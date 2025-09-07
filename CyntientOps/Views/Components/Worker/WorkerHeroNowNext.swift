import SwiftUI

struct WorkerHeroNowNext: View {
    @ObservedObject var viewModel: WorkerDashboardViewModel
    let container: ServiceContainer
    var onTaskTap: ((TaskRowVM) -> Void)? = nil
    var onBuildingTap: ((String) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            heroCard(title: "Now", routes: nowRoutes(), color: .blue)
            heroCard(title: "Next", routes: nextRoutes(), color: .purple)
        }
    }

    private func heroCard(title: String, routes: [RouteItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Circle().fill(color).frame(width: 6, height: 6)
            }
            
            if routes.isEmpty {
                Text("All Clear").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(routes.prefix(2), id: \.id) { route in
                    HStack(spacing: 8) {
                        Circle().fill(color.opacity(0.8)).frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(route.buildingName).font(.subheadline)
                            Text(route.time).font(.caption2).foregroundColor(.gray)
                        }
                        Spacer()
                        
                        // Route icon
                        Image(systemName: route.icon)
                            .font(.caption2)
                            .foregroundColor(color.opacity(0.7))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Direct building navigation using buildingId
                        if let buildingId = route.buildingId {
                            onBuildingTap?(buildingId)
                        }
                        // Fallback to task tap if building tap not provided
                        else if let taskVM = routeItemToTaskRowVM(route) {
                            onTaskTap?(taskVM)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Route-Driven Data Source
    
    private func nowRoutes() -> [RouteItem] {
        guard let workerId = viewModel.worker?.id else { return [] }
        
        // Get current active routes from RouteManager
        let now = Date()
        let todaysRoutes = container.routes.today(for: workerId, date: now)
        
        // Return active routes (currently happening)
        return Array(todaysRoutes.filter { $0.isActive }.prefix(2))
    }
    
    private func nextRoutes() -> [RouteItem] {
        guard let workerId = viewModel.worker?.id else { return [] }
        
        // Get next upcoming route
        if let nextRoute = container.routes.nextUp(for: workerId, from: Date()) {
            return [nextRoute]
        }
        
        // Fallback: get next few routes from today that aren't active yet
        let now = Date()
        let todaysRoutes = container.routes.today(for: workerId, date: now)
        let upcomingRoutes = todaysRoutes.filter { !$0.isActive }
        
        return Array(upcomingRoutes.prefix(2))
    }
    
    // MARK: - Compatibility Helper
    
    private func routeItemToTaskRowVM(_ routeItem: RouteItem) -> TaskRowVM? {
        // Convert RouteItem to TaskRowVM for compatibility with existing tap handlers
        // Create a minimal ContextualTask from the RouteItem
        let contextualTask = CoreTypes.ContextualTask(
            id: routeItem.id,
            title: routeItem.buildingName,
            description: "Route task at \(routeItem.buildingName)",
            dueDate: nil, // Could be enhanced with actual route time
            category: .maintenance, // Default category
            buildingId: routeItem.buildingId,
            buildingName: routeItem.buildingName,
            priority: .medium
        )
        
        let scoredTask = ScoredTask(task: contextualTask, score: 0)
        return TaskRowVM(scored: scoredTask)
    }
}
