# CyntientOps Developer Guide

This guide codifies our working style so features compile, connect, and display correctly across the entire app.

## Architecture Map (Overview)
- Data Layer: GRDBManager (SQLite), OperationalDataManager (routes/routines), WeatherDataAdapter, BuildingAssets, ServiceContainer (DI).
- Processing: WorkerDashboardViewModel, AdminDashboardViewModel, UnifiedIntelligenceService, WeatherScoreBuilder, BuildingOperationsCatalog.
- UI: WorkerDashboardView/MainView, AdminDashboardView, ClientDashboardView, BuildingDetailView, MapRevealContainer.
- Connection Points (must be wired):
  1) Data Load → ViewModel Update → UI Refresh
  2) Weather Load → Suggestion Generation → Card Display
  3) Routine Load → Schedule Display → Look‑Ahead (Sun PM + next AM)
  4) Policy/Compliance Load → Chips/Sheets → Building Context
  5) Admin Map Filters → Pin Set → Region Fit

## Coding Principles
- MainActor discipline: UI-bound updates run on `@MainActor` or `MainActor.run {}`.
- ServiceContainer first: resolve services through the container (avoid new singletons).
- Universal layouts: dashboards/views render universally; worker- and building-specific routines live in data/services, not in view layout logic.
- Schema safety: do not assume columns; rely on existing queries/services; verify migrations.
- Canonical IDs: use `CanonicalIDs` for all building/worker references.
- Data Flow over stubs: every feature must complete the chain from data → processing → view model → UI.

## Implementation Protocol (5 Phases)
1) Read context and validate schema/services used.
2) Wire connection points (ensure events propagate to UI).
3) Implement feature logic (universal; no special-casing UI).
4) Validate via tests (unit → integration → system → user checks).
5) Document decisions and update checklists.

## Testing Protocol (Quick Commands)
- Build: `xcodebuild build -scheme CyntientOps -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- Tests: `xcodebuild test -scheme CyntientOps -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
- File parse: `swiftc -parse <path-to-file>.swift`

## Success Criteria
- Compiles without warnings; displays in all applicable views; handles edge cases; updates in real time; adheres to design system.
 - Admin intelligence panel is docked (safe area inset), never obscuring tab bar.
 - Admin map filters swap pins (All/Issues/HPD/DSNY/Active/Visited) and refit region.
 - Routines show look‑ahead on Sunday evenings and next morning schedule.

## Anti‑Patterns to Avoid
- UI that only works for one worker/building.
- Data set without propagating to processing and UI.
- Off-main UI updates; schema/name assumptions.

## Current Alignment Summary (Now)
- ServiceContainer provides lazy services and background data init (see `Services/Core/ServiceContainer.swift`).
- AdminDashboard parity baseline implemented:
  - Hydration in `AdminDashboardViewModel.initialize()`; metrics via services + OperationalDataManager.
  - Intelligence panel docked via `.safeAreaInset(edge:.bottom)` in `AdminDashboardView.swift`.
  - Map filters and region fit in `Maps/MapRevealContainer.swift`.
  - Routines look‑ahead in `Views/Admin/AdminRoutinesPanel.swift` + `ViewModels/Dashboard/Admin/AdminRoutinesViewModel.swift`.
  - Weather ribbon Now/12h/48h + DSNY advisory in `Views/Admin/AdminWeatherRibbon.swift`.
- DSNY unit counts centralized in `BuildingUnitValidator`.
- ViewModels avoid new types in compiled targets: no direct references to `HydrationFacade` or `DSNYScheduleProvider` from VMs; DSNY UI and logic use `DSNYCollectionSchedule` which is in-target.
- Client dashboard metrics/UI prefer route-derived portfolio data: `routePortfolioTodayTasks` and `routePortfolioWorkerIds`.
- 29/31 E 20th fully deprecated from user-visible code.

Admin TODOs (P0 small polish)
- Copy: show “All active” instead of x/y when all workers are active.
- Verify compliance totals match drill‑downs in HPD/DOB/DSNY sheets for selected timeframe.

## Open Items (Track in TODO)
- Confirm elevator/stair counts for 133 E 15th if needed.
- Reconcile any dashboard unit summaries with validator data.
- Continue removing worker-specific conditionals from view layout (logic remains in services/routines).
