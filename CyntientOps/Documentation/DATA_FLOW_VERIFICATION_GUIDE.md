# End-to-End Data Flow Verification Guide

## 🔄 Complete Data Flow Mapping for CyntientOps

### Weather Suggestions Data Flow
```
WeatherDataAdapter
    ↓ (fetchWeatherData)
WorkerDashboardViewModel.loadWeatherForBuilding()
    ↓ (weather property set)
updateWeatherSuggestions(with: weather)
    ↓ (process tasks with WeatherScoreBuilder)
weatherSuggestion property updated
    ↓ (via @Published)
WeatherHybridCard displays suggestion
```

**Critical Connection Points:**
1. Line 1893-1898: `loadWeatherForBuilding()` must call `updateWeatherSuggestions()`
2. Line 2930-2948: `updateWeatherSuggestions()` must process current tasks
3. Line 60: `WeatherHybridCard(suggestion: viewModel.weatherSuggestion)` must be connected

### Routine Display Data Flow
```
OperationalDataManager (88 tasks, 7 workers, 16 buildings)
    ↓ (getRealWorldTasks)
WorkerDashboardViewModel.loadTodaysTasks()
    ↓ (convert to TaskItem format)
todaysTasks property updated
    ↓ (via @Published)
Hero Cards + Task Lists display

// Client portfolio (route-derived)
RouteOperationalBridge
    ↓ (convertSequencesToContextualTasks)
ClientDashboardViewModel.loadClientRoutePortfolioData()
    ↓ (filter to client buildings, add DSNY set‑out)
routePortfolioTodayTasks updated
    ↓ (via @Published)
ClientDashboardView lists Today’s Tasks
```

**Critical Connection Points:**
1. Line 1690-1750: `loadTodaysTasks()` must load for ANY workerId
2. Line 1094: `refreshData()` must call `loadTodaysTasks()`
3. UI components must reference `viewModel.todaysTasks`
4. Client UI must reference `viewModel.routePortfolioTodayTasks`

### Building Policies Data Flow  
```
BuildingOperationsCatalog (policy definitions)
    ↓ (building-specific rules)
PolicyChipsRow.policyChips(for: buildingId)
    ↓ (generate chips array)
Policy chips displayed under WeatherHybridCard
```

**Critical Connection Points:**
1. Line 772-799: `policyChips()` must check ALL building types
2. Line 104-108: PolicyChipsRow must be added to ALL dashboard views
3. Building ID must be passed correctly from viewModel

## 🎯 Verification Checklist

### For EVERY Implementation:

#### 1. Data Loading Verification
- [ ] OperationalDataManager contains required data
- [ ] Worker assignments exist for target worker IDs
- [ ] Building data exists for target building IDs
- [ ] Database queries use correct column names
- [ ] SQL queries handle missing data gracefully

#### 2. Processing Layer Verification
- [ ] ViewModel methods are called when data loads
- [ ] Processing logic works for ANY worker (not hardcoded)
- [ ] Error handling prevents crashes on missing data
- [ ] @Published properties are updated correctly
- [ ] Async/await context is correct (MainActor for UI)

#### 3. UI Connection Verification
- [ ] ViewModel properties are bound to UI components
- [ ] UI components exist in ALL applicable dashboard views
- [ ] @Published changes trigger UI re-renders
- [ ] Navigation and sheets work correctly
- [ ] Error states are handled gracefully

#### 4. Universal Functionality Verification
- [ ] Works for Kevin (Worker ID: 4)
- [ ] Works for Edwin (Worker ID: 2) 
- [ ] Works for Mercedes (Worker ID: 5)
- [ ] Works for Greg (Worker ID: 1)
- [ ] Works at ALL assigned buildings per worker
- [ ] Handles edge cases (no current building, offline, etc.)

## 🚨 Failure Investigation Protocol

### When a Feature Doesn't Display:

#### Step 1: Trace Data Path
```swift
// Add debug prints at each stage
print("🔍 1. Data loading for worker \(workerId)")
print("🔍 2. Processing triggered: \(processingMethod)")  
print("🔍 3. ViewModel updated: \(viewModelProperty)")
print("🔍 4. UI should display: \(uiComponent)")
```

#### Step 2: Check Database Integrity
```bash
# Verify worker exists
SELECT * FROM workers WHERE id = 'WORKER_ID';

# Verify building assignments 
SELECT * FROM worker_building_assignments WHERE worker_id = 'WORKER_ID';

# Verify routine data
SELECT * FROM routine_schedules WHERE worker_id = 'WORKER_ID';
```

#### Step 3: Verify SQL Queries
- Check all SQL queries for correct column names
- Verify JOIN conditions match actual schema
- Test queries in isolation to confirm they return data

#### Step 4: Check Update Triggers
```swift
// Verify @Published properties update UI
@Published var weatherSuggestion: String? = nil  // ← Must be updated

// Verify update methods are called
func refreshData() {
    await loadTodaysTasks()        // ← Must be called
    await loadWeatherForBuilding() // ← Must call updateWeatherSuggestions
}
```

#### Step 5: Test All Entry Points
- WorkerDashboardView (main implementation)
- WorkerDashboardMainView (simplified)
- SimplifiedDashboard (basic)
- Verify feature appears in ALL applicable views

## 📊 Success Patterns from CyntientOps

### Pattern 1: Universal Weather Suggestions
```swift
// ✅ Works for ANY worker at ANY building
private func updateWeatherSuggestions(with weather: WeatherSnapshot) {
    let contextualTasks = todaysTasks.map { /* convert to ContextualTask */ }
    updateUpcomingTasksFromContextualTasks(contextualTasks, weather: weather)
}
```

### Pattern 2: Building-Specific Policies
```swift
// ✅ Policies apply based on building, not worker
private func policyChips(for buildingId: String) -> [Chip] {
    var chips: [Chip] = []
    if rainMatBuildings.contains(buildingId) {
        chips.append(Chip(label: "Mats", symbol: "water.waves", color: .blue))
    }
    return chips
}
```

### Pattern 3: Robust Data Loading
```swift  
// ✅ Always ensure data is available
if let building = currentBuilding {
    await loadWeatherForBuilding(building)
} else if let firstBuilding = assignedBuildings.first {
    await loadWeatherForBuilding(firstBuilding) // Fallback for ALL workers
}
```

## 🔧 Debug Commands

### Build Verification
```bash
# Check specific file compilation
"/Volumes/FastSSD/6D68F897-B18B-46B1-B370-D3A3F300A9FA/Xcode-beta.app/Contents/Developer/usr/bin/swiftc" \
  -parse /path/to/file.swift -I . -I CyntientOps

# Full build
"/Volumes/FastSSD/6D68F897-B18B-46B1-B370-D3A3F300A9FA/Xcode-beta.app/Contents/Developer/usr/bin/xcodebuild" \
  build -scheme CyntientOps -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Database Verification
```sql
-- Check worker data
SELECT id, name FROM workers;

-- Check routine assignments  
SELECT worker_id, building_id, name, estimated_duration 
FROM routine_schedules WHERE worker_id = '4';

-- Check task data
SELECT id, title, assignee_id, building_id 
FROM tasks WHERE assignee_id = '4';
```

### Runtime Verification
```swift
// Add to ViewModels for debugging
print("🔍 Weather: \(weather?.current.condition ?? "nil")")
print("🔍 Suggestion: \(weatherSuggestion ?? "nil")")
print("🔍 Tasks: \(todaysTasks.count)")
print("🔍 Buildings: \(assignedBuildings.map { $0.name })")
```

---

**Remember**: Features that work in isolation but don't display are usually missing **connection triggers**. Always trace the complete data flow path and ensure every step properly triggers the next.
