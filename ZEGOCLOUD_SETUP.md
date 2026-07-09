# LoveChat — ZegoCloud calls setup (for the calls phase)

We use **ZegoCloud Call Kit** (`zego_uikit_prebuilt_call` + `zego_uikit_signaling_plugin`)
for real 1:1 voice & video calls. Zego provides the prebuilt call UI, ringing/accept/decline
invitations, and all the WebRTC/TURN/signaling. Free tier: ~10,000 minutes/month.

You only need this when we build **Phase 15 (Calls)** — not for the messaging MVP.

## Steps
1. Sign up at https://console.zegocloud.com.
2. **Create project** → product: **"In-app Chat / Call"** → enable the **Call Kit
   (zego_uikit_prebuilt_call)** scenario.
3. From the project dashboard copy the **AppID** (a number) and the **AppSign** (a long hex
   string).
4. Put them in `D:\Cloud\lovechat\.env`:
   ```
   ZEGO_APP_ID=1234567890
   ZEGO_APP_SIGN=abcd...the-long-hex...
   ```
5. (For ringing when the app is closed) we'll wire Zego offline invitations via FCM/APNs in
   the same phase — Zego has a guided setup for this in the console.

## How it maps to LoveChat
- Each user's **Zego userID = their Supabase auth user id**; userName = display name.
- The phone/video icons in a chat header start a Zego call invitation to the peer.
- The peer gets a native-style incoming-call screen (Zego prebuilt) with accept/decline.
- On call end, we log it to Supabase `call_logs` (for the Calls tab history).
- All gated by the `callsEnabled` flag in `lib/core/config/app_config.dart` until configured.
