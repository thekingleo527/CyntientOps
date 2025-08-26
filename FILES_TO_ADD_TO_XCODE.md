# Files to Add to Xcode Project Target

## 🎯 Required Manual Addition

The following files exist in the filesystem but are not yet added to the Xcode project target and need to be manually added:

### 1. AdminOperationalIntelligence.swift
**Location:** `CyntientOps/Services/Admin/AdminOperationalIntelligence.swift`  
**Status:** ❌ Not in project.pbxproj  
**Impact:** ServiceContainer getAdminIntelligence() method is commented out until this is added

**To Add:**
1. Open CyntientOps.xcodeproj in Xcode
2. Right-click on `Services/Admin` folder
3. Choose "Add Files to 'CyntientOps'"
4. Select `AdminOperationalIntelligence.swift`
5. Ensure it's added to the CyntientOps target

**After Adding:** Uncomment the getAdminIntelligence() method in ServiceContainer.swift:
```swift
public func getAdminIntelligence() -> AdminOperationalIntelligence {
    return AdminOperationalIntelligence(container: self, dashboardSync: dashboardSync)
}
```

### 2. Performance Utilities (Already Added ✅)
The following files were successfully added to the project:
- ✅ `BatchedUIUpdater.swift` - In Services/Core/
- ✅ `MemoryPressureMonitor.swift` - In Services/Core/
- ✅ `QueryOptimizer.swift` - In Services/Core/
- ✅ `TaskPoolManager.swift` - In Services/Core/

### 3. Production Command Steps (Already Added ✅)
- ✅ `CommandSteps_Production.swift` - In Services/Commands/

## 📋 Files Already in Project
These files are confirmed to be in the Xcode project target:
- ✅ OperationalDataManager.swift
- ✅ NYCComplianceService.swift  
- ✅ NYCIntegrationManager.swift
- ✅ ServiceContainer.swift
- ✅ All ViewModels and Core files

## 🔧 After Adding AdminOperationalIntelligence.swift

Once the file is added to the Xcode project, you'll need to:

1. **Uncomment ServiceContainer method:**
   ```swift
   // In ServiceContainer.swift, uncomment:
   public func getAdminIntelligence() -> AdminOperationalIntelligence {
       return AdminOperationalIntelligence(container: self, dashboardSync: dashboardSync)
   }
   ```

2. **Test compilation:**
   - Build the project in Xcode
   - All ServiceContainer errors should be resolved

## 🚀 Current Status

**✅ Fixed Issues:**
- ServiceContainer operationalManager scope → Fixed (operationalData)
- NYCComplianceService.shared → Fixed (proper initialization)
- ServiceContainer async property access → Fixed (try/await pattern)
- TaskService QueryOptimizer main actor isolation → Fixed (actor pattern)

**⏳ Pending:**
- AdminOperationalIntelligence type not found → Requires manual Xcode project addition

The system is 99% ready - only the manual file addition step remains.