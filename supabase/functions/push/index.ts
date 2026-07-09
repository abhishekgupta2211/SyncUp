// SyncUp — `push` Edge Function
// Sends an FCM (HTTP v1) push whenever a row is inserted into public.notifications.
// Wire it up as a Supabase Database Webhook: Database → Webhooks → INSERT on
// public.notifications → HTTP POST to this function's URL, with a custom header
// `x-push-secret: <PUSH_WEBHOOK_SECRET>`.
//
// Required Edge Function secrets (Dashboard → Edge Functions → Secrets):
//   FCM_SERVICE_ACCOUNT  = the full Firebase service-account JSON (one line)
//   PUSH_WEBHOOK_SECRET  = any random string; must match the webhook header
// (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT")!;
const PUSH_WEBHOOK_SECRET = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const buf = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
  return buf.buffer;
}

// deno-lint-ignore no-explicit-any
let cached: { token: string; exp: number } | null = null;

// deno-lint-ignore no-explicit-any
async function getAccessToken(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;

  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(sig)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`token error: ${JSON.stringify(json)}`);
  cached = { token: json.access_token, exp: now + (json.expires_in ?? 3600) };
  return cached.token;
}

Deno.serve(async (req) => {
  try {
    if (PUSH_WEBHOOK_SECRET) {
      if ((req.headers.get("x-push-secret") ?? "") !== PUSH_WEBHOOK_SECRET) {
        return new Response("unauthorized", { status: 401 });
      }
    }

    const payload = await req.json();
    const row = payload.record ?? payload; // webhook: { type, record, old_record, ... }
    const userId = row?.user_id;
    if (!userId) return new Response("no user", { status: 200 });

    const sa = JSON.parse(FCM_SERVICE_ACCOUNT);
    const projectId = sa.project_id;
    const supa = createClient(SUPABASE_URL, SERVICE_ROLE);

    const { data: tokens } = await supa
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId);
    if (!tokens || tokens.length === 0) {
      return new Response("no tokens", { status: 200 });
    }

    const accessToken = await getAccessToken(sa);

    const data: Record<string, string> = {
      type: String(row.type ?? ""),
      notification_id: String(row.id ?? ""),
    };
    if (row.data && typeof row.data === "object") {
      for (const [k, v] of Object.entries(row.data)) data[k] = String(v);
    }

    const dead: string[] = [];
    await Promise.all(
      tokens.map(async ({ token }: { token: string }) => {
        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: {
                  title: row.title ?? "SyncUp",
                  body: row.body ?? "",
                },
                data,
                android: { priority: "high", notification: { sound: "default" } },
              },
            }),
          },
        );
        if (!res.ok) {
          const err = await res.text();
          // Prune tokens FCM says are gone; leave transient errors alone.
          if (res.status === 404 || err.includes("UNREGISTERED")) dead.push(token);
        }
      }),
    );

    if (dead.length) await supa.from("device_tokens").delete().in("token", dead);

    return new Response(
      JSON.stringify({ sent: tokens.length, pruned: dead.length }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(`error: ${e}`, { status: 500 });
  }
});
