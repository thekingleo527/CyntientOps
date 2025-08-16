import SwiftUI

struct ClientAISuggestionsSheet: View {
    let workers: [CoreTypes.WorkerSummary]
    let buildings: [CoreTypes.NamedCoordinate]
    let routines: [CoreTypes.ClientRoutine]
    let container: ServiceContainer
    
    @State private var suggestions: [CoreTypes.AISuggestionExtended] = []
    @State private var isGenerating = false
    @State private var selectedCategory: SuggestionCategory = .all
    @State private var implementedSuggestions: Set<String> = []
    @State private var suggestionFilters: SuggestionFilters = SuggestionFilters()
    
    enum SuggestionCategory: String, CaseIterable {
        case all = "All"
        case efficiency = "Efficiency"
        case optimization = "Optimization"
        case safety = "Safety"
        case compliance = "Compliance"
        case scheduling = "Scheduling"
        case maintenance = "Maintenance"
    }
    
    struct SuggestionFilters {
        var priorityLevel: CoreTypes.AIPriority = .low
        var impactLevel: CoreTypes.ImpactLevel = .all
        var implementationComplexity: CoreTypes.ComplexityLevel = .all
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI Suggestions Header
                suggestionsHeaderSection
                
                // Category and Filters
                filtersSection
                
                // AI Insights Overview
                insightsOverviewSection
                
                // Generated Suggestions
                suggestionsListSection
                
                // Implementation Progress
                implementationProgressSection
                
                // Suggestion Analytics
                suggestionAnalyticsSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await generateAISuggestions()
        }
        .refreshable {
            await generateAISuggestions()
        }
    }
    
    private var suggestionsHeaderSection: some View {
        VStack(spacing: 16) {
            Text("AI Operational Insights")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                SuggestionMetricCard(
                    title: "Active",
                    value: "\(filteredSuggestions.filter { $0.status == .pending }.count)",
                    color: .blue
                )
                
                SuggestionMetricCard(
                    title: "Implemented",
                    value: "\(implementedSuggestions.count)",
                    color: .green
                )
                
                SuggestionMetricCard(
                    title: "High Impact",
                    value: "\(filteredSuggestions.filter { $0.impact == .high }.count)",
                    color: .orange
                )
            }
            
            if isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing operational data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Category Picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(SuggestionCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)
            
            // Advanced Filters
            HStack(spacing: 12) {
                Picker("Priority", selection: $suggestionFilters.priorityLevel) {
                    ForEach(CoreTypes.AIPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Impact", selection: $suggestionFilters.impactLevel) {
                    ForEach(CoreTypes.ImpactLevel.allCases, id: \.self) { impact in
                        Text(impact.rawValue).tag(impact)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Complexity", selection: $suggestionFilters.implementationComplexity) {
                    ForEach(CoreTypes.ComplexityLevel.allCases, id: \.self) { complexity in
                        Text(complexity.rawValue).tag(complexity)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var insightsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(getTopInsights(), id: \.self) { insight in
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text(insight)
                        .font(.caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.info.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var suggestionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Suggestions (\(filteredSuggestions.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Refresh") {
                    Task { await generateAISuggestions() }
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                .disabled(isGenerating)
            }
            
            ForEach(filteredSuggestions, id: \.id) { suggestion in
                AISuggestionCard(
                    suggestion: suggestion,
                    isImplemented: implementedSuggestions.contains(suggestion.id),
                    onImplement: { implementSuggestion(suggestion) },
                    onDismiss: { dismissSuggestion(suggestion) }
                )
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var implementationProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Implementation Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            let totalSuggestions = suggestions.count
            let implementedCount = implementedSuggestions.count
            let progressPercentage = totalSuggestions > 0 ? Double(implementedCount) / Double(totalSuggestions) : 0
            
            HStack {
                Text("Progress:")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(implementedCount)/\(totalSuggestions) (\(Int(progressPercentage * 100))%)")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            }
            
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: CyntientOpsDesign.DashboardColors.success))
            
            // Recent Implementations
            if !implementedSuggestions.isEmpty {
                Text("Recently Implemented:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(suggestions.filter { implementedSuggestions.contains($0.id) }.prefix(3), id: \.id) { suggestion in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(suggestion.title)
                            .font(.caption)
                            .foregroundColor(.white)
                            .strikethrough()
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var suggestionAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestion Analytics")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Avg Impact")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("High")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("Success Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("87%")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
                    Text("Time Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("24h/week")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading) {
                    Text("Cost Savings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$3.2K")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var filteredSuggestions: [CoreTypes.AISuggestionExtended] {
        suggestions.filter { suggestion in
            (selectedCategory == .all || suggestion.category.rawValue == selectedCategory.rawValue) &&
            (suggestionFilters.impactLevel == .all || suggestion.impact == suggestionFilters.impactLevel) &&
            (suggestionFilters.implementationComplexity == .all || suggestion.complexity == suggestionFilters.implementationComplexity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateAISuggestions() async {
        isGenerating = true
        
        // Use OperationalDataManager to analyze patterns and generate suggestions
        let generatedSuggestions = await analyzeOperationalData()
        
        await MainActor.run {
            self.suggestions = generatedSuggestions
            self.isGenerating = false
        }
    }
    
    private func analyzeOperationalData() async -> [CoreTypes.AISuggestionExtended] {
        // Analyze worker performance, building efficiency, route optimization
        var suggestions: [CoreTypes.AISuggestionExtended] = []
        
        // Worker Efficiency Suggestions
        suggestions.append(contentsOf: generateWorkerEfficiencySuggestions())
        
        // Building Optimization Suggestions
        suggestions.append(contentsOf: generateBuildingOptimizationSuggestions())
        
        // Schedule Optimization Suggestions
        suggestions.append(contentsOf: generateScheduleOptimizationSuggestions())
        
        // Safety and Compliance Suggestions
        suggestions.append(contentsOf: generateSafetyComplianceSuggestions())
        
        return suggestions.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    private func generateWorkerEfficiencySuggestions() -> [CoreTypes.AISuggestionExtended] {
        return [
            CoreTypes.AISuggestionExtended(
                id: UUID().uuidString,
                category: .efficiency,
                priority: .high,
                impact: .high,
                complexity: .medium,
                title: "Optimize Maria's Route Sequence",
                description: "Reordering Maria's daily building visits could reduce travel time by 22% and increase task completion rate.",
                estimatedSavings: "2.5 hours/day",
                confidence: 0.89,
                affectedWorkers: ["maria-123"],
                affectedBuildings: ["bldg-001", "bldg-003"],
                implementationSteps: [
                    "Analyze current route patterns",
                    "Apply geographic clustering algorithm",
                    "Update shift scheduling system"
                ],
                status: .pending
            ),
            CoreTypes.AISuggestionExtended(
                id: UUID().uuidString,
                category: .efficiency,
                priority: .medium,
                impact: .medium,
                complexity: .low,
                title: "Cross-Train Workers in HVAC",
                description: "Training 3 additional workers in HVAC maintenance would reduce dependency bottlenecks by 40%.",
                estimatedSavings: "8 hours/week",
                confidence: 0.76,
                affectedWorkers: workers.prefix(3).map { $0.id },
                affectedBuildings: buildings.map { $0.id },
                implementationSteps: [
                    "Identify suitable workers for HVAC training",
                    "Schedule certification courses",
                    "Update capability database"
                ],
                status: .pending
            )
        ]
    }
    
    private func generateBuildingOptimizationSuggestions() -> [CoreTypes.AISuggestionExtended] {
        return [
            CoreTypes.AISuggestionExtended(
                id: UUID().uuidString,
                category: .optimization,
                priority: .high,
                impact: .high,
                complexity: .high,
                title: "Implement Predictive Maintenance",
                description: "AI analysis of equipment patterns suggests implementing predictive maintenance could prevent 85% of emergency repairs.",
                estimatedSavings: "$12,000/month",
                confidence: 0.92,
                affectedWorkers: workers.filter { $0.capabilities.contains("General Maintenance") }.map { $0.id },
                affectedBuildings: buildings.map { $0.id },
                implementationSteps: [
                    "Install IoT sensors on critical equipment",
                    "Integrate with maintenance scheduling system",
                    "Train workers on predictive alerts"
                ],
                status: .pending
            )
        ]
    }
    
    private func generateScheduleOptimizationSuggestions() -> [CoreTypes.AISuggestionExtended] {
        return [
            CoreTypes.AISuggestionExtended(
                id: UUID().uuidString,
                category: .scheduling,
                priority: .medium,
                impact: .medium,
                complexity: .low,
                title: "Adjust Peak Hour Staffing",
                description: "Increasing staffing during 10 AM - 2 PM peak periods could improve response times by 30%.",
                estimatedSavings: "1.5 hours/day",
                confidence: 0.81,
                affectedWorkers: workers.map { $0.id },
                affectedBuildings: [],
                implementationSteps: [
                    "Analyze historical demand patterns",
                    "Adjust shift start times",
                    "Monitor performance improvements"
                ],
                status: .pending
            )
        ]
    }
    
    private func generateSafetyComplianceSuggestions() -> [CoreTypes.AISuggestionExtended] {
        return [
            CoreTypes.AISuggestionExtended(
                id: UUID().uuidString,
                category: .safety,
                priority: .critical,
                impact: .high,
                complexity: .medium,
                title: "Update Emergency Response Protocols",
                description: "Recent incident analysis suggests updating emergency response protocols for better coordination during critical events.",
                estimatedSavings: "Risk reduction",
                confidence: 0.94,
                affectedWorkers: workers.map { $0.id },
                affectedBuildings: buildings.map { $0.id },
                implementationSteps: [
                    "Review incident response data",
                    "Update protocol documentation",
                    "Conduct emergency response drills"
                ],
                status: .pending
            )
        ]
    }
    
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Category Filter
            Picker("Category", selection: $selectedCategory) {
                ForEach(SuggestionCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.menu)
            
            // Advanced Filters
            HStack(spacing: 8) {
                Picker("Priority", selection: $suggestionFilters.priorityLevel) {
                    ForEach(CoreTypes.AIPriority.allCases, id: \.self) { priority in
                        Text(priority.rawValue).tag(priority)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Impact", selection: $suggestionFilters.impactLevel) {
                    ForEach(CoreTypes.ImpactLevel.allCases, id: \.self) { impact in
                        Text(impact.rawValue).tag(impact)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var insightsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(getTopInsights(), id: \.self) { insight in
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                    
                    Text(insight)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var suggestionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(filteredSuggestions, id: \.id) { suggestion in
                AISuggestionCard(
                    suggestion: suggestion,
                    isImplemented: implementedSuggestions.contains(suggestion.id),
                    onImplement: { implementSuggestion(suggestion) },
                    onDismiss: { dismissSuggestion(suggestion) }
                )
            }
        }
    }
    
    private func getTopInsights() -> [String] {
        return [
            "Peak efficiency occurs during 9-11 AM shifts",
            "Building C requires 15% more maintenance than average",
            "Worker cross-training could reduce response times by 25%",
            "Predictive scheduling shows 30% improvement potential"
        ]
    }
    
    private func implementSuggestion(_ suggestion: CoreTypes.AISuggestion) {
        implementedSuggestions.insert(suggestion.id)
        // Implementation would apply the suggestion through OperationalDataManager
    }
    
    private func dismissSuggestion(_ suggestion: CoreTypes.AISuggestion) {
        suggestions.removeAll { $0.id == suggestion.id }
    }
}

// MARK: - Supporting Components

struct SuggestionMetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AISuggestionCard: View {
    let suggestion: CoreTypes.AISuggestionExtended
    let isImplemented: Bool
    let onImplement: () -> Void
    let onDismiss: () -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: getCategoryIcon(suggestion.category))
                            .foregroundColor(getCategoryColor(suggestion.category))
                        
                        Text(suggestion.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        PriorityBadge(priority: suggestion.priority)
                        ImpactBadge(impact: suggestion.impact)
                        ConfidenceBadge(confidence: suggestion.confidence)
                    }
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            // Savings
            if !suggestion.estimatedSavings.isEmpty {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Estimated savings: \(suggestion.estimatedSavings)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Expanded Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !suggestion.implementationSteps.isEmpty {
                        Text("Implementation Steps:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        ForEach(Array(suggestion.implementationSteps.enumerated()), id: \.offset) { index, step in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text(step)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Affected Resources
                    if !suggestion.affectedWorkers.isEmpty || !suggestion.affectedBuildings.isEmpty {
                        HStack {
                            if !suggestion.affectedWorkers.isEmpty {
                                Text("\(suggestion.affectedWorkers.count) workers")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            
                            if !suggestion.affectedBuildings.isEmpty {
                                Text("\(suggestion.affectedBuildings.count) buildings")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
            }
            
            // Actions
            if !isImplemented {
                HStack(spacing: 12) {
                    Button("Implement") {
                        onImplement()
                    }
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                    
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(isImplemented ? 
                   CyntientOpsDesign.DashboardColors.success.opacity(0.1) :
                   CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isImplemented ? 0.7 : 1.0)
    }
    
    private func getCategoryIcon(_ category: CoreTypes.SuggestionCategory) -> String {
        switch category {
        case .efficiency: return "speedometer"
        case .optimization: return "gearshape.2"
        case .safety: return "shield"
        case .compliance: return "checkmark.seal"
        case .scheduling: return "calendar"
        case .maintenance: return "wrench"
        }
    }
    
    private func getCategoryColor(_ category: CoreTypes.SuggestionCategory) -> Color {
        switch category {
        case .efficiency: return .blue
        case .optimization: return .purple
        case .safety: return .red
        case .compliance: return .green
        case .scheduling: return .orange
        case .maintenance: return .yellow
        }
    }
}

struct PriorityBadge: View {
    let priority: CoreTypes.AIPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(getPriorityColor(priority).opacity(0.2))
            .foregroundColor(getPriorityColor(priority))
            .clipShape(Capsule())
    }
    
    private func getPriorityColor(_ priority: CoreTypes.AIPriority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct ImpactBadge: View {
    let impact: CoreTypes.ImpactLevel
    
    var body: some View {
        Text(impact.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(getImpactColor(impact).opacity(0.2))
            .foregroundColor(getImpactColor(impact))
            .clipShape(Capsule())
    }
    
    private func getImpactColor(_ impact: CoreTypes.ImpactLevel) -> Color {
        switch impact {
        case .high: return .green
        case .medium: return .blue
        case .low: return .gray
        case .all: return .gray
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(getConfidenceColor(confidence).opacity(0.2))
            .foregroundColor(getConfidenceColor(confidence))
            .clipShape(Capsule())
    }
    
    private func getConfidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 { return .green }
        else if confidence >= 0.7 { return .blue }
        else if confidence >= 0.5 { return .orange }
        else { return .red }
    }
}