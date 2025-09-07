# CyntientOps SwiftUI Property Management Application
## 🏗️ Comprehensive Architectural Wire Diagram & Analysis

---

## 📱 **APPLICATION FLOW DIAGRAM**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              CyntientOpsApp.swift                                  │
│                    📱 Main App Entry Point + Sentry Monitoring                      │
│                                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │   Sentry Init   │    │ AppStartupCoord │    │ ServiceContainer│                │
│  │   Crash Report  │────│   .shared       │────│   7-Layer DI    │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────┬───────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                              ContentView.swift                                     │
│                         🔀 Role-Based Authentication Router                         │
│                                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │  SplashScreen   │    │   LoginView     │    │  OnboardingView │                │
│  │  Database Init  │────│  NewAuthManager │────│   User Setup    │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
│                                  │                                                 │
│                                  ▼                                                 │
│                         Role Detection & Routing                                   │
│                                  │                                                 │
│           ┌──────────────────────┼──────────────────────┐                         │
│           │                      │                      │                         │
│           ▼                      ▼                      ▼                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐                │
│  │  AdminRole      │    │   ClientRole    │    │   WorkerRole    │                │
│  │  Dashboard      │    │   Dashboard     │    │   Dashboard     │                │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏢 **SERVICE CONTAINER ARCHITECTURE (7-Layer Dependency Injection)**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           ServiceContainer.swift                                   │
│                        🏗️ 7-Layer Architecture Pattern                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 0: 🗄️ DATABASE & DATA FOUNDATION
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  ┌─────────────────────┐              ┌─────────────────────────────────────────┐   │
│  │   GRDBManager       │─────────────│      OperationalDataManager.shared     │   │
│  │   .shared           │              │      📊 Single Source of Truth        │   │
│  │                     │              │                                         │   │
│  │ • SQLite + GRDB     │              │ • 88 Operational Routines              │   │
│  │ • 17+ Tables        │              │ • 17 Manhattan Buildings               │   │
│  │ • Foreign Keys      │              │ • 7 Active Workers                     │   │
│  │ • Sync Queues       │              │ • Real-time Task Scheduling            │   │
│  │ • Migration Support │              │ • Canonical ID Management              │   │
│  └─────────────────────┘              └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 1: 🔧 CORE SERVICES
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │ NewAuthManager  │ │ WorkerService   │ │ BuildingService │ │ TaskService     │ │
│ │ • Biometrics    │ │ • Assignments   │ │ • Building Data │ │ • Scheduling    │ │
│ │ • Session Mgmt  │ │ • Clock In/Out  │ │ • Metrics       │ │ • Progress      │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
│                                                                                     │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │ClockInService   │ │PhotoEvidenceServ│ │ClientService    │ │UserProfileServ │ │
│ │ • Location      │ │ • Camera        │ │ • Portfolio     │ │ • Preferences   │ │
│ │ • Validation    │ │ • Compression   │ │ • Analytics     │ │ • Settings      │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 2: 🧠 BUSINESS LOGIC
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │DashboardSync    │ │BuildingMetrics  │ │ComplianceService│ │DailyOpsReset    │ │
│ │Service          │ │Service          │ │                 │ │                 │ │
│ │ • Real-time     │ │ • Performance   │ │ • NYC APIs      │ │ • Midnight      │ │
│ │ • Combine       │ │ • Analytics     │ │ • Violations    │ │ • Task Reset    │ │
│ │ • Publishers    │ │ • Reporting     │ │ • Predictions   │ │ • Clean State   │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 3: 🤖 UNIFIED INTELLIGENCE
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           UnifiedIntelligenceService                               │
│                                      +                                             │
│                              NovaAIManager.shared                                  │
│                                                                                     │
│ • AI-powered insights      • Scenario planning      • Predictive analytics        │
│ • Holographic interface    • Speech recognition     • Performance optimization     │
│ • Worker productivity      • Cost intelligence      • Route optimization          │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 4: 🎯 CONTEXT ENGINES (Role-Specific Intelligence)
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ ┌─────────────────────┐ ┌─────────────────────┐ ┌─────────────────────┐         │
│ │  AdminContextEngine │ │ ClientContextEngine │ │ WorkerContextEngine │         │
│ │                     │ │                     │ │                     │         │
│ │ • Building oversight│ │ • Portfolio monitor │ │ • Task assignments  │         │
│ │ • Worker management │ │ • Compliance track  │ │ • Route optimization│         │
│ │ • Performance track │ │ • Cost analytics    │ │ • Progress tracking │         │
│ │ • Emergency alerts  │ │ • Intelligence      │ │ • Schedule adherence│         │
│ │ • System monitoring │ │ • Real-time metrics │ │ • Photo evidence    │         │
│ └─────────────────────┘ └─────────────────────┘ └─────────────────────┘         │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 5: ⚡ COMMAND CHAINS
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                          CommandChainManager                                       │
│                        Complex Multi-Step Operations                               │
│                                                                                     │
│ • Worker assignment workflows    • Building compliance audits                      │
│ • Emergency response protocols   • Bulk task scheduling                            │
│ • Photo evidence chains         • Report generation pipelines                     │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 6: 📶 OFFLINE SUPPORT
┌─────────────────────────────────────────────────────────────────────────────────────┐
│ ┌─────────────────────┐                    ┌─────────────────────┐               │
│ │ OfflineQueueManager │                    │    CacheManager     │               │
│ │                     │                    │                     │               │
│ │ • Background sync   │                    │ • Response caching  │               │
│ │ • Retry policies    │                    │ • Image optimization│               │
│ │ • Conflict resolve  │                    │ • Data persistence  │               │
│ └─────────────────────┘                    └─────────────────────┘               │
└─────────────────────────────────────────────────────────────────────────────────────┘

Layer 7: 🌐 NYC API INTEGRATION
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            NYCIntegrationManager                                   │
│                          🏙️ Real-World Data Sources                                │
│                                                                                     │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │DSNYAPIService│ │HPDService   │ │DOBService   │ │LL97Service  │ │BBLGeneration│ │
│ │             │ │             │ │             │ │             │ │Service      │ │
│ │• Sanitation │ │• Housing    │ │• Building   │ │• Emissions  │ │• Property   │ │
│ │• Schedules  │ │• Violations │ │• Permits    │ │• Compliance │ │• Identification│ │
│ │• Real-time  │ │• Compliance │ │• Inspections│ │• Reporting  │ │• BBL Lookup │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🎨 **UI ARCHITECTURE DIAGRAM**

```
                              GLASS DESIGN SYSTEM
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                       Components/Glass/ + Design/                                  │
│                                                                                     │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │  GlassCard  │ │ GlassButton │ │ GlassModal  │ │GlassTabBar  │ │GlassStatus  │ │
│ │             │ │             │ │             │ │             │ │Badge        │ │
│ │• Material   │ │• Interactive│ │• Sheet      │ │• Navigation │ │• Real-time  │ │
│ │• Intensity  │ │• Haptic     │ │• Overlay    │ │• Animated   │ │• Status     │ │
│ │• Gradient   │ │• Animation  │ │• Dismissible│ │• Role-aware │ │• Indicators │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              DASHBOARD HIERARCHY
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                ContentView                                          │
│                            🎯 Role-Based Router                                     │
└─────────────────────────┬─────────────────────┬─────────────────────┬─────────────┘
                          │                     │                     │
                          ▼                     ▼                     ▼
        ┌─────────────────────────┐ ┌─────────────────────────┐ ┌─────────────────────────┐
        │   AdminDashboardView    │ │  ClientDashboardMainView│ │   WorkerDashboardView   │
        │                         │ │                         │ │                         │
        │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │
        │ │ AdminDashboardHeader│ │ │ │ClientDashboardHeader│ │ │ │ WorkerSimpleHeader  │ │
        │ │ • System overview   │ │ │ │ • Portfolio health  │ │ │ │ • Clock status      │ │
        │ │ • Real-time alerts  │ │ │ │ • Compliance score  │ │ │ │ • Current building  │ │
        │ └─────────────────────┘ │ │ └─────────────────────┘ │ │ └─────────────────────┘ │
        │                         │ │                         │ │                         │
        │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │
        │ │AdminRealtimeSection │ │ │ │PortfolioHeroCard    │ │ │ │MyAssignedBuildings  │ │
        │ │ • Live monitoring   │ │ │ │ • Performance ring  │ │ │ │Section              │ │
        │ │ • Worker status     │ │ │ │ • Monthly metrics   │ │ │ │ • Building cards    │ │
        │ │ • Building alerts   │ │ │ │ • Drill-down action │ │ │ │ • Task progress     │ │
        │ └─────────────────────┘ │ │ └─────────────────────┘ │ │ └─────────────────────┘ │
        │                         │ │                         │ │                         │
        │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │
        │ │AdminWorkerStatus    │ │ │ │ClientBuildingGrid   │ │ │ │TodaysProgressDetail │ │
        │ │Section              │ │ │ │Section              │ │ │ │View                 │ │
        │ │ • 7 active workers  │ │ │ │ • Building cards    │ │ │ │ • Task timeline     │ │
        │ │ • Assignment matrix │ │ │ │ • Image previews    │ │ │ │ • Route optimization│ │
        │ │ • Performance data  │ │ │ │ • Metrics overlay   │ │ │ │ • Weather alerts    │ │
        │ └─────────────────────┘ │ │ └─────────────────────┘ │ │ └─────────────────────┘ │
        │                         │ │                         │ │                         │
        │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │ │ ┌─────────────────────┐ │
        │ │AdminBuilding        │ │ │ │ClientCompliance     │ │ │ │WeatherTasksSection  │ │
        │ │PerformanceSection   │ │ │ │Section              │ │ │ │ • Weather API       │ │
        │ │ • Building metrics  │ │ │ │ • DSNY violations   │ │ │ │ • Task impact       │ │
        │ │ • Compliance scores │ │ │ │ • HPD tracking      │ │ │ │ • Safety alerts     │ │
        │ │ • Violation tracking│ │ │ │ • DOB permits       │ │ │ │ • Schedule adjust   │ │
        │ └─────────────────────┘ │ │ └─────────────────────┘ │ │ └─────────────────────┘ │
        └─────────────────────────┘ └─────────────────────────┘ └─────────────────────────┘
```

---

## 🏢 **BUILDING DATA FLOW ARCHITECTURE**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                         🏢 BUILDING MANAGEMENT FLOW                                │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              NYC Open Data APIs
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
        ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
        │   DSNY API      │ │    HPD API      │ │    DOB API      │
        │ • Schedules     │ │ • Violations    │ │ • Permits       │
        │ • Collection    │ │ • Compliance    │ │ • Inspections   │
        │ • Routes        │ │ • Housing code  │ │ • Safety        │
        └─────────────────┘ └─────────────────┘ └─────────────────┘
                    │                 │                 │
                    └─────────────────┼─────────────────┘
                                      ▼
                          ┌─────────────────────────┐
                          │  NYCIntegrationManager  │
                          │                         │
                          │ • Data normalization    │
                          │ • BBL property mapping  │
                          │ • Real-time sync        │
                          │ • Compliance aggregation│
                          └─────────────────────────┘
                                      │
                                      ▼
                          ┌─────────────────────────┐
                          │ OperationalDataManager  │
                          │      📊 MASTER DATA     │
                          │                         │
                          │ • 17 Manhattan Buildings│
                          │ • 88 Operational Routines│
                          │ • Worker Assignments    │
                          │ • Task Scheduling       │
                          │ • Compliance Tracking   │
                          └─────────────────────────┘
                                      │
                          ┌───────────┼───────────┐
                          │           │           │
                          ▼           ▼           ▼
              ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
              │AdminContext     │ │ClientContext    │ │WorkerContext    │
              │Engine           │ │Engine           │ │Engine           │
              │                 │ │                 │ │                 │
              │• Building       │ │• Portfolio      │ │• Assigned       │
              │  performance    │ │  health         │ │  buildings      │
              │• Worker metrics │ │• Compliance     │ │• Task routes    │
              │• Alert systems  │ │  overview       │ │• Schedule       │
              │• System health  │ │• Cost analysis  │ │  adherence      │
              └─────────────────┘ └─────────────────┘ └─────────────────┘
```

---

## 📊 **DATA RELATIONSHIP DIAGRAM**

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            🗄️ DATABASE SCHEMA OVERVIEW                             │
└─────────────────────────────────────────────────────────────────────────────────────┘

                              GRDB SQLite Database
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
        ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
        │     USERS       │ │   BUILDINGS     │ │     TASKS       │
        │                 │ │                 │ │                 │
        │ • id (PK)       │ │ • id (PK)       │ │ • id (PK)       │
        │ • name          │ │ • name          │ │ • title         │
        │ • email         │ │ • address       │ │ • building_id   │
        │ • role          │ │ • latitude      │ │ • worker_id     │
        │ • auth_token    │ │ • longitude     │ │ • status        │
        │ • biometric     │ │ • imageAssetName│ │ • scheduled_date│
        └─────────────────┘ └─────────────────┘ └─────────────────┘
                │                     │                     │
                │     ┌───────────────┼───────────────┐     │
                │     │               │               │     │
                ▼     ▼               ▼               ▼     ▼
        ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
        │ WORKER_PROFILES │ │ TASK_ASSIGNMENTS│ │ PHOTO_EVIDENCE  │
        │                 │ │                 │ │                 │
        │ • user_id (FK)  │ │ • task_id (FK)  │ │ • task_id (FK)  │
        │ • capabilities  │ │ • worker_id(FK) │ │ • photo_path    │
        │ • certifications│ │ • building_id   │ │ • timestamp     │
        │ • status        │ │ • assigned_date │ │ • category      │
        └─────────────────┘ └─────────────────┘ └─────────────────┘
                                      │
                                      ▼
                          ┌─────────────────────────┐
                          │   COMPLIANCE_TRACKING  │
                          │                         │
                          │ • building_id (FK)     │
                          │ • violation_type       │
                          │ • department (DSNY/HPD)│
                          │ • issue_date           │
                          │ • resolution_status    │
                          │ • severity_level       │
                          └─────────────────────────┘
```

---

## 🎯 **CRITICAL ARCHITECTURAL INSIGHTS**

### **1. Single Source of Truth Pattern**
- **OperationalDataManager** is the master data coordinator
- All Context Engines derive their data from this single source
- Prevents data inconsistency across role-specific views
- **File**: `CyntientOps/Managers/System/OperationalDataManager.swift`

### **2. Real-Time Data Synchronization**
- **DashboardSyncService** uses Combine publishers for live updates
- **Background sync** via OfflineQueueManager for reliability
- **Conflict resolution** strategies for offline/online data merging
- **NYC API polling** with intelligent caching and rate limiting

### **3. Building Image Integration System**
- **Asset mapping** from building addresses to image asset names
- **Graceful fallbacks** with gradient backgrounds
- **Consistent display** across all dashboards (Admin, Client, Worker)
- **Components**: PropertyCard, ClientBuildingCard, BuildingStatsGlassCard

### **4. Role-Based Access Control**
- **Authentication**: NewAuthManager with biometric support
- **Context Engines** provide role-specific data views
- **UI Components** adapt based on user role
- **Permission system** controls feature access

### **5. NYC Compliance Integration**
- **4 Major APIs**: DSNY, HPD, DOB, LL97
- **BBL Generation** for NYC property identification
- **Real-time violation** tracking and alerts
- **Compliance scoring** algorithms for portfolio health

This architectural analysis provides the forensic-level understanding needed to make informed development decisions and understand the complete application ecosystem!

<function_calls>
<invoke name="TodoWrite">
<parameter name="todos">[{"content": "Create visual wire diagrams for app architecture", "status": "completed", "id": "128"}]