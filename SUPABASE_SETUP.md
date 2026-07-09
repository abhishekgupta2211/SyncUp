# LoveChat — Supabase setup (one-time)

Follow these steps once. Total time ~10 minutes. Everything here is free-tier.

## 1. Create the project
1. Go to https://supabase.com → sign in → **New project**.
2. Name: `lovechat`. Choose a strong DB password (save it). Region: closest to you
   (e.g. **South Asia (Mumbai)** for India).
3. Wait ~2 min for it to provision.

## 2. Run the database migrations
1. In the project, open **SQL Editor** → **New query**.
2. Run each file from `supabase/migrations/` **in order**, one at a time:
   - `0001_schema.sql`
   - `0002_rls.sql`
   - `0003_rpcs_triggers.sql`
   - `0004_storage_realtime.sql`
3. Each should finish with "Success. No rows returned." (Re-running is safe — they're idempotent.)

## 3. Enable auth providers
1. **Authentication → Providers → Email**: enable. For fast local testing, turn
   **"Confirm email" OFF** (turn it back on before any real launch).
2. **Authentication → Providers → Google** (optional now): enable and paste your
   Google OAuth client id/secret. Can be added later — email works on its own.

## 4. Confirm storage buckets
**Storage** should list three buckets created by `0004`: `avatars` (public),
`chat-media` (private), `voice-notes` (private). If missing, re-run `0004`.

## 5. Get your API keys → put them in `.env`
1. **Project Settings → API**.
2. Copy **Project URL** and the **anon public** key.
3. Open `D:\Cloud\lovechat\.env` and fill in:
   ```
   SUPABASE_URL=https://YOUR_REF.supabase.co
   SUPABASE_ANON_KEY=eyJ...your-anon-key...
   ```
   (`.env` is gitignored — never commit it. Use the **anon** key, NOT the service_role key.)

## 6. Tell me it's done
Once `.env` has the URL + anon key, say so and I'll wire Phase 1 (auth + @username)
and run it on your device.

---

### Quick verification (optional, in SQL Editor)
```sql
-- tables exist
select table_name from information_schema.tables
where table_schema = 'public' order by table_name;

-- RLS is on
select relname, relrowsecurity from pg_class
where relname in ('profiles','conversations','messages','message_reactions');

-- realtime publication includes our tables
select tablename from pg_publication_tables where pubname = 'supabase_realtime';
```

### Notes
- **Push (FCM)** and **Realtime Authorization** hardening come in their own phases — not
  needed to start.
- Scale reality check: this schema handles millions of rows; the real ceiling on free/Pro
  tiers is concurrent realtime connections (~200 free / ~500 Pro), not data size.
