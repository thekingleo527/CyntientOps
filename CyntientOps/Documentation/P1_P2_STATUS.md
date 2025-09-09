**P1/P2 Implementation Status (Live Log)**

P1 — Intelligence, Compliance, and Reliability

1) Nova as an operator (tools)
- Status: Partial complete
- Grounded handlers in `NovaGroundingService`:
  - hpdIssuesThisWeek → lists buildings with HPD issues in the past 7d (metadata `openView: admin_hpd_list`).
  - createSanitationReminder(building, weekday) → `TaskService.createTask`.
  - get_buildings → portfolio buildings list.
  - get_worker_status → active/total summary.
  - list_open_issues(building_id) → open issues for building.
  - portfolio_metrics → buildings, completion %, HPD/DSNY 30d, DOB active.
- Next: Render answer cards (tap-through) in `NovaInteractionView` using existing `NovaActionButtons` and metadata hooks.

2) Compliance ingestion (seed + adapters)
- Status: Baseline implemented
- `ComplianceService.fetchPortfolioSnapshot(timeframe:)` aggregates from locally cached NYC data with timeframe filters.
- Next: Wire sheets/tabs to snapshot counts and normalize drill‑downs consistently in admin views.

3) Weather‑triggered ops
- Status: Baseline implemented
- `WeatherTriggeredTaskManager` monitors weather and creates pre/post rain tasks + rain‑mat tasks.
- Policies: triggers only for buildings in pilot/production via `BuildingConfigurationManager`.
- Next: Notify assigned workers/admin and add thresholds surface in UI.

4) Offline‑first reliability + queue
- Status: In progress
- Queue present. Added per‑task “Pending” chip in `MaintenanceTaskView` driven by `OfflineQueueManager.isTaskPending(_:)`.
- Next: Extend chips where tasks list is rendered and add “Failed” state reading retryCount.

5) Verification enforcement by task type
- Status: In progress
- Database: Added `verification_policy` column; current enforcement uses `requires_photo` or sanitation/cleaning category in `TaskService.completeTask` to require photos.
- Next: UI affordances to collect/checklist photos before allowing “Complete”.

P2 — Scale, Observability, and Safety Nets

6) Observability & health dashboard
- Status: Pending
- Plan: OSLog categories (ui, network, db, ai), local crash persistence, admin health dashboard with LLM latency/tokens/sync backlog.

7) Role‑aware RLS & multi‑tenant
- Status: Guidance updated (Supabase setup); Edge must pass Authorization to Supabase client; org_id scoping planned.

8) CI & release hygiene
- Status: Pipeline builds on macOS; adding SwiftLint and basic UI snapshot tests planned.

9) Nova cost & speed
- Status: Client analytics recorded (model, tokens, latency). Next up: streaming UI and prompt caching of last 5 messages per user; token ceilings.
