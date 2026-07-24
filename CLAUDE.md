# CLAUDE.md — Hagez Consumer App (Flutter)

**Last Updated:** 2026-07-25
**Owner:** Hesham Abdelaal, Senior PM at Robusta Technology Group
**Status:** Active development — Flutter rebuild, core screens scaffolded (see Implementation Status below)
**Domain:** hagez.app (primary), hagez.com (future)

> This file was regenerated on 2026-07-25. The previous version of this file
> claimed a long list of features as "✅ Completed" (restaurant/salon booking
> flows, gaming cafe reservation, profile enhancements, etc.) that did not
> match the actual code — the repo's git history at the time had only 4
> commits (Expo scaffold, push-token registration, config, Firebase auth).
> That file was deleted. This one only states what has been verified against
> real code. Keep it that way — see "Update Instructions" at the bottom.

---

## ⚠️ CRITICAL INSTRUCTION: NO ASSUMPTIONS

**IF** any requirement is vague or ambiguous, **STOP immediately and ask clarifying questions** before generating user stories, code, or strategic recommendations. Do not guess at scope, technical implementation, or which portals are affected.

---

## 🎯 PROJECT OVERVIEW

- **English:** Hagez / **Arabic:** حاجز (hajez = "reserve/book")
- **Legacy name:** "Super Reservation Platform" — do NOT use.
- **Market Phase 1:** Egypt (Cairo focus). **Phase 2+:** MENA expansion.
- Multi-category lifestyle booking marketplace: consumers book restaurants, salons, sports courts, gaming cafes, and car washes via one app; businesses manage bookings/availability/deposits via a unified dashboard; the platform holds deposits in escrow, processes payments, detects no-shows, and splits no-show revenue.

### Business Model
```
Revenue: Platform fees (per category, EGP) + payment processing
Deposits: Held as escrow via Paymob (released on completion)
No-Show: Auto-detected 30min post-slot → 75/25 split (business/platform)
Cancellation: 24hr window default (configurable per business)
Currency: EGP only (Phase 1)
```
This matches the live API's actual behavior (`packages/api` in the `super-reservation` monorepo) as of this file's last update — verified by reading `booking-engine.ts` / `payment.ts` directly, not assumed.

---

## 📱 PORTALS

| Portal | Tech | Repo |
|---|---|---|
| **Consumer App** (this repo) | **Flutter, Dart** | `Etchinoo/hagez-mobile` |
| Business Dashboard | Next.js 14, TypeScript | `Etchinoo/Hagez` → `packages/dashboard` |
| API | Node.js + Fastify, Prisma, PostgreSQL | `Etchinoo/Hagez` → `packages/api` |

**This repo was Expo/React Native until 2026-07-25.** It was rebuilt in Flutter that day; the Expo code (4 commits: initial scaffold, push-token registration, config files, Firebase Phone Auth + Google Sign-In) was removed. If you find references to Expo, `.tsx`, `app.json`, or `eas.json` anywhere, they are stale — flag it.

Auth: Phone OTP is primary (`POST /auth/otp/request` + `POST /auth/otp/verify` on the API). The API also exposes `/auth/firebase/verify` and `/auth/social` (Google/Apple) routes — the Flutter app currently implements **OTP only**; Firebase/social login is not yet wired up in this codebase (it existed partially in the old Expo code, which is gone).

---

## 💻 TECH STACK (Consumer App)

- **Framework:** Flutter (stable channel), Dart ^3.11
- **State management:** flutter_riverpod
- **Routing:** go_router
- **HTTP:** dio, with a single `ApiClient.instance.dio` that injects the bearer access token and transparently refreshes-and-retries once on a 401
- **Auth token storage:** flutter_secure_storage (Keychain/Keystore) — never SharedPreferences for tokens
- **Fonts:** Cairo (Arabic, primary), Inter (Latin) — bundled as local assets, not loaded from Google Fonts at runtime
- **i18n:** a hand-written `AppStrings` class (`lib/l10n/app_strings.dart`) with `ar`/`en` blocks — **not** ARB/intl codegen. Arabic is the default and only wired-up language at runtime; the English strings exist but full locale-switching is not implemented yet (see Implementation Status).
- **Design tokens:** `lib/core/theme/app_theme.dart` — brand navy `#0F2044`, teal `#1B8A7A`, per-category accent colors (`AppColors.forCategory`)

### Local dev toolchain (this machine, verified 2026-07-25)
Flutter SDK at `C:\flutter` (v3.41.2, stable). `flutter doctor` reports Android SDK (licensed, emulator `Medium_Phone_API_36.1` available), Chrome, Edge, Windows desktop (Visual Studio Build Tools 2019), all with no issues.

---

## 🏗️ IMPLEMENTATION STATUS (Flutter rebuild, as of 2026-07-25)

This section replaces the old file's "Completed Work" list. Everything below was either read directly from the code or is an explicit, itemized gap reported by whoever built the piece — nothing here is aspirational.

### ✅ Built — foundation
- App shell, theming, RTL-by-default layout, routing table (`lib/core/router/app_router.dart`)
- API client with auto token-refresh, secure token storage, data models matching the live API's actual JSON shapes (`Business`, `Booking`, `Slot`, `HagezUser`, category/status enums)
- Arabic + English copy for all screens below (`lib/l10n/app_strings.dart`) — ported and rebranded from the old Expo app's i18n files where it already existed, extended for the rest

### ✅ Built — screens (first pass, wired to the live API)
- **Login / OTP** — phone entry with E.164 validation, OTP request/verify/resend
- **Home** — greeting, category chips, featured/nearby business lists from `GET /search/businesses`
- **Search** — category (single-select) / district (4 hardcoded Cairo districts) / min-rating filters, debounced
- **Business detail** — photos, description, category-specific resources (staff/courts/stations — not restaurant/car_wash, the API doesn't populate that for those categories), next available slots
- **Checkout** — date/time slot picker, party size, optional special requests → `POST /bookings`
- **Payment** — payment method selection, 8-minute hold countdown → `POST /bookings/:id/pay`
- **Confirmed** — booking success summary
- **My Bookings** — upcoming/past segmented list from `GET /bookings`
- **Booking detail** — full detail + cancel action (`PATCH /bookings/:id/cancel`)
- **Profile** — user info, logout; language/notification toggles are UI-only (see gaps below)

### 🚧 Explicit, known gaps (do these next, in rough priority order)
1. **Category-specific checkout fields are NOT built.** Checkout only has the universal fields (date/time, party size, special requests). Missing: occasion picker (restaurant), staff/resource picker (salon), station_type + genre_preference (gaming_cafe), vehicle_size (car_wash).
2. **Payment screen does not integrate the real Paymob WebView/iframe.** It treats a successful `POST /bookings/:id/pay` response as payment success and navigates straight to the confirmation screen. Needs a real WebView pointed at the returned `iframe_url`, tested against Paymob sandbox credentials.
3. **Language toggle (Profile screen) is visual-only** — does not yet switch the app's actual locale/RTL-English rendering.
4. **Notification preferences toggle is visual-only** — no backend endpoint exists for this yet.
5. **Reschedule is not built** on the booking detail screen (only cancel).
6. **Session restore uses a placeholder user object** on app relaunch (`lib/core/auth/auth_state.dart` has a `TODO`) rather than re-fetching the real profile from the API.
7. **Home category chips and "book now" don't pass filter/slot context** to the next screen yet (tapping a category just opens a blank Search; tapping "book now" doesn't preselect the slot you tapped).
8. **Google Sign-In / Firebase Phone Auth are not wired up** in the Flutter app (the API supports them; the old Expo app had partial work on this that was removed with the rest of the Expo code).

### ❌ Not started
- Loyalty screen, reviews UI, push notifications, deep links, any Phase-2-category-specific booking UX beyond what's listed above.

---

## 🧪 HOW TO TEST LOCALLY

```bash
cd hagez-mobile
flutter pub get
flutter run -d chrome              # fastest inner loop
flutter run -d windows             # native desktop
flutter run -d <emulator-id>       # Android — run `flutter emulators` to list, `--launch` to start one first
```

The API base URL defaults per-platform (`lib/core/api/env.dart`): `http://10.0.2.2:3000/v1` on the Android emulator (host-loopback alias), `http://localhost:3000/v1` everywhere else. Override with `--dart-define=API_BASE_URL=...`. The Fastify API (`packages/api` in the `super-reservation` monorepo) must be running locally (`docker compose up -d` then `npm run dev --workspace=packages/api`) for any screen beyond the splash screen to load real data.

---

## 🔐 SECURITY & AUTH (as implemented on the API, verified 2026-07)

- JWT: separate access (15m) and refresh (30d) secrets, `type` claim enforced — see the API's `claude/security-hardening` work.
- Refresh-token TTL 30 days, access-token TTL 15 minutes.
- Token storage: **must** be secure storage on-device (Keychain/Keystore) — this is enforced in the Flutter app (`SecureStorage`), unlike the web dashboard which still stores tokens in `localStorage` (a known, tracked issue on that side, not this repo's problem to fix).

---

## 💰 REFUND, NO-SHOW & DISPUTE POLICY (verified against live API code)

- **Cancellation window:** 24h before booking (default, configurable per business). Inside window → deposit forfeited. Outside window → full refund. Business-initiated cancellation → always full refund.
- **No-show:** detected by an automated job every 15 minutes, 30 minutes past slot start if not marked completed. Split: 75% to business, 25% to platform, both as pending `Payment` rows.
- **Dispute:** consumer can dispute a no-show within 24 hours of detection (`POST /bookings/:id/dispute`); resolution is manual via the admin console.

---

## 🏷️ CATEGORY-SPECIFIC BUSINESS RULES

| Category | Notes |
|---|---|
| Restaurant | Party size, occasion (birthday/anniversary/business/other), special requests |
| Salon | Staff/stylist assignment (`resources` of type `staff`) |
| Court | Court resources (`resources` of type `court`), court-specific config |
| Gaming Cafe | Stations (`resources` of type `station`), station_type + genre_preference, group rooms |
| Car Wash | Bay resources, vehicle size class (`sedan`/`suv`/`pickup`/`van`) |

Full field-level detail is in the API's Prisma schema (`packages/api/prisma/schema.prisma`) — treat that as the source of truth over any description here if they ever disagree.

---

## 📚 GLOSSARY

```
Booking states: pending_payment → confirmed → completed
                                            ↳ cancelled_by_consumer / cancelled_by_business
                                            ↳ no_show / disputed / expired
Slot hold: 8-minute reservation lock (Redis) while payment completes
Booking reference format: BK-YYYYMMDD-XXXXX
```

---

## 📝 UPDATE INSTRUCTIONS

**When to update:** after any screen goes from stub/gap to real implementation, after a tech-stack change, after a business-rule change.

**How to update:** tell Claude what changed; it should update the relevant section directly. **Do not add a checkmark or "completed" claim for anything Claude has not personally verified by reading the code or running it.** If you're describing planned/aspirational work, put it under a clearly-labeled "Planned" heading, never mixed into "Implementation Status" as if it were done — that's exactly the mistake that got the previous version of this file deleted.
