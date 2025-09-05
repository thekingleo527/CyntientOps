**Release Readiness Checklist**

This checklist consolidates what’s required for a real‑world App Store submission and initial production rollout. It references App Store metadata and Supabase (Nova) docs without exposing secrets.

**App Store Metadata**

- Name/Bundle/SKU: Confirm matches App Store Connect (see `APP_STORE_SUBMISSION_PACKAGE.md`).
- Description/Promo/Keywords: Review and finalize messaging for current feature set.
- Categories: Business (primary), Productivity (secondary).
- Age rating: Verify content; likely 4+.
- Privacy Policy URL: `https://www.cyntientops.com/privacy` (live and accurate).
- Terms URL: `https://www.cyntientops.com/terms` (live and accurate).

**App Privacy (Data Types)**

- Data collected: name, email, location (while working), photos (task evidence), building/task metadata.
- Data used for: app functionality, analytics, compliance.
- Data linked to user: account, location, photos (evidence) – declare accordingly in App Privacy form.
- Tracking: not used (no IDFA); confirm ATT not required.

**Permissions (Info.plist)**

- `NSLocationWhenInUseUsageDescription`: Clock‑in verification at job sites.
- `NSCameraUsageDescription`: Photo evidence for task completion.
- `NSPhotoLibraryAddUsageDescription`: Save/export evidence when needed.
- `NSFaceIDUsageDescription` (if biometrics used).

**Screenshots & Marketing**

- iPhone 6.7" (6): Worker Dashboard, Admin Portfolio, Client Compliance, Nova Insights, Photo Verification, Activity Feed.
- iPad 12.9" (4): Split Dashboard, Compliance Center, Analytics, Building Detail.
- App icon and branding verified; display name correct.

**Demo & Review Notes**

- Reviewer access: Provide demo user and steps (non‑production credentials). Avoid real PII.
- Review notes: Location and camera justified; offline flow described.

**Build & Upload**

- Archive command: `xcodebuild archive -project CyntientOps.xcodeproj -scheme CyntientOps -configuration Release -archivePath ./build/CyntientOps.xcarchive`.
- Export and upload: see script in `APP_STORE_SUBMISSION_PACKAGE.md` (updated for correct project name). Consider using Transporter if preferred.

**Runtime Config (No Secrets in Code)**

- NYC tokens: `NYC_APP_TOKEN`, `DSNY_API_TOKEN` via environment/Keychain.
- Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY` via `.xcconfig` or CI secrets.
- Provide `Config/Development.example.xcconfig`; do not commit real keys.

**Operational Readiness**

- Offline: Queue persistence and replay validated; basic cache coverage for NYC datasets.
- Error handling: Graceful fallback for NYC API 4xx/decoding and Nova offline.
- Observability: Sentry configured with environment tags; OSLog for performance.
- Health: `ServiceContainer.verifyServicesReady()` returns meaningful status (not placeholders) for release.

**Compliance**

- Export compliance: TSU exception; ECCN 5D992 declared.
- Data retention: Evidence photo TTL policy documented; background cleanup strategy.

**Support & Policy**

- Support email(s) and website live.
- Basic runbook: incident paths for NYC API outages and rate limits.

Use this checklist alongside:
- App Store package: `CyntientOps/APP_STORE_SUBMISSION_PACKAGE.md`.
- Supabase/Nova: `CyntientOps/SUPABASE_SETUP.md`.
