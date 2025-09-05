**Architecture Overview**

- Purpose: Describe the current CyntientOps architecture, data flows, and integration patterns used in production builds.
- Scope: App composition, service layering, persistence, networking, offline model, and observability.

**Layers**

- App: `CyntientOpsApp` bootstraps, observes auth state, and hosts dashboards.
- Views/ViewModels: SwiftUI with MVVM; `@Published` state feeds role‑specific dashboards.
- Services: Business logic and integrations wired through `ServiceContainer`.
- Managers: Cross‑cutting concerns (operational data, Nova, notifications, performance).
- Persistence: SQLite via `GRDBManager` with WAL, FKs, and idempotent DDL.

**Service Container**

- Construction: `ServiceContainer` initializes fast; heavy seeding runs in background.
- Layer 0: `GRDBManager`, `OperationalDataManager`.
- Layer 1: `NewAuthManager`, `WorkerService`, `BuildingService`, `TaskService`, `ClockInService`, `PhotoEvidenceService`, `ClientService`, `UserProfileService`.
- Layer 2: `DashboardSyncService`, `BuildingMetricsService`, `ComplianceService`, `WebSocketManager`.
- Layer 3: `UnifiedIntelligenceService`, `NovaAPIService`.
- Context/Utils: `WorkerContextEngine`, `AdminContextEngine`, `ClientContextEngine`, `OfflineQueueManager`, `CacheManager`, `NYCIntegrationManager`, `NYCComplianceService`, `NYCHistoricalDataService`, `WeatherDataAdapter`, `RouteManager`.

**Key Design**

- Lazy Initialization: Most services are lazy; first access constructs them to keep launch time low.
- Async/await: Long‑running operations off the main thread; `@MainActor` used for UI updates.
- Idempotent DDL: Database tables created if missing; migrations helper supports schema evolution.

**Data Flows**

- Task Lifecycle:
  - Create/Assign via `TaskService` → persist in GRDB → enqueue sync → broadcast via `DashboardSyncService` → UI updates in dashboards.
  - Evidence flow: Photo capture → encrypt/TTL handling in `PhotoEvidenceService` → link to task.
- Worker Clock In/Out:
  - Validate location/access → create record → load tasks → dashboard refresh → metrics update.
- Client Filtering:
  - `ClientService` maps clients→buildings; client dashboards query only owned buildings.

**Offline Model**

- Queue: `OfflineQueueManager` persists actions; drains automatically on reconnect.
- Cache: `CacheManager` provides TTL caches for expensive calls and NYC datasets.
- Network Awareness: `NetworkMonitor` toggles sync and processing behavior.

**NYC Integrations**

- Service: `NYCAPIService` with endpoints for HPD, DOB, DSNY (routes/violations), 311, LL97, FDNY, DOF, energy ratings, and building footprints.
- Strategies:
  - Address→BIN/BBL resolution: building footprints + `$q` fallbacks where datasets support it.
  - Rate limiting: gentle delays between requests; jitter/backoff on transient errors.
  - Caching: per‑endpoint TTLs; longer TTLs for stable datasets (e.g., footprints/landmarks).
  - Graceful degradation: cached data or empty arrays returned on specific 4xx/decoding errors to protect dashboards.
- Tokens: The service checks Keychain and environment variables (`NYC_APP_TOKEN`, `DSNY_API_TOKEN`) and sets `X‑App‑Token` where supported.

**Persistence**

- Engine: GRDB/SQLite with WAL for performance and FKs for integrity.
- Patterns: Prepared statements, indices for common queries, batch operations.
- Migrations: Guarded, idempotent table creation with helper migrator.

**Observability**

- Logging: OSLog for performance and events; breadcrumbs sent to Sentry.
- Readiness: `ServiceContainer.verifyServicesReady()` provides a coarse health signal.
- Metrics: Performance utilities (query optimizer, task pool, memory pressure monitor) instrument critical paths.

**Security & Privacy**

- Keychain: Credentials and tokens via `KeychainManager`.
- Evidence: Photo TTL and cleanup routines; privacy overlays when backgrounding.
- Entitlements/Policies: App targets require appropriate entitlements; review data handling and logging for PII minimization.

**Build & Test**

- Build: `xcodebuild -scheme CyntientOps -configuration Debug`.
- Test: `xcodebuild test -scheme CyntientOps -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`.
- CI: GitHub Actions workflow builds app; extend with tests/lint as needed.

**Module Map**

- Core: database, migrations, system coordination.
- Services: operations (tasks, workers, buildings), real‑time, offline, commands, NYC.
- Intelligence: unified intelligence + Nova adapters.
- UI: role dashboards and components.
- Docs: data flow, debugging, and development methodology.

**Appendix: NYC Endpoint Reference**

- HPD Violations, DOB Permits/Inspections, DSNY routes/violations, LL97 Emissions, FDNY Inspections, 311 Complaints, DOF Property Assessments/Tax Bills/Liens, Energy Ratings, Landmark Buildings, Building Footprints, Active Construction, Business Licenses, Air Quality Complaints.

For details, see inline documentation in `Services/NYC/NYCAPIService.swift`.
