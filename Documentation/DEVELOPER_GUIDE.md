# CyntientOps Developer Guide

This guide codifies our working style so features compile, connect, and display correctly across the entire app.

## Architecture Map (Overview)
- Data Layer: OperationalDataManager (88 tasks/7 workers/17+ buildings), WeatherDataAdapter, BuildingAssets, ServiceContainer.
- Processing: WorkerDashboardViewModel, WeatherScoreBuilder, BuildingOperationsCatalog.
- UI: WorkerDashboardView, WorkerDashboardMainView, SimplifiedDashboard, BuildingDetailView.
- Connection Points (must be wired):
  1) Data Load → ViewModel Update → UI Refresh
  2) Weather Load → Suggestion Generation → Card Display
  3) Routine Load → Schedule Display → Time Calculation
  4) Policy Load → Chip Display → Building Context

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

## Anti‑Patterns to Avoid
- UI that only works for one worker/building.
- Data set without propagating to processing and UI.
- Off-main UI updates; schema/name assumptions.

## Current Alignment Summary
- Infra catalog standardized (elevators/stairs/notes) for core buildings.
- DSNY unit counts centralized in `BuildingUnitValidator`.
- 29/31 E 20th fully deprecated from user-visible code.

## Open Items (Track in TODO)
- Confirm elevator/stair counts for 133 E 15th if needed.
- Reconcile any dashboard unit summaries with validator data.
- Continue removing worker-specific conditionals from view layout (logic remains in services/routines).

