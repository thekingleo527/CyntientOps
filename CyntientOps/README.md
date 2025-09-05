**CyntientOps**

- Overview: iOS SwiftUI platform for NYC property operations, compliance, and real‑time tasking with offline support.
- Core: Layered services via `ServiceContainer`, GRDB/SQLite persistence, NYC Open Data integrations, Nova intelligence, and resilient command chains.

**Features**

- Role Dashboards: Admin, Client, Worker with tailored views and flows.
- NYC Compliance: HPD, DOB, DSNY, FDNY, LL97, 311, DOF, Energy ratings.
- Offline‑First: Queue, cache, and replay with network awareness.
- Real‑Time Updates: Dashboard sync and WebSocket coordination.
- Evidence & Security: Photo TTL handling and at‑rest best practices.
- Intelligence: Unified intelligence service and Nova assistant hooks.

**Architecture**

- Container: `ServiceContainer` composes layered services with lazy init.
- Persistence: `GRDBManager` (SQLite, WAL, FKs, idempotent DDL, migrations helper).
- Sync: `DashboardSyncService` and `OfflineQueueManager` for resilience.
- Networking: `NYCAPIService` with caching, rate limiting, backoff, and fallbacks.
- Observability: OSLog‑based performance monitor with Sentry hooks.

See `CyntientOps/Documentation/ARCHITECTURE.md` for a deep dive.

**Getting Started**

- Requirements: Xcode 15+, iOS 17+ Simulator or device.
- Open: `CyntientOps/CyntientOps.xcodeproj`, select the `CyntientOps` scheme.
- Run: Build and run on a simulator (e.g., iPhone 15/16 Pro).

Distribution and release

- App Store package: `CyntientOps/APP_STORE_SUBMISSION_PACKAGE.md` (metadata, screenshots, upload script).
- Release checklist: `CyntientOps/Documentation/RELEASE_READINESS_CHECKLIST.md`.
- Sample config: `CyntientOps/Config/Development.example.xcconfig` (copy then set local values).

Optional environment/config (for live NYC data):

- Env vars: `NYC_APP_TOKEN`, `DSNY_API_TOKEN`.
- Keychain: managed via `KeychainManager` (see docs). If not set, some endpoints operate in read‑only or cached mode.

**Project Structure**

- `Services/` core, real‑time, NYC, commands, offline, security.
- `Core/` database, migrations, models, system orchestration.
- `Views/` role dashboards and components.
- `ViewModels/` MVVM bindings to services.
- `Utilities/` cache, metrics, performance tools.
- `Documentation/` implementation and data‑flow guides.

**NYC Integrations**

- Endpoints include HPD violations, DOB permits, 311, DSNY routes/violations, LL97 emissions, FDNY inspections, DOF assessments/tax items, building footprints, and energy ratings.
- Behavior: per‑endpoint caching, gentle rate limiting, graceful fallbacks, and address→BIN/BBL resolution helpers.

**Testing**

- Unit/Integration Tests: see `CyntientOps/Tests`.
- Run: `xcodebuild test -scheme CyntientOps -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.

**Documentation**

- Architecture: `CyntientOps/Documentation/ARCHITECTURE.md`.
- Wire Diagrams: `CyntientOps/Documentation/WIRE_DIAGRAM.md`.
- Production Data Inventory: `CyntientOps/Documentation/PRODUCTION_DATA.md`.
- Data Flow: `CyntientOps/Documentation/DATA_FLOW_VERIFICATION_GUIDE.md`.
- Debugging: `CyntientOps/Documentation/DEBUGGING_CHECKLIST_DISPLAY_ISSUES.md`.
- Connection Methodology: `CyntientOps/Documentation/IMPLEMENTATION_CONNECTION_METHODOLOGY.md`.
- Developer Guide: `Documentation/DEVELOPER_GUIDE.md`.
 - Release Readiness: `CyntientOps/Documentation/RELEASE_READINESS_CHECKLIST.md`.

**Operational Notes**

- Services initialize lazily to keep launch fast; heavy seeding occurs in background.
- Offline queue persists and drains on reconnect; caches protect dashboards during transient errors.
- NYC API calls prefer BIN/BBL; address fallbacks are available where datasets support `$q`.

**Roadmap Pointers**

- WebSocket auth hardening, richer background enforcement for TTL cleanups, and expanded CI coverage are tracked in `CyntientOps/TODO.md`.

This README reflects the current app behavior and structure. For deeper details and sequence diagrams, read the Architecture document.
