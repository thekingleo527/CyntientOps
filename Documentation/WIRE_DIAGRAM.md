**Wire Diagrams**

These ASCII diagrams summarize the current app flow, layered services, and critical data paths.

**App Flow**

```
┌──────────────────────────────────────────┐
│            CyntientOpsApp.swift          │
│  - Launch                               │
│  - Observe auth state                   │
│  - Host role dashboards                 │
└───────────────┬──────────────────────────┘
                │
                ▼
      Role Detection (NewAuthManager)
                │
   ┌────────────┼─────────────┐
   │            │             │
   ▼            ▼             ▼
 Admin        Client        Worker
 Dashboard    Dashboard     Dashboard
```

**Service Container (Layered)**

```
ServiceContainer (fast init, lazy services)

Layer 0: DB & Data
- GRDBManager (SQLite, WAL, FKs)
- OperationalDataManager

Layer 1: Core Services
- NewAuthManager, WorkerService, BuildingService, TaskService
- ClockInService, PhotoEvidenceService, ClientService, UserProfileService

Layer 2: Coordination
- DashboardSyncService, BuildingMetricsService, ComplianceService, WebSocketManager

Layer 3: Intelligence
- UnifiedIntelligenceService, NovaAPIService

Context/Utils
- OfflineQueueManager, CacheManager, NetworkMonitor
- NYCIntegrationManager, NYCComplianceService, NYCHistoricalDataService
- WeatherDataAdapter, RouteManager
```

**Data Flow: Task Lifecycle**

```
Action → TaskService → GRDB (persist) → OfflineQueue (if offline)
        → DashboardSync (broadcast) → ViewModels (@Published) → SwiftUI
```

**NYC Integrations**

```
NYCAPIService
  - HPD, DOB, DSNY, 311, LL97, FDNY, DOF, Energy, Landmarks, Footprints
  - Address→BIN/BBL helpers, per-endpoint TTL cache, gentle rate limit
  - Graceful fallback on 4xx/decoding with cached data
```

**Offline/Resilience**

```
NetworkMonitor ⇄ OfflineQueueManager ⇄ DashboardSyncService
  - Queue actions when offline
  - Drain and sync on reconnect
  - UI remains responsive using caches
```

**Sequence: Worker Clock-In**

```
Worker → ClockInService → Validate Location/Access → Create Record → Load Tasks
    → DashboardSync → WorkerDashboard view refresh
```

**Sequence: Client Filtering**

```
Client → Auth → ClientService.getBuildings(client) → BuildingsView/ClientDashboard
  - Returns only owned buildings based on client_buildings
```

This document reflects the current architecture after consolidation; see `ARCHITECTURE.md` for details and `PRODUCTION_DATA.md` for the latest portfolio mapping.
