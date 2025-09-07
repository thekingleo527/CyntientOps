# 🚀 **CYNTIENTOPS HIERARCHICAL REFACTOR: COMPLETE PRODUCTION BASELINE**
## **FROM BROKEN STATE TO 100% PRODUCTION READY**
### **Version: 4.0 | Total Timeline: 21 Days | 158 Hours**

---

## **📊 EXECUTIVE SUMMARY**

```yaml
PROJECT: CyntientOps (formerly FrancoSphere)
STATUS: Currently broken with mock data
TARGET: 100% production-ready with real data

CRITICAL ISSUES TO FIX:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Mock data overriding real data (88 templates unused)
2. Three competing intelligence systems
3. Excessive singletons breaking dependency flow
4. Nova AI not persistent across app
5. Kevin missing 38 real tasks
6. Client data not filtered properly
7. No NYC API integrations
8. Missing compliance suite
9. Tab navigation instead of single-scroll
10. No command chains for resilience
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## **🏢 PRODUCTION DATA REALITY**

```yaml
WORKERS (7 Active):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID  Name                Role        Focus Area              Special Requirements
1   Greg Hutson         Manager     Maintenance/Admin       Full dashboard access
2   Edwin Lema          Worker      Stuyvesant Cove        Standard UI
4   Kevin Dutan         Worker      JM Buildings/Rubin      38 tasks, photo required
5   Mercedes Inamagua   Worker      Glass cleaning          Simplified Spanish UI
6   Luis Lopez          Worker      Perry St maintenance    Standard UI
7   Angel Guiracocha    Worker      Evening DSNY           Night shift UI
8   Shawn Magloire      Manager     HVAC/Advanced          Full dashboard access

CLIENTS (6 Active):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
JM Realty:           9 buildings (IDs: 3,5,6,7,9,10,11,14,21)
Weber Farhat:        1 building (ID: 13)
Solar One:           1 building (ID: 16 - Stuyvesant Cove Park)
Grand Elizabeth LLC: 1 building (ID: 8)
Citadel Realty:      2 buildings (IDs: 4,18)
Corbel Property:     1 building (ID: 15)

BUILDINGS (16 Active):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3:  135-139 West 17th (JM Realty)
4:  104 Franklin (Citadel Realty)
5:  138 West 17th (JM Realty)
6:  68 Perry (JM Realty)
7:  112 West 18th (JM Realty)
8:  41 Elizabeth Street (Grand Elizabeth)
9:  117 West 17th (JM Realty)
10: 131 Perry (JM Realty)
11: 123 1st Ave (JM Realty)
13: 136 West 17th (Weber Farhat)
14: Rubin Museum (JM Realty) ← KEVIN'S PRIMARY
15: 133 East 15th (Corbel Property)
16: Stuyvesant Cove Park (Solar One)
18: 36 Walker (Citadel Realty)
21: 148 Chambers (JM Realty) ← NEW

REMOVED: Building 2 (29-31 East 20th) - Discontinued
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## **🏗️ ARCHITECTURE TRANSFORMATION**

### **CURRENT BROKEN STATE**
```
Problems:
- Mock data everywhere (WorkerDashboardViewModel creates fake tasks)
- 3 competing intelligence systems (Nova, Intelligence, Features)
- Singletons for everything (.shared pattern abuse)
- Nova AI not persistent (recreated each view)
- Tab navigation (not single scroll)
- No dependency injection
- No offline support
- No NYC API integrations
```

### **TARGET ARCHITECTURE**
```
Solutions:
- ServiceContainer with dependency injection
- Single UnifiedIntelligenceService
- NovaAIManager.shared (only singleton that persists)
- Single-scroll dashboards
- Command chains for all operations
- Offline queue support
- Full NYC API integration suite
```

---

## **📋 PHASE 0: NOVA AI PERSISTENCE & PREREQUISITES**
### **Priority: CRITICAL | Timeline: Day 1 (12 hours)**

```swift
☐ 0.1: Create NovaAIManager Singleton
   Location: App/NovaAIManager.swift
   ```swift
   import SwiftUI
   import Combine
   
   @MainActor
   public final class NovaAIManager: ObservableObject {
       public static let shared = NovaAIManager()
       
       @Published public var novaState: NovaState = .idle
       @Published public var novaImage: UIImage?
       @Published public var animationPhase: Double = 0
       @Published public var pulseAnimation = false
       @Published public var rotationAngle: Double = 0
       @Published public var hasUrgentInsights = false
       @Published public var thinkingParticles: [Particle] = []
       
       public enum NovaState {
           case idle, thinking, active, urgent, error
       }
       
       private var animationTimer: Timer?
       
       private init() {
           loadNovaImage()
           startPersistentAnimations()
       }
       
       private func loadNovaImage() {
           self.novaImage = UIImage(named: "AIAssistant")
       }
       
       private func startPersistentAnimations() {
           animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
               Task { @MainActor in
                   self.updateAnimations()
               }
           }
       }
   }
   ```

☐ 0.2: Create App Startup Coordinator
   Location: App/AppStartupCoordinator.swift
   ```swift
   @MainActor
   public final class AppStartupCoordinator {
       private let container: ServiceContainer
       
       public init() async throws {
           // Phase 1: Database initialization
           let dbManager = GRDBManager.shared
           try await dbManager.initialize()
           
           // Phase 2: Verify operational data
           let opData = OperationalDataManager.shared
           assert(opData.getRealWorldTasks().count == 88, "Must have 88 task templates")
           assert(opData.getAllWorkers().count == 7, "Must have 7 workers")
           
           // Phase 3: Create service container
           self.container = try await ServiceContainer()
           
           // Phase 4: Initialize Nova
           let nova = NovaAIManager.shared
           container.setNovaManager(nova)
           
           // Phase 5: Verify Kevin's tasks
           let kevinTasks = opData.getKevinTasks()
           assert(kevinTasks.count == 38, "Kevin must have 38 tasks")
       }
   }
   ```

☐ 0.3: Update Main App Entry
   Location: CyntientOpsApp.swift (rename from FrancoSphereApp.swift)
   ```swift
   import SwiftUI
   
   @main
   struct CyntientOpsApp: App {
       @StateObject private var novaAI = NovaAIManager.shared
       @State private var container: ServiceContainer?
       @State private var isLoading = true
       @State private var loadError: Error?
       
       var body: some Scene {
           WindowGroup {
               if isLoading {
                   LoadingView()
                       .task {
                           do {
                               let coordinator = try await AppStartupCoordinator()
                               self.container = coordinator.container
                               self.isLoading = false
                           } catch {
                               self.loadError = error
                               self.isLoading = false
                           }
                       }
               } else if let container = container {
                   ContentView()
                       .environmentObject(novaAI)
                       .environmentObject(container)
               } else if let error = loadError {
                   ErrorView(error: error)
               }
           }
       }
   }
   ```

☐ 0.4: Create ClockInService ObservableObject
   Location: Services/Core/ClockInService.swift
   ```swift
   @MainActor
   public final class ClockInService: ObservableObject {
       @Published public var clockedInWorkers: [String: ClockInRecord] = [:]
       @Published public var isProcessing = false
       
       private let database: GRDBManager
       private let workers: WorkerService
       private let location: LocationManager
       
       public init(database: GRDBManager, workers: WorkerService, location: LocationManager) {
           self.database = database
           self.workers = workers
           self.location = location
       }
   }
   ```

☐ 0.5: Network Monitor Setup
   Location: Services/Network/NetworkMonitor.swift
   ```swift
   import Network
   import Combine
   
   public final class NetworkMonitor: ObservableObject {
       @Published public var isConnected = true
       private let monitor = NWPathMonitor()
       private let queue = DispatchQueue(label: "NetworkMonitor")
       
       public init() {
           monitor.pathUpdateHandler = { path in
               DispatchQueue.main.async {
                   self.isConnected = path.status == .satisfied
               }
           }
           monitor.start(queue: queue)
       }
   }
   ```

☐ 0.6: Keychain Manager
   Location: Services/Security/KeychainManager.swift
   ```swift
   public final class KeychainManager {
       public static let shared = KeychainManager()
       
       public func save(_ data: Data, for key: String) throws
       public func load(for key: String) throws -> Data?
       public func delete(for key: String) throws
   }
   ```
```

---

## **📋 PHASE 0A: AUTHENTICATION & SECURITY**
### **Timeline: Day 1 Continued (4 hours)**

```yaml
☐ 0A.1: Database Seed Script
   Location: Database/Seeds/ProductionSeeds.swift
   
   USERS TO CREATE:
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   System Admin:
   - admin@cyntientops.com (SHA256 hash)
   
   Managers:
   - greg.hutson@cyntientops.com (ID: 1)
   - shawn.magloire@cyntientops.com (ID: 8)
   
   Workers:
   - edwin.lema@cyntientops.com (ID: 2)
   - kevin.dutan@cyntientops.com (ID: 4)
   - mercedes.inamagua@cyntientops.com (ID: 5)
   - luis.lopez@cyntientops.com (ID: 6)
   - angel.guiracocha@cyntientops.com (ID: 7)
   
   Client Users:
   - jm@jmrealty.com (JM Realty primary)
   - sarah@jmrealty.com (JM Realty secondary)
   - david@weberfarhat.com (Weber Farhat)
   - maria@solarone.org (Solar One)
   - robert@grandelizabeth.com (Grand Elizabeth)
   - alex@citadelrealty.com (Citadel Realty)
   - jennifer@corbelproperty.com (Corbel Property)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

☐ 0A.2: Worker Capabilities Configuration
   ```sql
   UPDATE workers SET 
     simplified_interface = true,
     language = 'es'
   WHERE id = '5'; -- Mercedes
   
   UPDATE workers SET
     requires_photo_for_sanitation = true
   WHERE id = '4'; -- Kevin
   
   UPDATE workers SET
     dsny_specialist = true,
     shift_type = 'evening'
   WHERE id = '7'; -- Angel
   ```

☐ 0A.3: Biometric Configuration
   Info.plist additions:
   - NSFaceIDUsageDescription
   - Privacy descriptions
   
☐ 0A.4: Security Manager
   - QuickBooks OAuth token storage
   - Photo encryption with 24hr TTL
   - NYC API key management
```

---

## **📋 PHASE 0B: CLIENT-BUILDING RELATIONSHIPS**
### **Timeline: Day 2 (6 hours)**

```sql
☐ 0B.1: Database Schema
   CREATE TABLE clients (
       id TEXT PRIMARY KEY,
       name TEXT NOT NULL,
       contact_email TEXT,
       contract_type TEXT,
       monthly_value REAL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   
   CREATE TABLE client_buildings (
       client_id TEXT REFERENCES clients(id),
       building_id TEXT REFERENCES buildings(id),
       PRIMARY KEY (client_id, building_id)
   );
   
   CREATE TABLE client_users (
       email TEXT PRIMARY KEY,
       client_id TEXT REFERENCES clients(id),
       name TEXT,
       role TEXT,
       can_view_financials BOOLEAN DEFAULT false
   );

☐ 0B.2: Seed Client Data
   INSERT INTO clients:
   - JM Realty (9 buildings)
   - Weber Farhat (1 building)
   - Solar One (1 building)
   - Grand Elizabeth LLC (1 building)
   - Citadel Realty (2 buildings)
   - Corbel Property (1 building)

☐ 0B.3: Building Updates
   - DEACTIVATE building_id = '2' (29-31 E 20th)
   - ADD building_id = '21' (148 Chambers, JM Realty)
   - ADD BIN numbers for all buildings
   - ADD BBL codes for DOF lookups
```

---

## **📋 PHASE 0C: NYC API INTEGRATION LAYER**
### **Timeline: Day 3 (8 hours)**

```swift
☐ 0C.1: NYC API Service Base
   Location: Services/NYC/NYCAPIService.swift
   ```swift
   public class NYCAPIService {
       private let apiKey: String
       private let session: URLSession
       private let cache: CacheManager
       
       public enum APIEndpoint {
           case hpdViolations(bin: String)
           case dobPermits(bin: String)
           case dsnySchedule(district: String)
           case ll97Compliance(bbl: String)
           case depWaterUsage(account: String)
           case fdnyInspections(bin: String)
           case conEdisonOutages(zip: String)
           case complaints311(bin: String)
       }
       
       public func fetch<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
   }
   ```

☐ 0C.2: HPD Integration
   Location: Services/NYC/HPDService.swift
   - Violations endpoint with auto-task creation
   - Complaints monitoring
   - Registration status
   - Violation-to-task mapping

☐ 0C.3: DOB Integration
   Location: Services/NYC/DOBService.swift
   - Permit tracking
   - ECB violations
   - Inspection scheduling
   - Certificate of occupancy

☐ 0C.4: Utility Monitoring
   Location: Services/NYC/UtilityService.swift
   - DEP water usage anomaly detection
   - Con Edison integration
   - Meter reading imports
   - Peak usage optimization

☐ 0C.5: LL97 Compliance
   Location: Services/NYC/LL97Service.swift
   - Emissions tracking
   - Fine calculations
   - Compliance roadmap
   - ROI prioritization
```

---

## **📋 PHASE 1: DELETE MOCK DATA & CLEAN**
### **Timeline: Day 4 (4 hours)**

```bash
☐ 1.1: File Deletion List
   rm Components/Cards/CoverageInfoCard.swift
   rm Components/Cards/MySitesCard.swift
   rm Components/Design/AbstractFrancoSphereLogo.swift
   rm Components/Common/BuildingServiceWrapper.swift
   rm -rf Views/Main/Simplified/* (KEEP SimplifiedDashboard.swift)
   rm Components/Design/WeatherTaskTimelineCard.swift

☐ 1.2: Remove Mock Methods
   File: ViewModels/Dashboard/WorkerDashboardViewModel.swift
   DELETE LINES: 200-400
   - setupMockData()
   - loadMockTasks()
   - createMockBuildings()
   
   File: ViewModels/Dashboard/AdminDashboardViewModel.swift
   DELETE LINES: 150-600
   - setupMockData()
   - createMockWorkers()
   - generateMockMetrics()
   
   File: ViewModels/Dashboard/ClientDashboardViewModel.swift
   DELETE ALL MOCK METHODS:
   - createMockPortfolio()
   - generateMockCompliance()

☐ 1.3: Git Backup
   git checkout -b pre-refactor-backup
   git add . && git commit -m "Pre-refactor backup"
   git checkout -b hierarchical-refactor
```

---

## **📋 PHASE 2: SERVICE CONTAINER ARCHITECTURE**
### **Timeline: Day 5 (8 hours)**

```swift
☐ 2.1: Create ServiceContainer
   Location: Services/Core/ServiceContainer.swift
   ```swift
   @MainActor
   public final class ServiceContainer: ObservableObject {
       // Layer 0: Database
       public let database: GRDBManager
       public let operationalData: OperationalDataManager
       
       // Layer 1: Core Services
       public let auth: AuthenticationService
       public let workers: WorkerService
       public let buildings: BuildingService
       public let tasks: TaskService
       public let clockIn: ClockInService
       public let photos: PhotoEvidenceService
       
       // Layer 2: Business Logic
       public let dashboardSync: DashboardSyncService
       public let metrics: BuildingMetricsService
       public let compliance: ComplianceService
       public let dailyOps: DailyOpsReset
       
       // Layer 3: Unified Intelligence
       public let intelligence: UnifiedIntelligenceService
       
       // Layer 4: Context Engines
       public let workerContext: WorkerContextEngine
       public let adminContext: AdminContextEngine
       public let clientContext: ClientContextEngine
       
       // Layer 5: Command Chains
       public let commands: CommandChainManager
       
       // Layer 6: Offline Support
       public let offlineQueue: OfflineQueueManager
       public let cache: CacheManager
       
       // Layer 7: NYC APIs
       public let nycAPIs: NYCAPIManager
       
       // Nova AI Reference
       private weak var novaManager: NovaAIManager?
       
       public init() async throws {
           // Initialize all layers in order
           // Wire dependencies properly
           // No .shared except LocationManager
       }
   }
   ```

☐ 2.2: Dependency Wiring Rules
   - NO singletons except: LocationManager, NovaAIManager, PhotoEvidenceService
   - All services get dependencies through constructor
   - ServiceContainer owns lifecycle
   - Circular refs only for Context Engines
```

---

## **📋 PHASE 3: UNIFIED INTELLIGENCE SYSTEM**
### **Timeline: Day 6 (10 hours)**

```swift
☐ 3.1: Merge Intelligence Systems
   Location: Services/Intelligence/UnifiedIntelligenceService.swift
   
   MERGE THESE THREE:
   1. Nova/Core/NovaIntelligenceEngine.swift
   2. Services/IntelligenceService.swift
   3. Nova/Core/NovaFeatureManager.swift
   
   INTO SINGLE SERVICE:
   ```swift
   @MainActor
   public final class UnifiedIntelligenceService: ObservableObject {
       @Published public var insights: [IntelligenceInsight] = []
       @Published public var scenarios: [AIScenario] = []
       @Published public var processingState: ProcessingState = .idle
       
       private weak var novaManager: NovaAIManager?
       
       // Merged engines
       private let navigationEngine: NavigationEngine
       private let analyticsEngine: AnalyticsEngine
       private let featureEngine: FeatureEngine
       private let complianceEngine: ComplianceEngine // NEW
       
       public func getInsights(for role: UserRole) -> [IntelligenceInsight] {
           switch role {
           case .worker:
               return insights.filter { 
                   $0.category == .operations || 
                   $0.category == .weather ||
                   $0.category == .safety
               }
           case .admin:
               return insights // Admin sees all
           case .client:
               return insights.filter {
                   $0.category == .compliance ||
                   $0.category == .cost ||
                   $0.category == .performance
               }
           case .manager:
               return insights.filter { $0.category != .cost }
           }
       }
   }
   ```

☐ 3.2: Delete Old Systems
   rm Nova/Core/NovaIntelligenceEngine.swift
   rm Services/IntelligenceService.swift
   rm Nova/Core/NovaFeatureManager.swift
```

---

## **📋 PHASE 4: EXACT DASHBOARD IMPLEMENTATIONS**
### **Timeline: Day 7-8 (16 hours)**

### **4A: WORKER DASHBOARD**
```swift
☐ Location: Views/Main/WorkerDashboardMainView.swift
   
   STRUCTURE:
   ├── Header (60px) - Fixed
   ├── Hero Card (280px → 80px on scroll)
   ├── ScrollView with LazyVStack
   │   ├── Urgent Tasks Section
   │   ├── Current Building Section
   │   └── Today's Tasks Section
   └── Nova Intelligence Bar (60px → 300px expanded)
   
   KEVIN SPECIFIC:
   - Must show "38 tasks" in header
   - Must show "Rubin Museum" as current building
   - Photo requirements highlighted
   - Progress: 15/38 (39%)
```

### **4B: ADMIN DASHBOARD**
```swift
☐ Location: Views/Main/AdminDashboardMainView.swift
   
   STRUCTURE:
   ├── Admin Header with Focus Modes (100px)
   ├── Hero Status Card (320px)
   ├── Management View (based on focus)
   │   ├── Overview: Portfolio grid
   │   ├── Buildings: 17 building cards
   │   ├── Workers: 7 worker management cards
   │   ├── Tasks: Task overview
   │   └── Alerts: Critical alerts
   ├── Real-Time Activity Feed (150px)
   └── Nova Admin Overlay
   
   MUST SHOW:
   - All 7 workers with real data
   - All 16 active buildings
   - Real-time updates from workers
```

### **4C: CLIENT DASHBOARD**
```swift
☐ Location: Views/Main/ClientDashboardMainView.swift
   
   STRUCTURE:
   ├── Executive Header (80px)
   ├── KPI Bar (40px)
   ├── Client Hero Card (280px)
   ├── Portfolio Grid (2 columns)
   │   └── Filtered by client ownership
   ├── Executive Intelligence Panel
   └── Nova Executive Assistant
   
   CLIENT FILTERING:
   - JM Realty: Only sees 9 buildings
   - Weber Farhat: Only sees 1 building
   - No cross-client data leakage
```

---

## **📋 PHASE 4A: ENHANCED CLIENT DASHBOARD**
### **Timeline: Day 9-10 (16 hours)**

```yaml
☐ 4A.1: 5-Tab Navigation Structure
   Tabs: Overview | Compliance | Operations | Financials | Capital
   - Swipeable on iPad/mobile
   - Persistent Nova panel
   
☐ 4A.2: Unified Compliance Suite
   Components:
   - Overall compliance score
   - 6 categories (HPD, DOB, FDNY, LL97, LL11, DEP)
   - Critical deadlines timeline
   - Building-specific drill-downs
   
☐ 4A.3: HPD Violations View
   - Active violations by building
   - Resolution tracking
   - Auto-task generation
   - Historical analytics
   
☐ 4A.4: Utilities Monitoring
   - DEP water usage charts
   - Leak detection alerts
   - Electrical demand curves
   - Peak usage optimization
   
☐ 4A.5: LL97 Emissions Dashboard
   - Building compliance status
   - Fine calculations
   - Reduction roadmap
   - ROI prioritization
```

---

## **📋 PHASE 5: NOVA AI COMPONENTS**
### **Timeline: Day 11 (6 hours)**

```swift
☐ 5.1: Nova Avatar Component
   Location: Components/Nova/NovaAvatarView.swift
   Features:
   - Loads AIAssistant.png from Assets
   - Breathing animation (continuous)
   - Rotation when thinking
   - Pulse on urgent
   - Thinking particles
   - Urgent indicator badge

☐ 5.2: Nova Intelligence Bar
   Location: Components/Nova/NovaIntelligenceBar.swift
   Features:
   - Compact (60px) and expanded (300px) states
   - Insight rotation every 5 seconds
   - Critical/urgent badges
   - Role-based insight filtering

☐ 5.3: Nova Overlays
   - NovaAdminOverlay.swift
   - NovaExecutiveAssistant.swift
   - NovaWorkerHelper.swift
```

---

## **📋 PHASE 6: COMMAND CHAINS**
### **Timeline: Day 12 (8 hours)**

```swift
☐ 6.1: Command Chain Manager
   Location: Services/Commands/CommandChainManager.swift
   
☐ 6.2: Implement Chains
   TaskCompletionChain:
   1. Validate task/worker
   2. Check photo requirement
   3. Database transaction
   4. Real-time sync
   5. Intelligence update
   
   ClockInChain:
   1. Validate location
   2. Check building access
   3. Create record
   4. Load tasks
   5. Update dashboards
   
   PhotoCaptureChain:
   1. Capture image
   2. Encrypt with TTL
   3. Generate thumbnail
   4. Upload to storage
   5. Link to task
   
   ComplianceResolutionChain (NEW):
   1. Fetch violation
   2. Create resolution task
   3. Assign to worker
   4. Set deadline
   5. Monitor progress
```

---

## **📋 PHASE 7: OFFLINE SUPPORT**
### **Timeline: Day 13 (6 hours)**

```swift
☐ 7.1: Offline Queue Manager
   Location: Services/Offline/OfflineQueueManager.swift
   ```swift
   public final class OfflineQueueManager {
       private var queue: [OfflineAction] = []
       
       public func enqueue(_ action: OfflineAction)
       public func processQueue() async
       private func persistQueue()
       private func loadQueue()
   }
   ```

☐ 7.2: Cache Manager
   Location: Services/Cache/CacheManager.swift
   - TTL-based memory cache
   - 5-minute default expiry
   - Thread-safe operations
   - NYC API response caching

☐ 7.3: Network Monitor Integration
   - Auto-sync when reconnected
   - Queue persistence
   - Retry logic
```

---

## **📋 PHASE 8: DATA FLOW FIXES**
### **Timeline: Day 14 (8 hours)**

```swift
☐ 8.1: Fix OperationalDataManager
   Location: System/OperationalDataManager.swift
   
   MUST RETURN:
   - getAllWorkers() → 7 workers
   - getKevinTasks() → 38 tasks
   - getRubinMuseumTasks() → tasks for building 14
   - getWorkerBuildings("4") → includes building 14

☐ 8.2: Fix DailyOpsReset
   Location: Services/System/DailyOpsReset.swift
   
   VERIFY:
   - generateDailyTasks() creates 88 tasks
   - Kevin gets exactly 38 tasks
   - Tasks distributed correctly by worker

☐ 8.3: Fix ViewModels
   WorkerDashboardViewModel:
   - Remove ALL mock data
   - Load from container.tasks
   - Verify Kevin has 38 tasks
   
   AdminDashboardViewModel:
   - Show all 7 real workers
   - Show all 16 active buildings
   
   ClientDashboardViewModel:
   - Filter by client ownership
   - No cross-client data
```

---

## **📋 PHASE 9: NYC API IMPLEMENTATION**
### **Timeline: Day 15-16 (16 hours)**

```yaml
☐ 9.1: HPD Violations Integration
   - Real-time violation sync
   - Auto-task creation
   - Deadline tracking
   - Resolution workflow

☐ 9.2: DOB Permits & Inspections
   - Permit expiration alerts
   - Inspection scheduling
   - ECB violation tracking
   - Certificate management

☐ 9.3: LL97 Compliance Tracking
   - Building emissions data
   - Fine calculations
   - Reduction strategies
   - ROI analysis

☐ 9.4: Utility Monitoring
   - Water usage anomalies
   - Peak demand alerts
   - Leak detection
   - Cost optimization

☐ 9.5: 311 Complaints
   - Real-time monitoring
   - Auto-assignment
   - Response tracking
   - SLA management
```

---

## **📋 PHASE 10: COMPLIANCE INTELLIGENCE**
### **Timeline: Day 17-18 (16 hours)**

```swift
☐ 10.1: Violation Prediction Engine
   Location: Services/Intelligence/ViolationPredictor.swift
   - Historical pattern analysis
   - Building risk scoring
   - Preventive suggestions
   - ROI calculations

☐ 10.2: Automated Workflows
   - Violation → Task
   - Deadline → Calendar
   - Completion → Certification
   - Evidence → Filing

☐ 10.3: Cost Intelligence
   - Fine predictions
   - Contractor comparisons
   - Budget impact
   - Savings opportunities

☐ 10.4: Real-time Monitoring
   - NYC webhooks
   - Push notifications
   - Dashboard updates
   - Nova alerts
```

---

## **📋 PHASE 11: TESTING & VALIDATION**
### **Timeline: Day 19 (8 hours)**

```swift
☐ 11.1: Automated Test Suite
   Location: Tests/Integration/ProductionTests.swift
   
   CRITICAL TESTS:
   ```swift
   func testKevinHas38Tasks() async throws {
       let tasks = try await container.tasks.getTasks(for: "4", date: Date())
       XCTAssertEqual(tasks.count, 38, "Kevin must have exactly 38 tasks")
   }
   
   func testRubinMuseumAssignment() async throws {
       let buildings = OperationalDataManager.shared.getWorkerBuildings(workerId: "4")
       XCTAssertTrue(buildings.contains("14"), "Kevin must have Rubin Museum")
   }
   
   func testNovaAIPersistence() async throws {
       let nova1 = NovaAIManager.shared
       let nova2 = NovaAIManager.shared
       XCTAssertTrue(nova1 === nova2, "Nova must be singleton")
       XCTAssertNotNil(nova1.novaImage, "Nova image must load")
   }
   
   func testClientFiltering() async throws {
       // JM Realty should only see their 9 buildings
       let jmBuildings = try await container.buildings.getClientBuildings("jm-realty")
       XCTAssertEqual(jmBuildings.count, 9)
       XCTAssertTrue(jmBuildings.contains { $0.id == "14" }) // Includes Rubin
   }
   
   func testNYCAPIIntegration() async throws {
       let violations = try await container.nycAPIs.hpd.getViolations(for: "14")
       XCTAssertNotNil(violations)
   }
   ```

☐ 11.2: Manual Testing Matrix
   ☐ Worker Logins (All 7)
   ☐ Client Logins (All 6)
   ☐ Kevin sees 38 tasks
   ☐ Rubin Museum appears
   ☐ Nova animations work
   ☐ Photo capture works
   ☐ Offline mode works
   ☐ NYC APIs respond
   ☐ Compliance suite loads
```

---

## **📋 PHASE 12: REBRAND**
### **Timeline: Day 20 (4 hours)**

```yaml
☐ 12.1: Global Rename
   - FrancoSphere → CyntientOps everywhere
   - Update bundle identifier
   - Update display name
   - Update app icon

☐ 12.2: File Renames
   - FrancoSphereApp.swift → CyntientOpsApp.swift
   - All references in code
   - All references in comments
```

---

## **📋 PHASE 13: PRODUCTION DEPLOYMENT**
### **Timeline: Day 21 (8 hours)**

```yaml
☐ 13.1: Pre-Launch Verification
   Component                    Required State              Status
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Nova AI                     Persistent, animated         [ ]
   Kevin's Tasks              38 tasks verified            [ ]
   Rubin Museum               In Kevin's buildings         [ ]
   Mock Data                  COMPLETELY REMOVED           [ ]
   Service Container          All dependencies wired       [ ]
   Intelligence               Single unified service       [ ]
   Client Filtering           No data leakage             [ ]
   NYC APIs                   All integrated              [ ]
   Compliance Suite           Fully functional            [ ]
   Offline Support            Queue working               [ ]
   
☐ 13.2: TestFlight Beta
   - Internal testing
   - Client preview (JM Realty first)
   - Worker training
   - Compliance demo

☐ 13.3: App Store Submission
   - Screenshots (all dashboards)
   - Description emphasizing NYC compliance
   - Review notes
   - Production URLs
```

---

## **🎯 CRITICAL SUCCESS METRICS**

```yaml
MUST ACHIEVE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Nova AI persists with continuous animations      ✓ Required
2. Kevin sees exactly 38 real tasks                ✓ Required  
3. Rubin Museum (14) in Kevin's buildings          ✓ Required
4. All mock data completely removed                ✓ Required
5. Single intelligence system                      ✓ Required
6. Service container dependency injection          ✓ Required
7. Client data properly filtered                   ✓ Required
8. NYC APIs integrated and working                 ✓ Required
9. Compliance suite operational                    ✓ Required
10. App launches in < 2 seconds                    ✓ Required

PERFORMANCE TARGETS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Memory Usage:        < 100MB sustained
Crash-Free Rate:     > 99.5%
API Response Time:   < 500ms average
Offline Queue:       100% reliable sync
Battery Impact:      < 3% per hour active use
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## **💻 TERMINAL EXECUTION COMMANDS**

```bash
# Phase 0: Setup
cd ~/FrancoSphere
git checkout -b production-refactor
mkdir -p App Services/Core Services/NYC Services/Commands

# Phase 1: Clean
find . -name "*Mock*" -type f -delete
rm -rf Views/Main/Simplified/*
rm Components/Cards/CoverageInfoCard.swift
rm Components/Cards/MySitesCard.swift

# Phase 2-13: Implementation
# Use Claude Code to implement each phase systematically

# Testing
swift test --filter CyntientOpsTests.ProductionTests

# Build
xcodebuild -scheme CyntientOps -configuration Release

# Archive
xcodebuild archive -scheme CyntientOps -archivePath build/CyntientOps.xcarchive

# Export
xcodebuild -exportArchive -archivePath build/CyntientOps.xcarchive -exportPath build
```

---

## **📝 FINAL NOTES**

This document represents the complete baseline for making CyntientOps 100% production ready. Every phase has been detailed with exact implementation requirements. The transformation from FrancoSphere's broken state to CyntientOps' production system requires strict adherence to this plan.

**Critical Path:**
1. Nova AI persistence MUST be implemented first
2. Mock data MUST be completely removed
3. Kevin MUST have exactly 38 tasks
4. Service Container MUST manage all dependencies
5. NYC APIs MUST be integrated for compliance

**Do NOT proceed to the next phase until the current phase passes all tests.**

---

**Document Version:** 4.0  
**Last Updated:** Current  
**Total Implementation Time:** 158 hours across 21 days  
**Required for Production:** 100% completion of all phases
