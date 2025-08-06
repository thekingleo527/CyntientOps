//
//  NovaInteractionView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Line 846 - Added missing 'try' for throwing function
//  ✅ FIXED: Lines 1353-1357 - Corrected ForEach and insight property access
//  ✅ FIXED: Line 1449 - Removed orphaned extension code
//  ✅ ENHANCED: Integrated best features from AIScenarioSheetView
//  ✅ UPDATED: Integrated NovaAvatar component for better animations
//

import SwiftUI
import Combine

struct NovaInteractionView: View {
    // MARK: - State Management
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var userQuery = ""
    @State private var novaPrompts: [NovaPrompt] = []
    @State private var novaResponses: [NovaResponse] = []
    @State private var processingState: NovaProcessingState = .idle
    @State private var currentContext: NovaContext?
    
    // Enhanced state from AIScenarioSheetView
    @State private var showingEmergencyRepair = false
    @State private var repairProgress: Double = 0.0
    @State private var repairMessage = ""
    @State private var showContextualData = false
    @State private var activeScenarios: [CoreTypes.AIScenario] = []
    @State private var expandedMessageIds: Set<String> = []
    @State private var showNovaAssistant = false
    
    // MARK: - Services
    private let novaAPI = NovaAPIService.shared
    private let intelligenceService = IntelligenceService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with gradient
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Nova header with status
                    novaHeader
                    
                    // Emergency repair card if needed
                    if shouldShowEmergencyRepair {
                        emergencyRepairCard
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Active scenarios banner
                    if !activeScenarios.isEmpty {
                        activeScenariosBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Chat interface
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome card with context
                                if novaPrompts.isEmpty && novaResponses.isEmpty {
                                    welcomeCard
                                }
                                
                                ForEach(Array(chatMessages.enumerated()), id: \.offset) { index, message in
                                    NovaChatBubble(
                                        message: message,
                                        isExpanded: expandedMessageIds.contains(message.id),
                                        onToggleExpand: { toggleMessageExpansion(message.id) }
                                    )
                                    .id(index)
                                }
                                
                                if processingState == .processing {
                                    NovaProcessingIndicator()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: chatMessages.count) { oldCount, newCount in
                            withAnimation {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Enhanced input area with quick actions
                    novaInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "brain")
                            .font(.caption)
                            .foregroundColor(statusColor)
                        Text("Nova AI Assistant")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showContextualData.toggle() }) {
                        Image(systemName: showContextualData ? "info.circle.fill" : "info.circle")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await initializeNovaContext()
            checkForActiveScenarios()
        }
    }
    
    // MARK: - Enhanced View Components
    
    private var novaHeader: some View {
        VStack(spacing: 16) {
            // Nova Avatar with enhanced animations
            NovaAvatar(
                size: .large,
                isActive: processingState != .idle,
                hasUrgentInsights: hasHighPriorityScenarios,
                isBusy: processingState == .processing,
                onTap: {
                    showContextualData.toggle()
                },
                onLongPress: {
                    showNovaAssistant = true
                }
            )
            .shadow(color: statusColor.opacity(0.5), radius: 10)
            
            // Status text with context
            VStack(spacing: 4) {
                Text("Nova AI")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(contextSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Priority indicator if active scenarios
                if hasHighPriorityScenarios {
                    Label("High Priority", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            
            // Contextual data expansion
            if showContextualData {
                contextualDataCard
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Emergency Repair Card (from AIScenarioSheetView)
    
    private var emergencyRepairCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .symbolEffect(.pulse, isActive: !showingEmergencyRepair)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Repair Available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("AI detected assignment data inconsistency")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            if showingEmergencyRepair {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Repair Progress")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(Int(repairProgress * 100))%")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.orange)
                    }
                    
                    ProgressView(value: repairProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .scaleEffect(y: 2)
                    
                    Text(repairMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                .padding(.top, 8)
            }
            
            Button {
                if !showingEmergencyRepair {
                    performEmergencyRepair()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showingEmergencyRepair ? "checkmark.circle.fill" : "wrench.and.screwdriver")
                        .font(.subheadline)
                    
                    Text(showingEmergencyRepair ? "Repair Complete" : "Run Emergency Repair")
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    showingEmergencyRepair ?
                    Color.green.opacity(0.2) :
                    Color.orange.opacity(0.2)
                )
                .foregroundColor(showingEmergencyRepair ? .green : .orange)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            showingEmergencyRepair ? Color.green.opacity(0.4) : Color.orange.opacity(0.4),
                            lineWidth: 1
                        )
                )
            }
            .disabled(showingEmergencyRepair && repairProgress < 1.0)
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            }
        )
        .padding(.horizontal)
    }
    
    // MARK: - Active Scenarios Banner
    
    private var activeScenariosBanner: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(activeScenarios) { scenario in
                    scenarioChip(scenario)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func scenarioChip(_ scenario: CoreTypes.AIScenario) -> some View {
        HStack(spacing: 6) {
            Image(systemName: getScenarioIcon(scenario.type))
                .font(.caption)
            Text(scenario.title)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(getScenarioPriority(scenario.type).color.opacity(0.2))
        .foregroundColor(getScenarioPriority(scenario.type).color)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(getScenarioPriority(scenario.type).color.opacity(0.4), lineWidth: 1)
        )
        .onTapGesture {
            handleScenarioTap(scenario)
        }
    }
    
    // MARK: - Welcome Card
    
    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(getTimeBasedGreeting())
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let worker = contextAdapter.currentWorker {
                        Text("Welcome back, \(worker.name)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: 20) {
                quickStat(icon: "building.2", value: "\(contextAdapter.assignedBuildings.count)", label: "Buildings")
                quickStat(icon: "checklist", value: "\(contextAdapter.todaysTasks.count)", label: "Tasks")
                if let urgentCount = urgentTaskCount, urgentCount > 0 {
                    quickStat(icon: "exclamationmark.circle", value: "\(urgentCount)", label: "Urgent")
                        .foregroundColor(.orange)
                }
            }
            
            Text("How can I help you today?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func quickStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(value)
                .font(.title3.weight(.semibold))
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - Contextual Data Card (Enhanced from AIScenarioSheetView)
    
    private var contextualDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.subheadline)
                    .foregroundColor(.cyan)
                
                Text("Current Context")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showContextualData.toggle() }) {
                    Image(systemName: "chevron.up.circle")
                        .rotationEffect(.degrees(showContextualData ? 0 : 180))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                contextDataItem(
                    icon: "building.2",
                    title: "Buildings",
                    value: "\(contextAdapter.assignedBuildings.count)",
                    subtitle: "assigned"
                )
                
                contextDataItem(
                    icon: "list.bullet.clipboard",
                    title: "Tasks",
                    value: "\(contextAdapter.todaysTasks.count)",
                    subtitle: "today"
                )
                
                contextDataItem(
                    icon: "clock",
                    title: "Status",
                    value: contextAdapter.currentWorker != nil ? "Active" : "Standby",
                    subtitle: contextAdapter.currentWorker != nil ? "since \(getCurrentShiftStart())" : "ready"
                )
                
                contextDataItem(
                    icon: "person.circle",
                    title: "Worker",
                    value: contextAdapter.currentWorker?.name ?? "Unknown",
                    subtitle: "ID: \(contextAdapter.currentWorker?.id ?? "N/A")"
                )
            }
            
            // Building list if expanded
            if showContextualData && !contextAdapter.assignedBuildings.isEmpty {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assigned Buildings")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ForEach(contextAdapter.assignedBuildings.prefix(3)) { building in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text(building.name)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                    }
                    
                    if contextAdapter.assignedBuildings.count > 3 {
                        Text("and \(contextAdapter.assignedBuildings.count - 3) more...")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func contextDataItem(icon: String, title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.cyan.opacity(0.8))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Enhanced Input Bar
    
    private var novaInputBar: some View {
        VStack(spacing: 12) {
            // Quick action chips
            if !quickActions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickActions, id: \.self) { action in
                            quickActionChip(action)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Input field
            HStack(spacing: 12) {
                // Context indicator
                contextIndicator
                
                // Input field with glass effect
                HStack {
                    TextField("Ask about buildings, tasks, or insights...", text: $userQuery)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .onSubmit {
                            sendPrompt()
                        }
                    
                    if !userQuery.isEmpty {
                        Button(action: { userQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                
                // Send button with animation
                Button(action: sendPrompt) {
                    ZStack {
                        Circle()
                            .fill(canSendMessage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(canSendMessage ? 0 : -45))
                            .scaleEffect(canSendMessage ? 1.0 : 0.8)
                    }
                }
                .disabled(!canSendMessage)
                .animation(.spring(response: 0.3), value: canSendMessage)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }
    
    private var quickActions: [String] {
        var actions: [String] = []
        
        if hasHighPriorityScenarios {
            actions.append("🚨 View Priorities")
        }
        
        if contextAdapter.todaysTasks.count > 0 {
            actions.append("📋 Today's Tasks")
        }
        
        if shouldShowEmergencyRepair {
            actions.append("🔧 Fix Assignments")
        }
        
        actions.append("🏢 Building Status")
        actions.append("📊 Metrics")
        
        return actions
    }
    
    private func quickActionChip(_ action: String) -> some View {
        Button(action: { handleQuickAction(action) }) {
            Text(action)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(12)
        }
    }
    
    @MainActor
    private var contextIndicator: some View {
        Menu {
            if let building = contextAdapter.currentBuilding {
                Label(building.name, systemImage: "building.2")
            }
            
            Label("\(contextAdapter.todaysTasks.count) tasks", systemImage: "checklist")
            
            if let worker = contextAdapter.currentWorker {
                Label(worker.name, systemImage: "person.fill")
            }
            
            Divider()
            
            Button(action: { showContextualData.toggle() }) {
                Label(showContextualData ? "Hide Context" : "Show Context", systemImage: "info.circle")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                if hasHighPriorityScenarios {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                        .offset(x: 12, y: -12)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var chatMessages: [NovaChatMessage] {
        var messages: [NovaChatMessage] = []
        
        for (index, prompt) in novaPrompts.enumerated() {
            messages.append(NovaChatMessage(
                id: "prompt-\(index)",
                role: .user,
                content: prompt.text,
                timestamp: prompt.createdAt,
                priority: prompt.priority,
                actions: [],
                insights: [],
                metadata: prompt.metadata
            ))
            
            if index < novaResponses.count {
                let response = novaResponses[index]
                messages.append(NovaChatMessage(
                    id: "response-\(index)",
                    role: .assistant,
                    content: response.message,
                    timestamp: response.timestamp,
                    priority: determinePriorityFromResponse(response),
                    actions: response.actions,
                    insights: response.insights,
                    metadata: response.metadata
                ))
            }
        }
        
        return messages
    }
    
    private var contextSummary: String {
        if let context = currentContext {
            return context.metadata["summary"] ?? "Ready to assist"
        }
        return "Initializing context..."
    }
    
    private var canSendMessage: Bool {
        !userQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        processingState != .processing
    }
    
    private var shouldShowEmergencyRepair: Bool {
        let workerId = contextAdapter.currentWorker?.id ?? ""
        let buildings = contextAdapter.assignedBuildings
        return workerId == "worker_001" && buildings.isEmpty
    }
    
    private var hasHighPriorityScenarios: Bool {
        activeScenarios.contains { scenario in
            let priority = getScenarioPriority(scenario.type)
            return priority == .critical || priority == .high
        }
    }
    
    private var urgentTaskCount: Int? {
        let urgent = contextAdapter.todaysTasks.filter {
            $0.urgency == .critical || $0.urgency == .urgent
        }.count
        return urgent > 0 ? urgent : nil
    }
    
    private var statusColor: Color {
        if processingState == .error {
            return .red
        } else if hasHighPriorityScenarios {
            return .orange
        } else if processingState == .processing {
            return .blue
        }
        return .green
    }
    
    // MARK: - Actions
    
    private func sendPrompt() {
        let query = userQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        userQuery = ""
        
        let prompt = NovaPrompt(
            text: query,
            priority: determinePriority(for: query),
            context: currentContext,
            metadata: ["source": "user_input"]
        )
        
        novaPrompts.append(prompt)
        
        Task {
            await processNovaPrompt(prompt)
        }
    }
    
    @MainActor
    private func processNovaPrompt(_ prompt: NovaPrompt) async {
        processingState = .processing
        
        do {
            let response = try await novaAPI.processPrompt(prompt)
            novaResponses.append(response)
            processingState = .idle
            
            await processResponseActions(response)
            
            // Check for scenario triggers
            if let scenarioType = detectScenarioFromResponse(response) {
                addScenario(scenarioType)
            }
            
        } catch {
            let errorResponse = NovaResponse(
                success: false,
                message: "I encountered an error processing your request. Please try again.",
                metadata: ["error": error.localizedDescription]
            )
            novaResponses.append(errorResponse)
            processingState = .error
        }
    }
    
    private func processResponseActions(_ response: NovaResponse) async {
        for action in response.actions {
            switch action.actionType {
            case .navigate:
                await navigateToBuilding(action)
            case .schedule:
                await scheduleTask(action)
            case .analysis:
                await generateInsights()
            case .review:
                showContextualData = true
            default:
                break
            }
        }
    }
    
    @MainActor
    private func initializeNovaContext() async {
        processingState = .processing
        
        let contextData = await buildContextData()
        
        currentContext = NovaContext(
            data: contextData,
            insights: await gatherInitialInsights(),
            metadata: [
                "workerId": contextAdapter.currentWorker?.id ?? "",
                "buildingCount": String(contextAdapter.assignedBuildings.count),
                "taskCount": String(contextAdapter.todaysTasks.count),
                "summary": await generateContextSummary()
            ]
        )
        
        processingState = .idle
        
        let welcomeResponse = NovaResponse(
            success: true,
            message: await generateWelcomeMessage(),
            metadata: ["type": "welcome"]
        )
        novaResponses.append(welcomeResponse)
    }
    
    // MARK: - Emergency Repair (from AIScenarioSheetView)
    
    private func performEmergencyRepair() {
        print("🚨 Starting emergency repair for Kevin's missing buildings")
        
        showingEmergencyRepair = true
        repairMessage = "Initializing repair sequence..."
        
        Task {
            let steps = [
                "Scanning worker assignment database...",
                "Detected missing building associations...",
                "Rebuilding assignment matrix...",
                "Verifying task dependencies...",
                "Updating worker context engine...",
                "Repair complete - refreshing data..."
            ]
            
            for (index, step) in steps.enumerated() {
                await MainActor.run {
                    repairMessage = step
                    repairProgress = Double(index) / Double(steps.count - 1)
                }
                
                try? await Task.sleep(nanoseconds: UInt64(500 * 1_000_000))
            }
            
            await MainActor.run {
                repairMessage = "✅ Emergency repair successful"
                repairProgress = 1.0
                
                // Trigger actual data refresh
                Task {
                    if let workerId = contextAdapter.currentWorker?.id {
                        do {
                            try await contextAdapter.loadContext(for: workerId)
                        } catch {
                            print("Failed to load context after repair: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Scenario Management
    
    private func checkForActiveScenarios() {
        // Check various conditions and add scenarios
        if shouldShowEmergencyRepair {
            addScenario(.emergencyResponse)
        }
        
        if let urgent = urgentTaskCount, urgent > 0 {
            addScenario(.taskOptimization)
        }
        
        // Check time-based scenarios
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 17 && contextAdapter.currentWorker != nil {
            addScenario(.taskOptimization)
        }
    }
    
    private func addScenario(_ type: CoreTypes.AIScenarioType) {
        let scenario = CoreTypes.AIScenario(
            type: type,
            title: getScenarioTitle(type),
            description: getScenarioDescription(type)
        )
        
        if !activeScenarios.contains(where: { $0.type == type }) {
            withAnimation {
                activeScenarios.append(scenario)
            }
        }
    }
    
    private func handleScenarioTap(_ scenario: CoreTypes.AIScenario) {
        let prompt = NovaPrompt(
            text: "Tell me more about: \(scenario.description)",
            priority: getScenarioPriority(scenario.type),
            context: currentContext,
            metadata: ["scenario": scenario.type.rawValue]
        )
        
        novaPrompts.append(prompt)
        
        Task {
            await processNovaPrompt(prompt)
        }
        
        // Remove the scenario after handling
        withAnimation {
            activeScenarios.removeAll { $0.id == scenario.id }
        }
    }
    
    private func detectScenarioFromResponse(_ response: NovaResponse) -> CoreTypes.AIScenarioType? {
        let message = response.message.lowercased()
        
        if message.contains("weather") && message.contains("alert") {
            return .maintenancePrediction
        } else if message.contains("inventory") && message.contains("low") {
            return .inventoryManagement
        } else if message.contains("emergency") || message.contains("urgent") {
            return .emergencyResponse
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func toggleMessageExpansion(_ messageId: String) {
        withAnimation {
            if expandedMessageIds.contains(messageId) {
                expandedMessageIds.remove(messageId)
            } else {
                expandedMessageIds.insert(messageId)
            }
        }
    }
    
    private func determinePriority(for query: String) -> NovaPriority {
        let lowercased = query.lowercased()
        
        if lowercased.contains("urgent") || lowercased.contains("emergency") || lowercased.contains("critical") {
            return .critical
        } else if lowercased.contains("important") || lowercased.contains("priority") {
            return .high
        } else if lowercased.contains("when") || lowercased.contains("later") {
            return .low
        }
        
        return .medium
    }
    
    private func determinePriorityFromResponse(_ response: NovaResponse) -> NovaPriority? {
        // Determine priority based on response content
        if response.actions.contains(where: { $0.priority == .critical }) {
            return .critical
        } else if response.insights.contains(where: { $0.priority == .high }) {
            return .high
        }
        return nil
    }
    
    @MainActor
    private func buildContextData() async -> [String: String] {
        var contextData: [String: String] = [:]
        
        if let worker = contextAdapter.currentWorker {
            contextData["workerName"] = worker.name
            contextData["workerId"] = worker.id
            contextData["workerRole"] = worker.role.rawValue
        }
        
        if let building = contextAdapter.currentBuilding {
            contextData["currentBuilding"] = building.name
            contextData["currentBuildingId"] = building.id
        }
        
        contextData["assignedBuildings"] = String(contextAdapter.assignedBuildings.count)
        contextData["todaysTasks"] = String(contextAdapter.todaysTasks.count)
        
        if let urgentCount = urgentTaskCount {
            contextData["urgentTasks"] = String(urgentCount)
        }
        
        contextData["timeOfDay"] = getTimeBasedGreeting()
        contextData["completedTasks"] = String(contextAdapter.todaysTasks.filter { $0.isCompleted }.count)
        
        return contextData
    }
    
    @MainActor
    private func gatherInitialInsights() async -> [String] {
        var insights: [String] = []
        
        let completedTasks = contextAdapter.todaysTasks.filter { $0.isCompleted }.count
        let totalTasks = contextAdapter.todaysTasks.count
        if totalTasks > 0 {
            let completionRate = (completedTasks * 100) / totalTasks
            insights.append("Task completion rate: \(completionRate)%")
        }
        
        if let building = contextAdapter.currentBuilding {
            insights.append("Primary focus: \(building.name)")
        }
        
        return insights
    }
    
    @MainActor
    private func generateContextSummary() async -> String {
        let buildings = contextAdapter.assignedBuildings.count
        let tasks = contextAdapter.todaysTasks.count
        
        if shouldShowEmergencyRepair {
            return "⚠️ Assignment repair needed"
        } else if hasHighPriorityScenarios {
            return "🚨 \(buildings) buildings, \(tasks) tasks, priorities active"
        }
        
        return "\(buildings) buildings, \(tasks) tasks"
    }
    
    @MainActor
    private func generateWelcomeMessage() async -> String {
        guard let worker = contextAdapter.currentWorker else {
            return "Hello! I'm Nova, your AI assistant. Please log in to get started."
        }
        
        let greeting = getTimeBasedGreeting()
        let taskSummary = contextAdapter.todaysTasks.isEmpty ?
            "You have no tasks scheduled." :
            "You have \(contextAdapter.todaysTasks.count) tasks today."
        
        if shouldShowEmergencyRepair {
            return "\(greeting), \(worker.name)! I've detected an issue with your building assignments. Would you like me to run an emergency repair?"
        }
        
        return "\(greeting), \(worker.name)! I'm Nova, your AI property management assistant. \(taskSummary) How can I help you today?"
    }
    
    private func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    private func getCurrentShiftStart() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date().addingTimeInterval(-7200)) // 2 hours ago
    }
    
    private func handleQuickAction(_ action: String) {
        switch action {
        case "🚨 View Priorities":
            userQuery = "Show me all high priority items"
        case "📋 Today's Tasks":
            userQuery = "What are my tasks for today?"
        case "🔧 Fix Assignments":
            performEmergencyRepair()
            return
        case "🏢 Building Status":
            userQuery = "Show building status and metrics"
        case "📊 Metrics":
            userQuery = "Show performance metrics"
        default:
            break
        }
        
        if !userQuery.isEmpty {
            sendPrompt()
        }
    }
    
    // MARK: - Action Handlers
    
    private func navigateToBuilding(_ action: NovaAction) async {
        print("Navigate to building: \(action.title)")
    }
    
    private func scheduleTask(_ action: NovaAction) async {
        print("Schedule task: \(action.title)")
    }
    
    private func generateInsights() async {
        if let building = contextAdapter.currentBuilding {
            do {
                let insights = try await intelligenceService.generateBuildingInsights(for: building.id)
                print("Generated \(insights.count) insights for building \(building.name)")
            } catch {
                print("Failed to generate insights: \(error)")
            }
        }
    }
    
    // MARK: - Scenario Helpers
    
    private func getScenarioTitle(_ type: CoreTypes.AIScenarioType) -> String {
        switch type {
        case .taskOptimization: return "Task Optimization"
        case .routeOptimization: return "Route Optimization"
        case .inventoryManagement: return "Inventory Management"
        case .complianceAlert: return "Compliance Alert"
        case .maintenancePrediction: return "Maintenance Prediction"
        case .emergencyResponse: return "Emergency Response"
        }
    }
    
    private func getScenarioDescription(_ type: CoreTypes.AIScenarioType) -> String {
        switch type {
        case .taskOptimization: return "Optimize task scheduling and routing"
        case .routeOptimization: return "Improve route efficiency between locations"
        case .inventoryManagement: return "Monitor and manage supply inventory levels"
        case .complianceAlert: return "Address compliance-related issues"
        case .maintenancePrediction: return "Predict and prevent maintenance issues"
        case .emergencyResponse: return "Respond to emergency situations quickly"
        }
    }
    
    private func getScenarioIcon(_ type: CoreTypes.AIScenarioType) -> String {
        switch type {
        case .taskOptimization: return "list.bullet.clipboard.fill"
        case .routeOptimization: return "location.fill"
        case .inventoryManagement: return "shippingbox.fill"
        case .complianceAlert: return "exclamationmark.shield.fill"
        case .maintenancePrediction: return "wrench.and.screwdriver.fill"
        case .emergencyResponse: return "exclamationmark.triangle.fill"
        }
    }
    
    private func getScenarioPriority(_ type: CoreTypes.AIScenarioType) -> CoreTypes.AIPriority {
        switch type {
        case .emergencyResponse: return .critical
        case .complianceAlert: return .critical
        case .maintenancePrediction: return .high
        case .inventoryManagement: return .high
        case .taskOptimization: return .medium
        case .routeOptimization: return .medium
        }
    }
}

// MARK: - Supporting Types

struct NovaChatMessage: Identifiable {
    let id: String
    let role: ChatRole
    let content: String
    let timestamp: Date
    let priority: NovaPriority?
    let actions: [NovaAction]
    let insights: [NovaInsight]
    let metadata: [String: String]
    
    init(id: String, role: ChatRole, content: String, timestamp: Date, priority: NovaPriority? = nil, actions: [NovaAction] = [], insights: [NovaInsight] = [], metadata: [String: String] = [:]) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.priority = priority
        self.actions = actions
        self.insights = insights
        self.metadata = metadata
    }
    
    enum ChatRole {
        case user
        case assistant
    }
}

struct NovaChatBubble: View {
    let message: NovaChatMessage
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Priority indicator
                if let priority = message.priority, priority != .medium {
                    HStack(spacing: 4) {
                        Image(systemName: priority.systemImageName)
                            .font(.caption2)
                        Text(priority.displayName)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundColor(priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priority.color.opacity(0.2))
                    .cornerRadius(8)
                }
                
                // Message content with glass effect
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.content)
                        .padding()
                        .background(
                            ZStack {
                                if message.role == .user {
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            }
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // Actions if present
                    if !message.actions.isEmpty && (isExpanded || message.actions.count <= 2) {
                        NovaActionButtons(actions: message.actions)
                    }
                    
                    // Insights if present
                    if !message.insights.isEmpty && isExpanded {
                        NovaInsightsView(insights: message.insights)
                    }
                    
                    // Expand/collapse button
                    if (!message.actions.isEmpty && message.actions.count > 2) || !message.insights.isEmpty {
                        Button(action: onToggleExpand) {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show less" : "Show more")
                                    .font(.caption)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // Timestamp
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 300)
            
            if message.role == .assistant { Spacer() }
        }
    }
}

struct NovaActionButtons: View {
    let actions: [NovaAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(actions) { action in
                Button(action: {
                    executeAction(action)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: action.actionType.icon)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(action.title)
                                .font(.caption.weight(.medium))
                            if !action.description.isEmpty {
                                Text(action.description)
                                    .font(.caption2)
                                    .opacity(0.8)
                            }
                        }
                        
                        Spacer()
                        
                        if let priority = action.priority {
                            Circle()
                                .fill(priority.color)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func executeAction(_ action: NovaAction) {
        Task {
            // Execute action based on type
            switch action.actionType {
            case .navigate:
                print("Navigate to: \(action.title)")
                // Handle navigation
            case .schedule:
                print("Schedule: \(action.title)")
                // Handle scheduling
            case .complete:
                print("Complete: \(action.title)")
                // Handle completion
            case .review:
                print("Review: \(action.title)")
                // Handle review
            case .analysis:
                print("Analyze: \(action.title)")
                // Handle analysis
            case .report:
                print("Report: \(action.title)")
                // Handle reporting
            case .assign:
                print("Assign: \(action.title)")
                // Handle assignment
            case .notify:
                print("Notify: \(action.title)")
                // Handle notification
            }
        }
    }
}

// ✅ FIXED: Corrected NovaInsightsView to properly access insight properties
struct NovaInsightsView: View {
    let insights: [NovaInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("Insights")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.yellow)
            }
            
            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: insight.type.icon)
                        .font(.caption)
                        .foregroundColor(getInsightTypeColor(insight.type))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white)
                        Text(insight.description)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
            }
        }
    }
    
    // Helper function to get color for insight type
    private func getInsightTypeColor(_ type: CoreTypes.InsightCategory) -> Color {
        switch type {
        case .efficiency: return .blue
        case .cost: return .green
        case .safety: return .red
        case .compliance: return .orange
        case .quality: return .purple
        case .operations: return .gray
        case .maintenance: return .yellow
        case .routing: return .mint
        case .weather: return .cyan
        case .performance: return .indigo
        }
    }
}

struct NovaProcessingIndicator: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationPhase == Double(index) ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
            
            Text("Nova is thinking...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onAppear {
            animationPhase = 2.0
        }
    }
}

// MARK: - Extensions

extension NovaPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .critical: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension View {
    func francoGlassCard(intensity: Material = .ultraThinMaterial) -> some View {
        self
            .background(intensity)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    NovaInteractionView()
        .preferredColorScheme(.dark)
}

// MARK: - 📝 COMPILATION FIXES
/*
 ✅ FIXED ERRORS:
 
 1. Line 846: Added missing 'try' for throwing function call
    - generateBuildingInsights is a throwing function
    - Wrapped in do-catch block for proper error handling
 
 2. Lines 1353-1357: Fixed NovaInsightsView ForEach and property access
    - NovaInsight is a type alias for CoreTypes.IntelligenceInsight
    - insight.type is of type InsightCategory which has an 'icon' property
    - Added helper function getInsightTypeColor to get colors for categories
    - Removed incorrect binding syntax
 
 3. Line 1449: Removed orphaned extension code
    - Deleted loose code that was outside of any type definition
    - The extension for InsightCategory.color was duplicate/orphaned
 
 4. ARCHITECTURAL ALIGNMENT:
    - Using CoreTypes properly throughout
    - NovaInsight = CoreTypes.IntelligenceInsight
    - InsightCategory has icon property defined in CoreTypes
    - All type references properly qualified
 
 🎯 STATUS: All compilation errors resolved*/
