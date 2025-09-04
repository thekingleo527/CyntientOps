CyntientOps TODO — Portfolio Alignment and Consistency

- Removed 29–31 East 20th (ID 2) from all user‑facing code:
  - Commands (`getBuildingName` cases)
  - Maps/coordinates (`CyntientOpsExtensions`, `WorkerProfileViewModel`)
  - UI assets (`PropertyCard` image switch)
  - Sample data (`VerificationRecord`)
  - Kept admin/database filters to proactively deactivate legacy records.

- Infrastructure catalog updates (confirmed by client):
  - `7` (112 W 18th): 1 elevator, 1 staircase
  - `9` (117 W 17th): 1 elevator, 1 staircase
  - `21` (148 Chambers): elevator opens into unit, 1 staircase, 7 units
  - `17` (178 Spring): no elevator, 1 staircase
  - `18` (36 Walker): no elevator, 1 staircase
  - `6` (68 Perry): no elevator, 1 staircase, roof gutter + drain (access via Apt 2R)
  - `10` (131 Perry): 1 elevator, 2 staircases
  - `14` (Rubin Museum Apts): no elevator, five‑story walk‑ups

Completed (this phase)

- Rubin Apts elevator = No; walk‑up notes in tabs
- Infra catalog updated (112/117/148/178/36W/68P/131P)
- Unit counts updated (Rubin 45; 133 E 15th = 16; 115 7th = 0; 36W = 10; 104 Franklin = 6)
- Building Detail DSNY messaging refined (non‑residential handling)
- Removed 29–31 East 20th (ID 2) from user‑facing code
- Seed/Initializer aligned to Canonical IDs

Next actions

- Add infra entries for remaining IDs not in catalog: `15`, `16`, `19`, `20` (awaiting confirmation).
- Reconcile unit counts in `ClientDashboardViewModel` with `BuildingUnitValidator` for 112 W 18th and related to avoid mixed signals in UI.
- Confirm any remaining legacy references to ID `2` in non‑UI logs/tests can remain as deactivation safeguards or remove entirely if preferred.

Latest adjustments (Greg @ 12 W 18th)

- Morning routine extended to 11:30 (Mon–Fri only)
- Replace carpet vacuum with hallway sweep + damp mop (Floors 2–9)
- Move trash area clean (no chute) before upstairs hallways
- Weekly boiler, roof drain, and stairwell moved to afternoons
- Saturday morning sidewalk pass‑bys assigned to Edwin for 17th/18th corridor

New adjustments

- During hallway sweep, include package deliveries to units (combined efficiency)
- Add daily on‑demand "Freight Elevator Coverage & Deliveries" window (11:30–12:00, Mon–Fri)
- Luis: add commercial end‑of‑day set‑out (41 Elizabeth, 104 Franklin). No garbage set‑out at 36 Walker; delete any such routines.
  - Revised: Luis set‑out applies to 41 Elizabeth only. 104 Franklin is commercial; Angel handles Floors 2 & 4 garbage removal on M/W/F at 16:30. No set‑out at 36 Walker.

Next comprehensive step

- Build out full routine matrices for Kevin, Edwin, Mercedes, Luis, Angel (and others), using upsert patterns with RRULEs and verified building constraints.

Design & Consistency

- Keep worker routines specific, but keep dashboard layouts universal (no worker‑specific UI paths).
- Route all service usage via `ServiceContainer`.
- Ensure UI updates happen on `@MainActor`.

References

- See `Documentation/DEVELOPER_GUIDE.md` for coding standards and verification protocol.

Audit: worker-specific UI logic (to migrate to data/services)

- `Views/Client/ClientWorkerDetailSheet.swift` (hardcoded worker cases for schedules)
- `Views/Main/TaskRequestView.swift` (hardcoded worker names for list examples)
- `Views/Components/Buildings/Supporting/BuildingMetricsComponents.swift` (static worker sample)
- `Views/Components/Buildings/Supporting/BuildingTeamComponents.swift` (hardcoded worker list)
- `Views/Components/Buildings/BuildingDetailView.swift` (DSNY assignment helper references specific workers; keep logic but ensure layout remains universal)

Plan: Replace hardcoded names with data from `WorkerService`/`OperationalDataManager` while preserving universal layouts.
