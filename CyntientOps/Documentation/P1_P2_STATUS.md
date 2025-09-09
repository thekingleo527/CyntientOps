**P1/P2 Implementation Status (Live Log)**

P1 — Intelligence, Compliance, and Reliability

1) Nova as an operator (tools)
- Status: In progress
- Added intents and grounded handlers in `NovaGroundingService` for:
  - hpdIssuesThisWeek → lists buildings with HPD issues in the past 7d with drill‑down hook via metadata `openView: admin_hpd_list`.
  - createSanitationReminder(building, weekday) → creates a task via `TaskService.createTask`.
- Next: Add additional intents for get_buildings, get_worker_status, list_open_issues(building_id), portfolio_metrics; render answer cards in `NovaInteractionView`.

2) Compliance ingestion (seed + adapters)
- Status: Baseline implemented
- `ComplianceService.fetchPortfolioSnapshot(timeframe:)` aggregates from locally cached NYC data with timeframe filters.
- Next: Wire sheets/tabs to snapshot counts and normalize drill‑downs consistently in admin views.

3) Weather‑triggered ops
- Status: Baseline implemented
- `WeatherTriggeredTaskManager` monitors weather and creates pre/post rain tasks + rain‑mat tasks.
- Next: Add per‑building weather action policy surface (thresholds) and notifications to assigned workers/admin.

4) Offline‑first reliability + queue
- Status: Queue is present (`OfflineQueueManager`); sync processing is integrated.
- Next: Add per‑task sync chips (Synced/Pending/Failed) in task lists and detail views by checking queue state.

5) Verification enforcement by task type
- Status: Enforcement partially present (departure checklist) and complete‑task path updated to validate photos when required.
- Next: Add a `verification_policy` column migration for `routine_tasks` and UI affordances in MaintenanceTaskView (checklists/photos gates).

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

