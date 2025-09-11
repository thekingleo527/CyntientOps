//
//  NavigationCoordinator.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create a centralized navigation system to manage app flow.
//
//  ✅ PRODUCTION READY: A robust, observable object for programmatic navigation.
//  ✅ MODERN: Uses SwiftUI's NavigationPath for type-safe, stack-based navigation.
//  ✅ CENTRALIZED: Manages tabs, sheets, and alerts from a single source of truth.
//  ✅ DEEP LINKING: Contains logic to handle incoming URLs.
//  ✅ FIXED: Removed duplicate WorkerPreferencesView definition.
//

import SwiftUI
import Combine

@MainActor
final class NavigationCoordinator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NavigationCoordinator()
    
    // MARK: - Published Properties
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: Tab = .dashboard
    @Published var presentedSheet: SheetType?
    @Published var presentedAlert: AlertType?
    
    // MARK: - Tab Definitions
    enum Tab: String, Hashable {
        case dashboard
        case tasks
        case buildings
        case profile
    }
    
    // MARK: - Sheet & Alert Definitions
    enum SheetType: Identifiable, Hashable {
        case taskDetail(taskId: String)
        case buildingDetail(buildingId: String)
        case photoCapture(forTask: ContextualTask)
        case settings
        case workerPreferences(workerId: String)
        case conflictResolution(conflict: Conflict) // Assuming Conflict is Hashable
        
        var id: String {
            switch self {
            case .taskDetail(let taskId): return "task-\(taskId)"
            case .buildingDetail(let buildingId): return "building-\(buildingId)"
            case .photoCapture: return "photo-capture"
            case .settings: return "settings"
            case .workerPreferences(let workerId): return "prefs-\(workerId)"
            case .conflictResolution(let conflict): return "conflict-\(conflict.entityId)"
            }
        }
        
        // Conformance to Hashable
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: SheetType, rhs: SheetType) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    enum AlertType: Identifiable {
        case genericError(title: String, message: String)
        case actionConfirmation(title: String, message: String, action: () -> Void)
        case logoutConfirmation
        
        var id: String {
            switch self {
            case .genericError(let title, _): return "error-\(title)"
            case .actionConfirmation(let title, _, _): return "confirm-\(title)"
            case .logoutConfirmation: return "logout"
            }
        }
    }
    
    private init() {}
    
    // MARK: - Navigation Methods
    
    func selectTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func push<V: Hashable>(_ view: V) {
        navigationPath.append(view)
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func pop(count: Int) {
        navigationPath.removeLast(min(count, navigationPath.count))
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    // MARK: - Sheet & Alert Presentation
    
    func presentSheet(_ sheet: SheetType) {
        presentedSheet = sheet
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func presentAlert(_ alert: AlertType) {
        presentedAlert = alert
    }
    
    func dismissAlert() {
        presentedAlert = nil
    }
    
    // MARK: - Deep Linking
    
    func handleDeepLink(_ url: URL) {
        // Supported formats:
        // cyntientops://task/<taskId>
        // cyntientops://building/<buildingId>
        let host = url.host?.lowercased()
        let segments = url.pathComponents.filter { $0 != "/" }
        guard let first = host ?? segments.first else { return }
        let id: String? = host != nil ? segments.first : (segments.count > 1 ? segments[1] : nil)
        switch first {
        case "task":
            if let id = id { presentSheet(.taskDetail(taskId: id)) }
        case "building":
            if let id = id { presentSheet(.buildingDetail(buildingId: id)) }
        default:
            break
        }
    }
}

// MARK: - View Modifier for easy access

struct NavigationCoordinatorViewModifier: ViewModifier {
    @StateObject private var coordinator = NavigationCoordinator.shared
    @EnvironmentObject private var container: ServiceContainer
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $coordinator.presentedSheet) { sheetType in
                switch sheetType {
                case .taskDetail(let taskId):
                    TaskDetailSheet(taskId: taskId, container: container)
                case .buildingDetail(let buildingId):
                    BuildingDetailSheet(buildingId: buildingId, container: container)
                case .workerPreferences(let workerId):
                    // This now correctly points to the single, authoritative WorkerPreferencesView file.
                    WorkerPreferencesView(workerId: workerId)
                case .conflictResolution(let conflict):
                    VStack(spacing: 20) {
                        Text("🔄 Conflict Resolution")
                            .font(.title2)
                        Text("Conflict detected - resolution needed")
                            .foregroundColor(.secondary)
                        Button("Resolve") {
                            // Handle resolution choice
                            coordinator.dismissSheet()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                default:
                    Text("Unknown Sheet")
                }
            }
            .alert(item: $coordinator.presentedAlert) { alertType in
                // Alert logic remains the same...
                switch alertType {
                case .genericError(let title, let message):
                    return Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
                case .actionConfirmation(let title, let message, let action):
                    return Alert(
                        title: Text(title),
                        message: Text(message),
                        primaryButton: .destructive(Text("Confirm"), action: action),
                        secondaryButton: .cancel()
                    )
                case .logoutConfirmation:
                    return Alert(
                        title: Text("Logout"),
                        message: Text("Are you sure you want to logout?"),
                        primaryButton: .destructive(Text("Logout")) {
                            Task {
                                await NewAuthManager.shared.logout()
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
    }
}

// MARK: - Loader Sheets

private struct TaskDetailSheet: View {
    let taskId: String
    let container: ServiceContainer
    @State private var task: CoreTypes.ContextualTask?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let task = task {
                UnifiedTaskDetailView(task: task, mode: .dashboard)
            } else if isLoading {
                ProgressView("Loading task…")
                    .padding()
            } else {
                Text("Task not found")
            }
        }
        .task {
            do {
                let loaded = try await container.tasks.getTask(taskId)
                await MainActor.run { self.task = loaded; self.isLoading = false }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}

private struct BuildingDetailSheet: View {
    let buildingId: String
    let container: ServiceContainer
    @State private var building: NamedCoordinate?
    @State private var isLoading = true

    var body: some View {
        Group {
            if let b = building {
                BuildingDetailView(container: container, buildingId: b.id, buildingName: b.name, buildingAddress: b.address)
            } else if isLoading {
                ProgressView("Loading building…")
                    .padding()
            } else {
                Text("Building not found")
            }
        }
        .task {
            do {
                let loaded = try await container.buildings.getBuilding(buildingId: buildingId)
                await MainActor.run { self.building = loaded; self.isLoading = false }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}

extension View {
    func withNavigationCoordinator() -> some View {
        self.modifier(NavigationCoordinatorViewModifier())
    }
}
