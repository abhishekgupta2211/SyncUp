# 🏍️ RIDER APP TRANSFORMATION PLAN

This document outlines the systematic transformation of the generic social application into a premium **Bike Rider Community & Ride Management Platform**.

---

## 1. Project Audit

### 🛠️ Tech Stack
- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (Auth, DB, Realtime, Storage)
- **Communication:** ZegoCloud (Video/Audio Calls)
- **Notifications:** Firebase Messaging (FCM)
- **State Management:** Provider
- **Design:** Modern Material 3 with Glassmorphism / Custom themes

### 📊 Existing Features vs. Transformation Mapping

| Feature | Current State | Transformation Strategy |
| :--- | :--- | :--- |
| **Authentication** | Magic Link & Guest Login | **KEEP** - Simplify onboarding to include Rider Profile Setup. |
| **Profiles** | Bio, Interests, XP, Social Level | **REDESIGN** - Add "My Garage", "Riding Style", and "Experience". |
| **Chat** | 1:1, Snaps, Vanish Mode, Smart Replies | **KEEP & REPURPOSE** - Theme it for riders; add "Route Sharing". |
| **Discovery** | Vibe Match (Swipe Cards) | **REDESIGN** - Change to "Rider Match" (Find nearby riders/bikes). |
| **Feed** | Social Posts, Shoutouts, Hashtags | **REPURPOSE** - "Rider Community" for bike builds and ride stories. |
| **Lounges** | Global Chat Rooms | **REPURPOSE** - "Riding Clubs" (General, Tourers, Stunters, etc). |
| **Stories** | Photo/Video Stories with Rings | **KEEP** - Focus on "Ride Highlights". |
| **AI Assistant** | SyncUp AI (Knowledge, Vision, Art) | **REPURPOSE** - "Ride Planner AI" / "Bike Mechanic AI". |
| **Notes** | 24-hour Status Bubbles | **REPURPOSE** - "Quick Vibe" (e.g., "Heading to Leh 🏔️"). |
| **Games** | RPS, Tic-Tac-Toe | **KEEP** - Keep as secondary social fun. |
| **Calling** | Voice/Video Calls | **KEEP** - Essential for group communication. |

### ❌ Features to Remove
- Generic "LoveChat" branding and romantic references.
- Any non-rider specific social placeholders.

### ✨ New Rider-Specific Features to Add
1. **The Garage:** Manage multiple motorcycles (Brand, Model, Mods).
2. **Maintenance Tracker:** Oil changes, chain service logs, reminders.
3. **Ride Planner:** Create rides with routes, waypoints, and meeting points.
4. **Live Ride Mode:** Real-time navigation, GPS tracking, and group location.
5. **SOS Center:** Emergency contacts and location sharing for riders.
6. **Maps Integration:** Google Maps for route discovery and nearby fuel/repair search.

---

## 2. Rider Design System

### 🎨 Color Palette (Adventure Theme)
- **Primary:** #FF4D00 (Racy Orange) or #F5C400 (Vibrant Yellow)
- **Secondary:** #1A1A1A (Deep Charcoal / Asphalt)
- **Accent:** #00C853 (Safety Green for SOS/Online)
- **Surface:** Glassmorphism over rugged backgrounds.

### 🖋️ Typography
- **Headlines:** Bold, high-energy sans-serif (e.g., Montserrat or Archivo).
- **Body:** Clean, highly readable fonts for outdoors.

---

## 3. Implementation Phases

### 🏁 Phase 1: Branding & Shell (Current)
- [ ] Rename App to **"SYNCUP RIDER"** (or similar).
- [ ] Implement new Splash Screen and Logo.
- [ ] Update Design System (Colors, Typography).
- [ ] Overhaul Onboarding to include Bike setup.

### 📍 Phase 2: Rider Profiles & Garage
- [ ] Extend Database for `bikes` and `rider_details`.
- [ ] Build **"My Garage"** UI.
- [ ] Redesign **Rider Profile** with statistics (KM ridden, trips).

### 🗺️ Phase 3: Maps & Ride Management
- [ ] Integrate Google Maps SDK.
- [ ] Build **"Plan a Ride"** flow.
- [ ] Implement **"Live Ride Mode"** with real-time GPS.

### 🏟️ Phase 4: Community & Clubs
- [ ] Repurpose Lounges into **Riding Clubs**.
- [ ] Update Discovery for **Rider Match**.
- [ ] Redesign Feed for **Ride Stories**.

### 🛠️ Phase 5: Safety & Maintenance
- [ ] Implement **Maintenance Tracker**.
- [ ] Build **SOS Safety Center**.

---

## 4. Database Schema Changes Required

- `profiles`: Add `riding_style`, `experience_years`, `current_bike_id`.
- `bikes`: New table for user motorcycles (brand, model, year, photos).
- `maintenance_logs`: New table for bike service tracking.
- `rides`: New table for planned trips (start, end, waypoints, participants).
- `ride_locations`: Real-time location tracking table (logged during live rides).

---

## 5. Risks & Dependencies
- **Google Maps API Costs:** Requires billing setup.
- **Background Location:** Battery consumption during Live Ride Mode.
- **Call Reliability:** Network issues in remote mountain areas.
