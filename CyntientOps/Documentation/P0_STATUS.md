**P0 Status — Ship‑Blockers & Core Foundations**

This document reconciles what is DONE vs REMAINING for P0 items based on the current code in this repo. It also maps acceptance tests to files/behaviors to verify.

—

1) Admin Dashboard parity (data is truth, not chrome)

What’s done
- Hydration: `AdminDashboardViewModel.initialize()` loads real data from services + OperationalDataManager, builds metrics and insights.
  - Files: `Views/Main/AdminDashboardView.swift`, `ViewModels/Dashboard/AdminDashboardViewModel.swift`
- Intelligence panel docked with safeAreaInset: no overlay on tab bar.
  - File: `AdminDashboardView.swift` uses `.safeAreaInset(edge: .bottom)` for `AdminNovaIntelligenceBar`.
- Portfolio Map with admin filters and region fit:
  - Filters: All • Issues • HPD • DSNY • Active • Visited
  - Region refit on filter change.
  - File: `Maps/MapRevealContainer.swift` (adminMode + filters, `position = .region(.fit(points: …))`).
- Routines look‑ahead when empty (Sunday evening set‑out and Monday AM first routine).
  - Files: `Views/Admin/AdminRoutinesPanel.swift`, `ViewModels/Dashboard/Admin/AdminRoutinesViewModel.swift`.
- Weather ribbon: Now / 12h / 48h and DSNY advisory.
  - File: `Views/Admin/AdminWeatherRibbon.swift` (advisory heuristic and forecast windows).
- Live status tiles: active/total, completion, compliance, recent activity — populated from real services.
  - Files: `AdminDashboardView.swift`, `AdminDashboardViewModel.swift`.

Status
- Complete. Workers tile now shows “All Active” when active == total; intelligence panel is docked; map filters and region refit are live; routines look‑ahead implemented; weather advisories wired.

Acceptance mapping
- Buildings > 0; Workers show active/total; Compliance & Completion show percentages.
  - Verified via `AdminDashboardViewModel.updateDigitalTwinMetrics()` and tiles in `AdminDashboardView.swift`.
- Map shows all pins; filters swap pin sets and recompute region.
  - `MapRevealContainer` admin filters + `position = .region(.fit(points: …))` on filter change.
- Panel collapsed never hides tab bar.
  - Docked via `.safeAreaInset(edge:.bottom)` (no overlay).
- Sunday evening shows DSNY set‑out look‑ahead; Monday AM shows first routine.
  - `AdminRoutinesViewModel.computeLookahead()` implements both cases.

—

2) Supabase online mode (secure) + Nova wiring

What’s done
- JWT pass‑through from app → Edge Function: Nova uses `Authorization: Bearer <sessionJWT>` if available.
  - File: `Nova/Core/NovaAPIService.swift` (`callSupabaseEdgeFunction`); `Managers/System/NewAuthManager.swift` exposes `accessToken`.
- Local persistence + analytics queue, then online sync with Authorization header.
  - File: `Services/Core/SupabaseSyncService.swift` (conversations + usage with JWT, falls back to anon only if JWT absent).
- Per‑user rate‑limit guard and observability (model, tokens, latency) in Nova flow.
  - File: `Nova/Core/NovaAPIService.swift` (requestLog + analytics logging).
- Offline fallback path on network or 5xx.
  - File: `Nova/Core/NovaAPIService.swift` (`processPromptOffline`).

Status
- App side complete and locked down for Release: Nova forbids anon fallback in non‑DEBUG builds; REST sync uses JWT.
- Server: deploy Edge Function without `--no-verify-jwt` and pass through Authorization to Supabase client (see setup guide). Add simple per‑user/IP rate limits server‑side.

Acceptance mapping
- Authenticated call writes a `conversations` row tied to auth.uid().
  - App already sends JWT; Edge must use it to satisfy RLS.
- Unauthenticated call fails to write.
  - Ensure Edge rejects or RLS blocks when no/invalid JWT.
- Rate‑limit triggers after N rapid calls.
  - Client limiter done; add server limiter.
- App falls back to offline mode and returns usable answer on errors.
  - Implemented.

—

3) Worker UX: multi‑location site departure + DSNY intelligence

What’s done
- Multi‑site departure sheet for the full building circuit with inline photo collection and checklist.
  - File: `Views/Worker/MultiSiteDepartureSheet.swift` (+ `SiteDepartureSingleView.swift` for single‑site flow).
- DSNY set‑out look‑ahead after evening window when visited/pending sparse.
  - File: `ViewModels/Dashboard/Admin/AdminRoutinesViewModel.swift` (`computeLookahead` adds DSNY set‑out item after 7pm on Su/Tu/Th).

Status
- Batch “circuit completion” implemented: `SiteDepartureViewModel.submit` writes a departure log per stop.
- DSNY set‑out fallback flows into the look‑ahead and multi‑site sheet.

Acceptance mapping
- Sun 8:30p clock‑out opens multi‑site sheet listing DSNY buildings.
  - DSNY look‑ahead present; hook entry from clock‑out to sheet where not already wired.
- Circuit completion writes a batch “departure” record per stop.
  - Confirm/extend `SiteDepartureViewModel` submit path.

—

Notes
- Map filters for admin are live in `Maps/MapRevealContainer.swift` (All, Issues, HPD, DSNY, Active, Visited) and refit the camera automatically.
- Weather advisories and 12h/48h views are displayed in `Views/Admin/AdminWeatherRibbon.swift`.
- All admin intelligence is populated from real services and OperationalDataManager; sync and health modeled in `AdminDashboardViewModel` and `AdminContextEngine`.
