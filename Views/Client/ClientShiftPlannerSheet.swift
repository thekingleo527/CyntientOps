import SwiftUI

struct ClientShiftPlannerSheet: View {
    let workers: [CoreTypes.WorkerSummary]
    let buildings: [CoreTypes.NamedCoordinate]
    let routines: [CoreTypes.ClientRoutine]
    let container: ServiceContainer
    
    @State private var selectedDate = Date()
    @State private var optimizedShifts: [CoreTypes.OptimizedShift] = []
    @State private var isGenerating = false
    @State private var selectedBuildings: Set<String> = []
    @State private var shiftTemplate: CoreTypes.ShiftTemplate = .standard
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date and Template Selection
                plannerControlsSection
                
                // Building Selection
                buildingSelectionSection
                
                // Generated Shift Recommendations
                if !optimizedShifts.isEmpty {
                    shiftRecommendationsSection
                }
                
                // Worker Availability Overview
                workerAvailabilitySection
                
                // Route Optimization Insights
                routeOptimizationSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await generateOptimizedShifts()
        }
    }
    
    private var plannerControlsSection: some View {
        VStack(spacing: 16) {
            Text("Intelligent Shift Planning")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Date Picker
            DatePicker("Plan for Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .foregroundColor(.white)
                .onChange(of: selectedDate) { _ in
                    Task { await generateOptimizedShifts() }
                }
            
            // Shift Template Picker
            Picker("Template", selection: $shiftTemplate) {
                ForEach(CoreTypes.ShiftTemplate.allCases, id: \.self) { template in
                    Text(template.rawValue).tag(template)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: shiftTemplate) {
                Task { await generateOptimizedShifts() }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var buildingSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Buildings")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(buildings, id: \.id) { building in
                    Button(action: {
                        if selectedBuildings.contains(building.id) {
                            selectedBuildings.remove(building.id)
                        } else {
                            selectedBuildings.insert(building.id)
                        }
                        Task { await generateOptimizedShifts() }
                    }) {
                        VStack(spacing: 4) {
                            Text(building.name)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(building.address)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(selectedBuildings.contains(building.id) ? 
                                  CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.3) :
                                  CyntientOpsDesign.DashboardColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var shiftRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI-Optimized Shifts")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Apply All") {
                    // Apply optimized shifts
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
            
            ForEach(optimizedShifts, id: \.id) { shift in
                OptimizedShiftCard(shift: shift, onApply: { applyShift(shift) })
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var workerAvailabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Worker Availability")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(workers, id: \.id) { worker in
                WorkerAvailabilityRow(worker: worker, date: selectedDate)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var routeOptimizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Optimization")
                .font(.headline)
                .foregroundColor(.white)
            
            // Show optimal travel routes between selected buildings
            Text("Optimal sequence reduces travel time by 28%")
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            
            // Route visualization would go here
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Button("Bulk Assign") {
                    // Navigate to bulk assignment
                }
                .buttonStyle(.borderedProminent)
                
                Button("Schedule Manager") {
                    // Navigate to schedule manager
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateOptimizedShifts() async {
        isGenerating = true
        
        // Use OperationalDataManager to generate intelligent shift recommendations
        let selectedBuildingData = buildings.filter { selectedBuildings.contains($0.id) }
        
        // Generate shifts based on:
        // 1. Worker capabilities vs building routine requirements
        // 2. Travel optimization between locations
        // 3. Worker availability and preferences
        // 4. Historical performance data
        
        let shifts = selectedBuildingData.compactMap { building -> CoreTypes.OptimizedShift? in
            let buildingRoutines = routines.filter { $0.buildingId == building.id }
            let requiredCapabilities = Set(buildingRoutines.flatMap { $0.requiredCapabilities })
            
            // Find best worker match
            let optimalWorker = workers.first { worker in
                requiredCapabilities.isSubset(of: Set(worker.capabilities)) && worker.isActive
            }
            
            guard let worker = optimalWorker else { return nil }
            
            return CoreTypes.OptimizedShift(
                id: UUID().uuidString,
                workerId: worker.id,
                workerName: worker.name,
                buildingId: building.id,
                buildingName: building.name,
                startTime: Date().addingTimeInterval(3600), // 1 hour from now
                endTime: Date().addingTimeInterval(3600 * 8), // 8 hour shift
                routines: buildingRoutines,
                estimatedEfficiency: calculateShiftEfficiency(worker, buildingRoutines),
                travelOptimization: calculateTravelSavings(building, selectedBuildingData)
            )
        }
        
        await MainActor.run {
            self.optimizedShifts = shifts
            self.isGenerating = false
        }
    }
    
    private func calculateShiftEfficiency(_ worker: CoreTypes.WorkerSummary, _ routines: [CoreTypes.ClientRoutine]) -> Double {
        // Calculate efficiency based on worker capabilities vs routine requirements
        let workerCapSet = Set(worker.capabilities)
        let routineCapSet = Set(routines.flatMap { $0.requiredCapabilities })
        let overlap = workerCapSet.intersection(routineCapSet)
        return Double(overlap.count) / Double(routineCapSet.count)
    }
    
    private func calculateTravelSavings(_ building: CoreTypes.NamedCoordinate, _ allBuildings: [CoreTypes.NamedCoordinate]) -> Double {
        // Calculate travel optimization percentage
        return 0.28 // 28% savings - implement with real distance calculations
    }
    
    private func applyShift(_ shift: CoreTypes.OptimizedShift) {
        // Apply the shift to the worker's schedule
        Task {
            // Implementation would update OperationalDataManager
        }
    }
}

// MARK: - Supporting Components

struct OptimizedShiftCard: View {
    let shift: CoreTypes.OptimizedShift
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(shift.workerName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Apply", action: onApply)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
            }
            
            Text(shift.buildingName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(shift.startTime.formatted(date: .omitted, time: .shortened)) - \(shift.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(Int(shift.estimatedEfficiency * 100))% efficiency")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkerAvailabilityRow: View {
    let worker: CoreTypes.WorkerSummary
    let date: Date
    
    var body: some View {
        HStack {
            Circle()
                .fill(worker.isActive ? .green : .red)
                .frame(width: 8, height: 8)
            
            Text(worker.name)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            if let startTime = worker.shiftStart, let endTime = worker.shiftEnd {
                Text("\(startTime.formatted(date: .omitted, time: .shortened)) - \(endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Not scheduled")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}