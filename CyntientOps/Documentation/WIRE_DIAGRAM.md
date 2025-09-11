# CyntientOps End-to-End Architecture Wire Diagram

## 🏗️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CyntientOpsApp.swift                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ @main App                                                           │   │
│  │ • ServiceContainer (DI)                                            │   │
│  │ • NewAuthManager                                                   │   │
│  │ • DashboardSyncService                                            │   │
│  └──────────────────┬──────────────────────────────────────────────┘   │
└────────────────────┼────────────────────────────────────────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │       ContentView.swift        │
        │   Role-Based Router (Auth)     │
        └────────────┬───────────────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Admin   │  │  Client  │  │  Worker  │
│Dashboard │  │Dashboard │  │Dashboard │
└──────────┘  └──────────┘  └──────────┘
```

## 📊 Layered Service Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         ServiceContainer                                  │
│                    (Composition Root - Fast Init)                        │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Layer 0: Database & Core Data                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ • GRDBManager (SQLite + WAL + FKs)                             │    │
│  │ • OperationalDataManager                                       │    │
│  │ • CacheManager (TTL-based)                                     │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Layer 1: Domain Services                                               │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ • NewAuthManager        • WorkerService                        │    │
│  │ • BuildingService       • TaskService                          │    │
│  │ • ClockInService        • PhotoEvidenceService                 │    │
│  │ • ClientService         • UserProfileService                   │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Layer 2: Coordination & Integration                                    │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ • DashboardSyncService  • BuildingMetricsService               │    │
│  │ • ComplianceService     • WebSocketManager                     │    │
│  │ • RouteManager          • WeatherDataAdapter                   │    │
│  │ • OfflineQueueManager   • NetworkMonitor                       │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  Layer 3: Intelligence & Analytics                                      │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ • UnifiedIntelligenceService                                   │    │
│  │ • NovaAPIService (GPT-4)                                       │    │
│  │ • AdminContextEngine                                           │    │
│  │ • ClientContextEngine                                          │    │
│  │ • WorkerContextEngine                                          │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  NYC Integration Layer                                                  │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ • NYCAPIService         • NYCComplianceService                 │    │
│  │ • NYCHistoricalDataService                                     │    │
│  │ • NYCIntegrationManager • NYCDataCoordinator                   │    │
│  └────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Patterns

### Task Lifecycle Flow
```
User Action (UI)
     │
     ▼
TaskService.create()
     │
     ├──→ GRDBManager.persist()
     │         │
     │         ▼
     │    SQLite Database
     │         │
     ├──→ OfflineQueueManager (if offline)
     │         │
     │         ▼
     │    Queue Storage
     │
     ▼
DashboardSyncService.broadcast()
     │
     ├──→ WebSocketManager
     │         │
     │         ▼
     │    Real-time Updates
     │
     ▼
ViewModels (@Published)
     │
     ▼
SwiftUI Views (Auto-update)
```

### Worker Clock-In Flow
```
WorkerDashboardView
     │
     ▼
ClockInSheet
     │
     ▼
ClockInService.clockIn()
     │
     ├──→ LocationValidator
     │         │
     │         ▼
     │    Access Check
     │
     ├──→ ClockInManager (Actor)
     │         │
     │         ▼
     │    Session Creation
     │
     ├──→ GRDBManager
     │         │
     │         ▼
     │    time_clock_entries
     │
     ▼
DashboardSyncService
     │
     ├──→ AdminDashboard (Update)
     ├──→ ClientDashboard (Update)
     └──→ WorkerDashboard (Refresh)
```

### NYC Compliance Data Flow
```
AdminDashboardViewModel.initialize()
     │
     ▼
NYCHistoricalDataService.loadHistoricalDataForAllBuildings(months: 6)
     │
     ├──→ NYCAPIService (Multiple Endpoints)
     │    ├── HPD Violations
     │    ├── DOB Permits
     │    ├── DSNY Schedule/Violations
     │    ├── LL97 Emissions
     │    ├── FDNY Inspections
     │    ├── 311 Complaints
     │    └── DOF Assessments
     │
     ▼
NYCComplianceService (Aggregation)
     │
     ├──→ getHPDViolations()
     ├──→ getDOBPermits()
     ├──→ getDSNYSchedule()
     ├──→ getLL97Emissions()
     ├──→ getLL11NextDueDate() [+5 years from FISP]
     └──→ getLL97NextDueDate() [May 1 after reporting year]
     │
     ▼
BuildingHistoricalData
     │
     ▼
PortfolioComplianceStatistics
     │
     ▼
AdminDashboardView (Analytics Tab)
     └── 30-day Trend Calculation
```

## 🎯 Role-Based UI Architecture

### Admin Dashboard Structure
```
AdminDashboardView
├── MapRevealContainer
│   └── Portfolio Map (Building Pins)
├── AdminHeaderV3B
├── AdminRealTimeHeroCard
├── AdminUrgentItemsSection
├── AdminNovaIntelligenceBar
│   ├── Priorities Tab (Streaming)
│   ├── Workers Tab (Active Status)
│   ├── Buildings Tab (KPIs)
│   └── Analytics Tab
│       ├── Efficiency Metrics
│       ├── Compliance Trend (30d vs prev 30d)
│       ├── HPD Open Count
│       ├── DSNY Open Count
│       ├── DOB Active Count
│       ├── LL97 Non-Compliant
│       ├── Workers Active
│       └── Buildings Count
└── Sheet Navigation (.activeSheet)
    ├── .profile → AdminProfileView
    ├── .buildings → AdminBuildingsListView
    ├── .workers → WorkerManagerView
    ├── .compliance → AdminComplianceCenter
    ├── .analytics → AdminAnalyticsView
    ├── .exampleReport → Building Report
    └── .verificationSummary → CSV Export
```

### Client Dashboard Structure
```
ClientDashboardView
├── MapRevealContainer
│   └── Portfolio Map
├── ClientHeaderV3B
├── ClientRealTimeHeroCard
├── Broadcast Banner (Inline)
├── Buildings Grid
├── ClientNovaIntelligenceBar
│   ├── Priorities Tab
│   ├── Portfolio Tab
│   ├── Compliance Tab
│   │   ├── HPD Drill-in
│   │   ├── DOB Drill-in
│   │   ├── DSNY Drill-in
│   │   └── LL97 Drill-in
│   └── Analytics Tab
└── Sheet Navigation
    ├── ClientProfileView
    ├── BuildingDetailView
    └── ClientComplianceViews (Extracted)
```

### Worker Dashboard Structure
```
WorkerDashboardMainView
├── WorkerHeroNowNext
│   ├── Now Card (Current Task)
│   └── Next Card (Upcoming)
├── WeatherRibbonView
│   └── WorkerWeatherSnapshot
├── UpcomingTaskListView
│   ├── WeatherScoreBuilder
│   └── UpcomingTaskRowView
├── BroadcastStrip
├── DSNYBinTaskCard
└── Quick Action Sheets
    ├── ClockInSheet
    ├── QuickNoteSheet
    ├── VendorAccessLogSheet
    └── BuildingMapDetailView
```

## 🗄️ Database Schema & Tables

```
SQLite Database (GRDBManager)
│
├── Core Tables
│   ├── buildings (id, name, address, lat, lng, client_id)
│   ├── workers (id, name, email, role, status)
│   ├── tasks (id, title, description, status, urgency, building_id, worker_id)
│   └── clients (id, name, contact_info)
│
├── Operational Tables
│   ├── time_clock_entries (id, worker_id, building_id, clock_in, clock_out)
│   ├── task_assignments (task_id, worker_id, assigned_at)
│   ├── worker_assignments (worker_id, building_id, active)
│   └── routines (id, name, building_id, frequency, tasks)
│
├── Compliance Tables
│   ├── compliance_issues (id, building_id, type, severity, details)
│   ├── nyc_compliance_cache (building_id, data_type, raw_data, cached_at)
│   ├── building_permits (permit_id, building_id, status, issued_date)
│   └── dsny_schedules (building_id, route_id, collection_days)
│
├── Real-Time Tables
│   ├── dashboard_updates (id, type, payload, created_at)
│   ├── offline_queue (id, action, payload, status, created_at)
│   └── websocket_events (id, channel, event, data, timestamp)
│
└── Evidence Tables
    ├── photo_evidence (id, task_id, url, metadata, ttl, created_at)
    ├── departure_logs (id, building_id, worker_id, timestamp, notes)
    └── vendor_access (id, building_id, vendor_name, time_in, time_out)
```

## 🌐 NYC API Integration Points

```
NYCAPIService
│
├── Building Data
│   ├── /resource/building-footprints → BIN/BBL resolution
│   ├── /resource/pluto-data → Property details
│   └── /resource/energy-ratings → Energy efficiency
│
├── Compliance Endpoints
│   ├── /resource/hpd-violations → HPD Violations
│   ├── /resource/dob-permits → DOB Permits
│   ├── /resource/dob-fisp → LL11 Facade Inspections
│   ├── /resource/dsny-routes → Collection Schedule
│   ├── /resource/dsny-violations → DSNY Violations
│   └── /resource/ll97-emissions → LL97 Compliance
│
├── Operational Data
│   ├── /resource/311-complaints → Service Requests
│   ├── /resource/fdny-inspections → Fire Safety
│   └── /resource/dof-assessments → Tax/Financial
│
└── Caching Strategy
    ├── Footprints: 30 days
    ├── Violations: 1 hour
    ├── Permits: 4 hours
    ├── Schedules: 24 hours
    └── Energy: 7 days
```

## ⚡ Real-Time Sync Architecture

```
DashboardSyncService
│
├── WebSocketManager
│   ├── Connection Management
│   ├── Channel Subscriptions
│   │   ├── admin-updates
│   │   ├── client-portfolio-{id}
│   │   └── worker-{id}
│   └── Event Broadcasting
│
├── Update Types
│   ├── TaskUpdate
│   ├── ComplianceChange
│   ├── WorkerStatusChange
│   ├── BuildingMetricUpdate
│   └── EmergencyAlert
│
└── Broadcast Flow
    │
    ├──→ AdminDashboardViewModel
    │    └── @Published properties update
    │
    ├──→ ClientDashboardViewModel
    │    └── Portfolio metrics refresh
    │
    └──→ WorkerDashboardViewModel
         └── Task list/status update
```

## 🔐 Authentication & Session Flow

```
NewAuthManager
│
├── Session Management
│   ├── Login → Token Generation
│   ├── Biometric Auth (Face/Touch ID)
│   ├── Session Refresh (JWT)
│   └── Logout → Clear State
│
├── Role Detection
│   ├── worker
│   ├── client
│   ├── admin
│   ├── manager
│   └── superAdmin
│
└── ContentView Routing
    │
    ├── if .worker → WorkerDashboardView
    ├── if .client → ClientDashboardView
    ├── if .admin → AdminDashboardView
    └── else → LoginView
```

## 🏗️ Core Types & Models

```
CoreTypes.swift
│
├── User Models
│   ├── User (id, name, email, role)
│   ├── WorkerProfile (status, assignments)
│   └── ClockStatus (in/out, building, time)
│
├── Task Models
│   ├── ContextualTask
│   │   ├── id, title, description
│   │   ├── status (pending/active/complete)
│   │   ├── urgency (7 levels)
│   │   ├── building_id, worker_id
│   │   └── due_date, created_at
│   └── TaskUrgency
│       └── low → emergency (7 levels)
│
├── Building Models
│   ├── NamedCoordinate (id, name, address, lat, lng)
│   ├── BuildingMetrics (tasks, compliance, occupancy)
│   └── PortfolioMetrics (aggregate stats)
│
├── Compliance Models
│   ├── ComplianceIssue (type, severity, details)
│   ├── ComplianceSeverity (low/medium/high/critical)
│   ├── LocalLawComplianceData
│   └── ComplianceOverview (summary stats)
│
├── Weather Models
│   ├── WeatherCondition (enum)
│   ├── WeatherSnapshot (global)
│   ├── WorkerWeatherSnapshot (banner)
│   └── OutdoorWorkRisk (assessment)
│
└── Utility Types
    ├── ProcessedPhoto (evidence)
    ├── DateUtils (timezone-aware)
    └── CanonicalIDs (building/worker refs)
```

## 🚀 Performance & Optimization

```
Performance Architecture
│
├── Lazy Initialization
│   ├── ServiceContainer (<100ms startup)
│   ├── Heavy services load on-demand
│   └── Background seeding tasks
│
├── Task Pooling (TaskPoolManager)
│   ├── Task.Priority management
│   ├── Max 8 concurrent tasks
│   ├── TaskPool.pooled() helpers
│   └── High-priority lane
│
├── Memory Management
│   ├── MemoryPressureMonitor
│   ├── Circuit breakers
│   ├── Cache eviction
│   └── Batch processing
│
├── UI Optimization
│   ├── @MainActor discipline
│   ├── BatchedPublished properties
│   ├── 60fps target
│   └── Smooth animations
│
└── Database Optimization
    ├── WAL mode enabled
    ├── Query caching (5min TTL)
    ├── Indexed lookups
    └── Batch operations
```

## 📱 Offline Support

```
Offline Architecture
│
├── NetworkMonitor
│   ├── Connectivity detection
│   ├── State broadcasting
│   └── Auto-recovery
│
├── OfflineQueueManager
│   ├── Action persistence
│   ├── Queue management
│   ├── Retry logic
│   └── Drain on reconnect
│
├── CacheManager
│   ├── TTL-based caching
│   ├── Per-endpoint config
│   ├── Fallback data
│   └── Smart invalidation
│
└── UI Behavior
    ├── Cached data display
    ├── Queue status indicator
    ├── Sync on reconnect
    └── Optimistic updates
```

## 🎨 Design System

```
Glass Design System (AdaptiveGlassModifier)
│
├── GlassButtonStyle
│   ├── .primary (brand color)
│   ├── .secondary (muted)
│   ├── .ghost (transparent)
│   ├── .danger (red accent)
│   └── .success (green accent)
│
├── GlassButtonSize
│   ├── .small (compact)
│   ├── .medium (default)
│   └── .large (prominent)
│
├── Card Helpers
│   ├── glassCard(intensity:cornerRadius:padding:)
│   └── GlassCard background, border, blur
│
└── Theme Tokens
    ├── Colors (role-based accents)
    ├── Typography (SF Pro)
    ├── Spacing (8pt grid)
    └── Animations (spring-based)
```

## 🔍 Weather-Aware Task Scoring

```
WeatherScoreBuilder
│
├── Input Data
│   ├── WeatherSnapshot (global)
│   ├── Task urgency/due time
│   └── Task category
│
├── Scoring Algorithm
│   ├── Precipitation penalty
│   ├── Wind speed factor
│   ├── Temperature adjustment
│   └── Time proximity bonus
│
├── Output Chips
│   ├── goodWindow (optimal)
│   ├── wet (light rain)
│   ├── heavyRain (postpone)
│   ├── windy (caution)
│   ├── hot/cold (advisory)
│   └── urgent (override weather)
│
└── Route Optimization
    └── RouteOperationalBridge
        └── getWeatherOptimizedRoute()
```

## 📋 Key File Mappings

### Views (Canonical)
- Admin: `Views/Main/AdminDashboardView.swift`
- Client: `Views/Main/ClientDashboardView.swift`
- Worker: `Views/Main/WorkerDashboardMainView.swift`
- Buildings: `Views/Components/Buildings/BuildingDetailView.swift`
- Profile: `Views/Admin/AdminProfileView.swift`, `Views/Client/ClientProfileView.swift`

### ViewModels
- Admin: `ViewModels/Dashboard/AdminDashboardViewModel.swift`
- Client: `ViewModels/Dashboard/ClientDashboardViewModel.swift`
- Worker: `ViewModels/Dashboard/WorkerDashboardViewModel.swift`

### Services
- Container: `Services/Core/ServiceContainer.swift`
- NYC: `Services/NYC/NYCAPIService.swift`, `Services/NYC/NYCComplianceService.swift`
- Sync: `Services/Core/DashboardSyncService.swift`
- Clock: `Managers/System/ClockInManager.swift`

### Core
- Types: `Core/Types/CoreTypes.swift`
- Utils: `Core/Utils/DateUtils.swift`
- DB: `Core/Database/GRDBManager.swift`

## 🚦 Critical Connection Points

1. Data Load → ViewModel → UI
   - Service fetches → ViewModel @Published → View auto-updates
2. Weather → Suggestions → Display
   - WeatherDataAdapter → WeatherScoreBuilder → Task chips
3. Routine → Schedule → Time
   - OperationalDataManager → WorkerDashboardViewModel → UI cards
   - RouteOperationalBridge → ClientDashboardViewModel.routePortfolioTodayTasks → ClientDashboardView list
4. NYC Compliance → Analytics → Dashboard
   - NYCHistoricalDataService → AdminDashboardViewModel → Analytics tab
5. Clock-In → Sync → Broadcasting
   - ClockInManager → DashboardSyncService → All dashboards
6. Offline Action → Queue → Sync
   - User action → OfflineQueueManager → NetworkMonitor → Drain

## 📝 Build & Deployment Notes

### Target Membership
✅ Include all canonical files from Views/, ViewModels/, Services/, Core/
❌ Exclude files wrapped with `#if false`
❌ Exclude _Optimized variants
❌ Exclude placeholder/stub implementations

### Clean Build Protocol
1. Clean Build Folder (Cmd+Shift+K)
2. Delete Derived Data if needed
3. Rebuild with CyntientOps scheme
4. Run on iPhone 16 Pro simulator

### Environment Configuration
- NYC_APP_TOKEN (for API access)
- DSNY_API_TOKEN (for DSNY data)
- Development.xcconfig (local settings)

---

Version: Current Production Build
Last Updated: Sync’d with latest code on main
Architecture Status: ✅ Production Ready
