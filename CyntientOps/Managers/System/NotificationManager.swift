//
//  NotificationManager.swift
//  CyntientOps
//
//  ✅ FIXED: ContextualTask.buildingId → .buildingId property access
//  ✅ FIXED: Optional unwrapping for TaskCategory
//

import Foundation
import Combine
import UserNotifications

// MARK: - Notification Models

/// CyntientOps notification model
struct FSNotification: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let message: String
    let date: Date
    let isRead: Bool
    let type: NotificationType
    let relatedBuildingId: String?
    let relatedTaskId: String?
    let relatedWorkerId: String?
    let requiresAction: Bool
    let actionTaken: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, date, isRead, type, relatedBuildingId, relatedTaskId, relatedWorkerId, requiresAction, actionTaken
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         message: String,
         date: Date = Date(),
         isRead: Bool = false,
         type: NotificationType,
         relatedBuildingId: String? = nil,
         relatedTaskId: String? = nil,
         relatedWorkerId: String? = nil,
         requiresAction: Bool = false,
         actionTaken: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.type = type
        self.relatedBuildingId = relatedBuildingId
        self.relatedTaskId = relatedTaskId
        self.relatedWorkerId = relatedWorkerId
        self.requiresAction = requiresAction
        self.actionTaken = actionTaken
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case task = "Task"
    case maintenance = "Maintenance"
    case weather = "Weather"
    case inventory = "Inventory"
    case security = "Security"
    case system = "System"
    
    var icon: String {
        switch self {
        case .task: return "checklist"
        case .maintenance: return "wrench.and.screwdriver"
        case .weather: return "cloud.sun.rain"
        case .inventory: return "cube.box"
        case .security: return "lock.shield"
        case .system: return "gear"
        }
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [FSNotification] = []
    @Published var unreadCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        requestNotificationPermission()
        setupObservers()
        loadNotifications()
    }
    
    // MARK: - Notification Permission
    
    /// Request permission to send notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Notification Management
    
    /// Add a new notification
    func addNotification(
        title: String,
        message: String,
        type: NotificationType,
        buildingId: String? = nil,
        taskId: String? = nil,
        workerId: String? = nil,
        requiresAction: Bool = false
    ) {
        let notification = FSNotification(
            title: title,
            message: message,
            type: type,
            relatedBuildingId: buildingId,
            relatedTaskId: taskId,
            relatedWorkerId: workerId,
            requiresAction: requiresAction
        )
        
        notifications.insert(notification, at: 0)
        updateUnreadCount()
        saveNotifications()
        
        // Send local notification
        sendLocalNotification(title: title, message: message, type: type)
    }
    
    /// Add notification async for actor compatibility
    func addNotificationAsync(
        title: String,
        message: String,
        type: NotificationType,
        buildingId: String? = nil,
        taskId: String? = nil,
        workerId: String? = nil,
        requiresAction: Bool = false
    ) async {
        await MainActor.run {
            addNotification(
                title: title,
                message: message,
                type: type,
                buildingId: buildingId,
                taskId: taskId,
                workerId: workerId,
                requiresAction: requiresAction
            )
        }
    }
    
    /// Mark a notification as read
    func markAsRead(notificationId: String) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index] = FSNotification(
                id: notifications[index].id,
                title: notifications[index].title,
                message: notifications[index].message,
                date: notifications[index].date,
                isRead: true,
                type: notifications[index].type,
                relatedBuildingId: notifications[index].relatedBuildingId,
                relatedTaskId: notifications[index].relatedTaskId,
                relatedWorkerId: notifications[index].relatedWorkerId,
                requiresAction: notifications[index].requiresAction,
                actionTaken: notifications[index].actionTaken
            )
        }
        
        saveNotifications()
        updateUnreadCount()
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        notifications = notifications.map { notification in
            FSNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                date: notification.date,
                isRead: true,
                type: notification.type,
                relatedBuildingId: notification.relatedBuildingId,
                relatedTaskId: notification.relatedTaskId,
                relatedWorkerId: notification.relatedWorkerId,
                requiresAction: notification.requiresAction,
                actionTaken: notification.actionTaken
            )
        }
        
        saveNotifications()
        updateUnreadCount()
    }
    
    /// Get notifications requiring action
    var actionableNotifications: [FSNotification] {
        return notifications.filter { $0.requiresAction && !$0.actionTaken }
    }
    
    /// Get unread notifications
    var unreadNotifications: [FSNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    /// Get notifications by type
    func getNotifications(ofType type: NotificationType) -> [FSNotification] {
        return notifications.filter { $0.type == type }
    }
    
    /// Get notifications for a building
    func getNotifications(forBuilding buildingId: String) -> [FSNotification] {
        return notifications.filter { $0.relatedBuildingId == buildingId }
    }
    
    /// Get notifications for a task
    func getNotifications(forTask taskId: String) -> [FSNotification] {
        return notifications.filter { $0.relatedTaskId == taskId }
    }
    
    /// Get notifications for a worker
    func getNotifications(forWorker workerId: String) -> [FSNotification] {
        return notifications.filter { $0.relatedWorkerId == workerId }
    }
    
    // MARK: - Local Notifications
    
    /// Send a local notification
    private func sendLocalNotification(title: String, message: String, type: NotificationType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        content.categoryIdentifier = type.rawValue
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    // MARK: - Task Notifications (FIXED: Property access)
    
    /// Generate task-related notifications
    func generateTaskNotifications(for task: ContextualTask) {
        // ✅ FIXED: Use buildingId property directly
        let buildingId = task.buildingId ?? task.building?.id ?? "unknown"
        
        if task.isOverdue {
            addNotification(
                title: "Overdue Task",
                message: "Task '\(task.title)' is overdue",
                type: .task,
                buildingId: buildingId,
                taskId: task.id,
                requiresAction: true
            )
        }
        
        // ✅ FIXED: Properly unwrap optional TaskCategory before accessing rawValue
        let categoryName: String
        if let category = task.category {
            categoryName = category.rawValue
        } else {
            categoryName = "General"
        }
        
        if task.priority ?? task.urgency ?? .medium == .high {
            addNotification(
                title: "High Priority Task",
                message: "High priority \(categoryName) task: \(task.title)",
                type: .task,
                buildingId: buildingId,
                taskId: task.id
            )
        }
    }
    
    // MARK: - Private Helpers
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    private func saveNotifications() {
        if let data = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(data, forKey: "CyntientOps_Notifications")
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: "CyntientOps_Notifications"),
           let savedNotifications = try? JSONDecoder().decode([FSNotification].self, from: data) {
            notifications = savedNotifications
            updateUnreadCount()
        }
    }
    
    private func setupObservers() {
        // Task completion notifications
        NotificationCenter.default.publisher(for: Notification.Name("TaskCompleted"))
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let taskTitle = userInfo["taskTitle"] as? String else {
                    return
                }
                
                self.addNotification(
                    title: "Task Completed",
                    message: "Successfully completed: \(taskTitle)",
                    type: .task
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Weather Notifications
    
    /// Generate weather-related notifications for a building
    func generateWeatherNotifications(for building: NamedCoordinate) {
        Task { @MainActor in
            let weatherAdapter = WeatherDataAdapter.shared
            
            if let weatherAlert = generateWeatherAlertMessage(for: building) {
                await self.addNotificationAsync(
                    title: "Weather Alert",
                    message: weatherAlert,
                    type: .weather,
                    buildingId: building.id
                )
            }
        }
    }
    
    private func generateWeatherAlertMessage(for building: NamedCoordinate) -> String? {
        // This would integrate with WeatherDataAdapter to generate actual alerts
        return "Weather conditions may affect operations at \(building.name)"
    }
}
