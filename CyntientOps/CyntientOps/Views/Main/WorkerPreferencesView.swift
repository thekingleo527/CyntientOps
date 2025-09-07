//
//  WorkerPreferencesView.swift
//  CyntientOps
//
//  Stream A: UI/UX & Spanish
//  Mission: Allow workers to customize their app experience.
//
//  ✅ PRODUCTION READY: Complete preferences management for workers.
//  ✅ INTEGRATED: Works with ThemeManager, GRDBManager, and worker capabilities.
//  ✅ ACCESSIBLE: Large touch targets and clear visual feedback.
//  ✅ BILINGUAL: Supports English/Spanish language switching.
//

import SwiftUI
import Combine

struct WorkerPreferencesView: View {
    
    @StateObject private var viewModel: WorkerPreferencesViewModel
    
    // ThemeManager can be injected as an EnvironmentObject if it's provided by a parent view.
    // For standalone use, it can also be instantiated directly.
    @StateObject private var themeManager = ThemeManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    init(workerId: String) {
        // Initialize the StateObject with the workerId, which is then passed to the ViewModel.
        self._viewModel = StateObject(wrappedValue: WorkerPreferencesViewModel(workerId: workerId))
    }
    
    var body: some View {
        NavigationView {
            Form {
                languageSection
                displaySection
                accessibilitySection
                notificationsSection
                aboutSection
            }
            .navigationTitle(LocalizedStringKey("Preferences"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("Done")) {
                        Task {
                            await viewModel.savePreferences()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.hasChanges)
                }
            }
        }
        .task {
            // Asynchronously load the worker's current preferences when the view appears.
            await viewModel.loadPreferences()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Failed to save preferences")
        }
    }
    
    // MARK: - Sections
    
    private var languageSection: some View {
        Section {
            HStack {
                Label("Language", systemImage: "globe")
                Spacer()
                Picker("Language", selection: $viewModel.selectedLanguage) {
                    Text("English").tag("en")
                    Text("Español").tag("es")
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedLanguage) { _ in
                    updateAppLanguage(to: viewModel.selectedLanguage)
                }
            }
        } header: {
            Text("Preferred Language")
        } footer: {
            Text("Choose your preferred language for the app interface.")
                .font(.caption)
        }
    }
    
    private var displaySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Text Size", systemImage: "textformat.size")
                
                HStack(spacing: 16) {
                    Image(systemName: "textformat.size.smaller")
                        .foregroundColor(.secondary)
                    
                    Slider(value: $viewModel.textSizeMultiplier, in: 0.8...1.5, step: 0.1)
                    
                    Image(systemName: "textformat.size.larger")
                        .foregroundColor(.secondary)
                }
                
                Text("Sample Text")
                    .font(.body)
                    .scaleEffect(viewModel.textSizeMultiplier)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
            }
            .padding(.vertical, 4)
            
            Toggle(isOn: $viewModel.useHighContrast) {
                Label("High Contrast Mode", systemImage: "circle.lefthalf.filled")
            }
            .onChange(of: viewModel.useHighContrast) { _ in
                themeManager.toggleHighContrast(isOn: viewModel.useHighContrast)
            }
            
            HStack {
                Label("Theme", systemImage: "moon.circle")
                Spacer()
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    ForEach(ThemeManager.Theme.allCases) { theme in
                        Text(LocalizedStringKey(theme.displayName)).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: viewModel.selectedTheme) { _ in
                    themeManager.applyTheme(viewModel.selectedTheme)
                }
            }
        } header: {
            Text("Display")
        }
    }
    
    private var accessibilitySection: some View {
        Section {
            Toggle(isOn: $viewModel.useSimplifiedInterface) {
                Label("Simplified Interface", systemImage: "square.grid.2x2")
            }
            
            if viewModel.canTogglePhotoRequirement {
                Toggle(isOn: $viewModel.requiresPhoto) {
                    Label("Require Photos for Tasks", systemImage: "camera")
                }
            }
            
            Toggle(isOn: $viewModel.reduceMotion) {
                Label("Reduce Motion", systemImage: "figure.walk.motion")
            }
        } header: {
            Text("Accessibility")
        } footer: {
            if viewModel.useSimplifiedInterface {
                Text("Simplified interface shows only essential features with larger buttons.")
                    .font(.caption)
            }
        }
    }
    
    private var notificationsSection: some View {
        Section {
            Toggle(isOn: $viewModel.enableNotifications) {
                Label("Enable Push Notifications", systemImage: "bell")
            }
            
            if viewModel.enableNotifications {
                Toggle(isOn: $viewModel.urgentTaskAlerts) {
                    Label("Urgent Task Alerts", systemImage: "exclamationmark.triangle")
                }
                
                Toggle(isOn: $viewModel.clockInReminders) {
                    Label("Clock In Reminders", systemImage: "clock")
                }
                
                Toggle(isOn: $viewModel.endOfDayReports) {
                    Label("End of Day Reports", systemImage: "doc.text")
                }
            }
        } header: {
            Text("Notifications")
        }
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("6.0.0")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Worker ID")
                Spacer()
                Text(viewModel.workerId)
                    .foregroundColor(.secondary)
                    .font(.system(.caption, design: .monospaced))
            }
        } header: {
            Text("About")
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateAppLanguage(to languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        // NOTE: For the change to take full effect, the user may need to restart the app.
        // A production app might show an alert suggesting this.
    }
}

// MARK: - Worker Preferences ViewModel

@MainActor
class WorkerPreferencesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var selectedLanguage = "en"
    @Published var textSizeMultiplier: Double = 1.0
    @Published var useHighContrast = false
    @Published var selectedTheme: ThemeManager.Theme = .system
    @Published var useSimplifiedInterface = false
    @Published var requiresPhoto = true
    @Published var reduceMotion = false
    @Published var enableNotifications = true
    @Published var urgentTaskAlerts = true
    @Published var clockInReminders = true
    @Published var endOfDayReports = false
    
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var hasChanges = false
    
    let workerId: String
    var canTogglePhotoRequirement = true
    
    private let grdbManager = GRDBManager.shared
    private var initialPreferencesState: Data?
    private var cancellables = Set<AnyCancellable>()
    
    init(workerId: String) {
        self.workerId = workerId
        setupChangeMonitor()
    }
    
    // MARK: - Data Operations
    
    func loadPreferences() async {
        isLoading = true
        
        do {
            let rows = try await grdbManager.query("""
                SELECT * FROM worker_capabilities
                WHERE worker_id = ?
                LIMIT 1
            """, [workerId])
            
            if let row = rows.first {
                useSimplifiedInterface = (row["simplified_interface"] as? Int64 ?? 0) == 1
                requiresPhoto = (row["requires_photo_for_sanitation"] as? Int64 ?? 1) == 1
                canTogglePhotoRequirement = (row["can_add_emergency_tasks"] as? Int64 ?? 0) == 1
                selectedLanguage = row["preferred_language"] as? String ?? "en"
            }
            
            loadLocalPreferences()
            
            // Capture the initial state after loading to check for changes later.
            captureInitialState()
            
        } catch {
            errorMessage = "Failed to load preferences: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func savePreferences() async {
        do {
            try await grdbManager.execute("""
                INSERT INTO worker_capabilities (worker_id, simplified_interface, requires_photo_for_sanitation, preferred_language, updated_at)
                VALUES (?, ?, ?, ?, datetime('now'))
                ON CONFLICT(worker_id) DO UPDATE SET
                simplified_interface = excluded.simplified_interface,
                requires_photo_for_sanitation = excluded.requires_photo_for_sanitation,
                preferred_language = excluded.preferred_language,
                updated_at = datetime('now')
            """, [
                workerId,
                useSimplifiedInterface ? 1 : 0,
                requiresPhoto ? 1 : 0,
                selectedLanguage
            ])
            
            saveLocalPreferences()
            captureInitialState() // Reset the "changes" tracker
            
            print("✅ Preferences saved successfully for worker \(workerId)")
            
            // Notify the rest of the app that preferences have changed.
            NotificationCenter.default.post(name: .workerPreferencesChanged, object: nil)
            
        } catch {
            errorMessage = "Failed to save preferences: \(error.localizedDescription)"
            showError = true
        }
    }
    
    // MARK: - Change Monitoring
    
    private func setupChangeMonitor() {
        // Chain multiple CombineLatest publishers to handle more than 4 values
        let group1 = Publishers.CombineLatest4(
            $selectedLanguage,
            $textSizeMultiplier,
            $useHighContrast,
            $selectedTheme
        )
        
        let group2 = Publishers.CombineLatest4(
            $useSimplifiedInterface,
            $requiresPhoto,
            $reduceMotion,
            $enableNotifications
        )
        
        Publishers.CombineLatest(group1, group2)
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkForChanges()
            }
            .store(in: &cancellables)
    }
    
    private func captureInitialState() {
        let currentState = [
            selectedLanguage,
            String(textSizeMultiplier),
            String(useHighContrast),
            selectedTheme.rawValue,
            String(useSimplifiedInterface),
            String(requiresPhoto),
            String(reduceMotion),
            String(enableNotifications)
        ].joined(separator: "|")
        
        initialPreferencesState = currentState.data(using: .utf8)
        hasChanges = false
    }
    
    private func checkForChanges() {
        let currentState = [
            selectedLanguage,
            String(textSizeMultiplier),
            String(useHighContrast),
            selectedTheme.rawValue,
            String(useSimplifiedInterface),
            String(requiresPhoto),
            String(reduceMotion),
            String(enableNotifications)
        ].joined(separator: "|")
        
        let currentStateData = currentState.data(using: .utf8)
        
        if let initialState = initialPreferencesState {
            hasChanges = initialState != currentStateData
        }
    }
    
    // MARK: - Helper Methods for Local Preferences
    
    private func loadLocalPreferences() {
        let defaults = UserDefaults.standard
        let prefix = "worker_\(workerId)_"
        
        textSizeMultiplier = defaults.double(forKey: "\(prefix)textSize")
        if textSizeMultiplier == 0 { textSizeMultiplier = 1.0 }
        
        useHighContrast = defaults.bool(forKey: "\(prefix)highContrast")
        reduceMotion = defaults.bool(forKey: "\(prefix)reduceMotion")
        
        if let themeRawValue = defaults.string(forKey: "\(prefix)theme"),
           let theme = ThemeManager.Theme(rawValue: themeRawValue) {
            selectedTheme = theme
        }
        
        enableNotifications = defaults.object(forKey: "\(prefix)enableNotifications") as? Bool ?? true
        urgentTaskAlerts = defaults.object(forKey: "\(prefix)urgentTaskAlerts") as? Bool ?? true
        clockInReminders = defaults.object(forKey: "\(prefix)clockInReminders") as? Bool ?? true
        endOfDayReports = defaults.object(forKey: "\(prefix)endOfDayReports") as? Bool ?? false
    }
    
    private func saveLocalPreferences() {
        let defaults = UserDefaults.standard
        let prefix = "worker_\(workerId)_"
        
        defaults.set(textSizeMultiplier, forKey: "\(prefix)textSize")
        defaults.set(useHighContrast, forKey: "\(prefix)highContrast")
        defaults.set(reduceMotion, forKey: "\(prefix)reduceMotion")
        defaults.set(selectedTheme.rawValue, forKey: "\(prefix)theme")
        
        defaults.set(enableNotifications, forKey: "\(prefix)enableNotifications")
        defaults.set(urgentTaskAlerts, forKey: "\(prefix)urgentTaskAlerts")
        defaults.set(clockInReminders, forKey: "\(prefix)clockInReminders")
        defaults.set(endOfDayReports, forKey: "\(prefix)endOfDayReports")
    }
}

// MARK: - Notification Name Extension
extension Notification.Name {
    static let workerPreferencesChanged = Notification.Name("workerPreferencesChanged")
}

// MARK: - Preview
struct WorkerPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkerPreferencesView(workerId: "4") // Kevin
                .environmentObject(ThemeManager.shared)
                .environment(\.locale, .init(identifier: "en"))
            
            WorkerPreferencesView(workerId: "5") // Mercedes
                .environmentObject(ThemeManager.shared)
                .environment(\.locale, .init(identifier: "es"))
                .preferredColorScheme(.dark)
        }
    }
}
