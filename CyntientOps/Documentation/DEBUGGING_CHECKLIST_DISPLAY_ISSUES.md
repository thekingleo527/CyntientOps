# Debugging Checklist for Display Issues

## 🚨 When Features Don't Display - Systematic Diagnosis

### Quick Diagnostic Questions
1. **Does the feature compile without errors?** → Build test
2. **Does data exist in the database?** → Database query test  
3. **Is the ViewModel property populated?** → Debug print test
4. **Is the UI component connected to the ViewModel?** → Binding verification
5. **Does the feature appear in ALL applicable dashboards?** → Multi-view test

## 🔍 Step-by-Step Debugging Protocol

### Step 1: Compilation Verification
```bash
# Test specific file compilation
swiftc -parse /path/to/modified/file.swift -I . -I CyntientOps

# Test full project build
xcodebuild build -scheme CyntientOps -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

**Red Flags:**
- ❌ `error: cannot find 'ClassName' in scope`
- ❌ `error: no member named 'propertyName'`
- ❌ `error: missing argument`

**Resolution**: Fix compilation errors FIRST before debugging display issues.

### Step 2: Data Source Verification
```sql
-- Verify worker exists
SELECT id, name FROM workers WHERE id = 'WORKER_ID';

-- Verify building assignments
SELECT * FROM worker_building_assignments WHERE worker_id = 'WORKER_ID';

-- Verify routine data
SELECT name, estimated_duration, building_id 
FROM routine_schedules 
WHERE worker_id = 'WORKER_ID' AND building_id = 'BUILDING_ID';

-- Verify task data  
SELECT title, assignee_id, building_id, completedAt
FROM tasks 
WHERE assignee_id = 'WORKER_ID';
```

**Red Flags:**
- ❌ Empty result sets for expected workers
- ❌ SQL errors about missing columns
- ❌ Mismatched building/worker IDs

### Step 3: ViewModel Data Flow Check
Add debug prints to track data flow:

```swift
// Add to ViewModel loading methods
func loadTodaysTasks() async {
    print("🔍 1. Loading tasks for worker: \(workerId)")
    
    let tasks = await loadTasksFromSource()
    print("🔍 2. Loaded \(tasks.count) tasks")
    
    await MainActor.run {
        self.todaysTasks = tasks
        print("🔍 3. Updated todaysTasks property: \(self.todaysTasks.count)")
    }
    
    // ✅ CRITICAL: Trigger dependent processing
    if let weather = self.weather {
        updateWeatherSuggestions(with: weather)
        print("🔍 4. Weather suggestions updated")
    }
}
```

**Red Flags:**
- ❌ "Loading tasks" but count is 0
- ❌ "Updated property" but UI doesn't refresh
- ❌ "Weather suggestions" never prints

### Step 4: UI Connection Verification
```swift
// Verify ViewModel properties are bound to UI
struct WeatherHybridCard: View {
    var body: some View {
        // ✅ DEBUG: Verify data reaches UI
        let _ = print("🔍 UI: weather=\(snapshot != nil), suggestion=\(suggestion != nil)")
        
        if let suggestionText = suggestion {
            Text(suggestionText) // ← Should display if connected properly
        }
    }
}
```

**Red Flags:**
- ❌ "UI: weather=true, suggestion=false" → Processing broken
- ❌ "UI: weather=false, suggestion=false" → Data loading broken
- ❌ No debug prints at all → Component not being rendered

### Step 5: Multi-Dashboard Integration Check
**Verify feature appears in ALL applicable views:**

```swift
// ✅ CHECK: Feature in WorkerDashboardView (main implementation)
// File: Views/Main/WorkerDashboardView.swift
WeatherHybridCard(suggestion: viewModel.weatherSuggestion)

// ✅ CHECK: Feature in WorkerDashboardMainView  
// File: Views/Main/WorkerDashboardMainView.swift
WeatherHybridCard(suggestion: viewModel.weatherSuggestion)

// ✅ CHECK: Feature in SimplifiedDashboard
// File: Views/Main/Simplified/SimplifiedDashboard.swift  
WeatherHybridCard(suggestion: viewModel.weatherSuggestion)
```

**Red Flags:**
- ❌ Feature only in one dashboard view
- ❌ Different ViewModel properties used in different views
- ❌ Inconsistent implementation across views

## 🛠️ Specific CyntientOps Debugging Commands

### Database Integrity Check
```bash
# Check operational data seeding
echo "SELECT COUNT(*) FROM routine_schedules;" | sqlite3 database.db

# Check worker assignments
echo "SELECT worker_id, COUNT(*) FROM routine_schedules GROUP BY worker_id;" | sqlite3 database.db

# Check building data
echo "SELECT id, name FROM buildings ORDER BY id;" | sqlite3 database.db
```

### ViewModel State Debugging
```swift
// Add to WorkerDashboardViewModel.refreshData()
print("🔍 WORKER: \(worker?.id ?? "nil")")
print("🔍 CURRENT BUILDING: \(currentBuilding?.id ?? "nil")")  
print("🔍 ASSIGNED BUILDINGS: \(assignedBuildings.count)")
print("🔍 TODAY'S TASKS: \(todaysTasks.count)")
print("🔍 WEATHER: \(weather?.current.condition ?? "nil")")
print("🔍 WEATHER SUGGESTION: \(weatherSuggestion ?? "nil")")
```

### UI Rendering Verification
```swift
// Add to UI components that aren't displaying
var body: some View {
    let _ = print("🔍 \(Self.self) rendering with data: \(hasData)")
    
    // Your UI implementation
}
```

## ⚡ Quick Fix Patterns

### Pattern 1: Missing Update Trigger
```swift
// ❌ SYMPTOM: Data loads but UI never updates
func loadData() {
    data = newData
}

// ✅ FIX: Add trigger for dependent processing  
func loadData() {
    data = newData
    triggerDependentProcessing(data) // ← ADD THIS
}
```

### Pattern 2: Single-Worker Logic
```swift
// ❌ SYMPTOM: Feature only works for Kevin
if workerId == "4" { 
    processWeatherSuggestions() 
}

// ✅ FIX: Make universal
if hasWeatherDependentTasks {
    processWeatherSuggestions() 
}
```

### Pattern 3: Missing UI Integration  
```swift
// ❌ SYMPTOM: Component exists but never added to views
struct PolicyChipsRow: View { /* perfect implementation */ }

// ✅ FIX: Add to ALL dashboard views
// In WorkerDashboardMainView:
PolicyChipsRow(buildingId: viewModel.currentBuilding?.id)
// In SimplifiedDashboard:  
PolicyChipsRow(buildingId: viewModel.currentBuilding?.id)
```

### Pattern 4: Wrong Async Context
```swift
// ❌ SYMPTOM: Property updates but UI doesn't refresh
func updateProperty() {
    self.uiProperty = newValue // Wrong context
}

// ✅ FIX: Use MainActor for UI updates
func updateProperty() async {
    await MainActor.run {
        self.uiProperty = newValue // Correct context
    }
}
```

## 🎯 Success Verification

### A feature is "properly connected" when:
- [ ] **Compiles without errors**
- [ ] **Data loading prints show correct values**
- [ ] **Processing prints show method execution**  
- [ ] **ViewModel properties contain expected data**
- [ ] **UI debug prints show component rendering**
- [ ] **Feature displays correctly in ALL dashboard views**
- [ ] **Works for ALL workers (Kevin, Edwin, Mercedes, Greg)**
- [ ] **Handles edge cases (missing data, offline, etc.)**

### Red Flags (Connection Broken):
- ❌ **Data loads but UI property remains nil**
- ❌ **UI property has data but component doesn't render**
- ❌ **Feature works for one worker but not others**
- ❌ **Feature in one dashboard but missing from others**
- ❌ **Console shows SQL errors or missing column warnings**

## 📊 Debugging Tools & Techniques

### Console Output Patterns
```
✅ GOOD: Sequential execution
🔍 1. Loading tasks for worker: 4
🔍 2. Loaded 12 tasks  
🔍 3. Updated todaysTasks property: 12
🔍 4. Weather suggestions updated

❌ BAD: Broken chain
🔍 1. Loading tasks for worker: 4
🔍 2. Loaded 12 tasks
(Missing: property update, suggestion update)
```

### Build Output Analysis
```
✅ GOOD: Clean build
** BUILD SUCCEEDED **

❌ BAD: Compilation errors
error: cannot find 'WeatherSuggestion' in scope
error: no member named 'weatherSuggestion'
```

### Runtime Behavior Testing
```swift
// Test each component in isolation
let weather = WeatherSnapshot(/* test data */)
let suggestion = WeatherScoreBuilder.score(task: testTask, weather: weather)
print("Suggestion: \(suggestion.advice)") // Should not be nil
```

## 📝 Documentation Requirements

### For Every Implementation:
1. **Document Data Flow**: Source → Processing → UI path
2. **List Connection Points**: Where integration happens
3. **Note Universal Requirements**: Must work for all workers
4. **Record Test Results**: Which workers/buildings were tested

### Connection Failure Documentation:
```markdown
## Issue: WeatherHybridCard not showing suggestions
**Root Cause**: Weather data loading never triggered suggestion generation
**Fix Applied**: Added `updateWeatherSuggestions()` call to `loadWeatherForBuilding()`
**Files Modified**: ViewModels/Dashboard/WorkerDashboardViewModel.swift:1897
**Test Results**: Verified working for Kevin, Edwin, Mercedes, Greg
```

---

**Remember: The goal is not just to implement features, but to ensure they integrate seamlessly into the existing data flow and display correctly for all users.**