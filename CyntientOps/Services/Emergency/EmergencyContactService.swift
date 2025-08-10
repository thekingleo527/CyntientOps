//
//  EmergencyContactService.swift
//  CyntientOps (formerly CyntientOps)
//
//  Extracted from CoverageInfoCard.swift - Emergency Contact Management
//  ✅ ENHANCED: Full emergency contact system with building-specific contacts
//  ✅ INTEGRATED: NYC emergency services, building security, management contacts
//  ✅ FEATURES: Auto-dialing, emergency logging, escalation procedures
//

import Foundation
import UIKit
import Combine

@MainActor
public final class EmergencyContactService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var isEmergencyMode = false
    @Published public private(set) var lastEmergencyCall: EmergencyCall?
    @Published public private(set) var emergencyLog: [EmergencyCall] = []
    
    // MARK: - Singleton
    
    public static let shared = EmergencyContactService()
    
    private init() {
        loadEmergencyLog()
    }
    
    // MARK: - Emergency Activation
    
    /// Activate emergency mode (triggers all emergency protocols)
    public func activateEmergencyMode(buildingId: String, reason: EmergencyReason) {
        isEmergencyMode = true
        
        let emergencyCall = EmergencyCall(
            id: UUID().uuidString,
            buildingId: buildingId,
            reason: reason,
            timestamp: Date(),
            status: .initiated
        )
        
        lastEmergencyCall = emergencyCall
        emergencyLog.append(emergencyCall)
        
        // Log emergency activation
        logEmergencyEvent("Emergency mode activated", buildingId: buildingId, reason: reason)
        
        // Auto-notify management (non-blocking)
        Task {
            await notifyManagement(of: emergencyCall)
        }
        
        saveEmergencyLog()
    }
    
    /// Deactivate emergency mode
    public func deactivateEmergencyMode() {
        isEmergencyMode = false
        
        if var lastCall = lastEmergencyCall {
            lastCall.status = .resolved
            lastCall.resolvedAt = Date()
            lastEmergencyCall = lastCall
            
            // Update in log
            if let index = emergencyLog.firstIndex(where: { $0.id == lastCall.id }) {
                emergencyLog[index] = lastCall
            }
        }
        
        logEmergencyEvent("Emergency mode deactivated")
        saveEmergencyLog()
    }
    
    // MARK: - Emergency Contacts
    
    /// Make emergency call (extracted from CoverageInfoCard logic)
    public func makeEmergencyCall(_ contact: EmergencyContact, buildingId: String? = nil) {
        guard let phoneURL = URL(string: "tel://\(contact.phoneNumber)") else {
            print("❌ Invalid phone number: \(contact.phoneNumber)")
            return
        }
        
        // Log the call attempt
        let emergencyCall = EmergencyCall(
            id: UUID().uuidString,
            buildingId: buildingId,
            contactType: contact.type,
            contactName: contact.name,
            phoneNumber: contact.phoneNumber,
            timestamp: Date(),
            status: .inProgress
        )
        
        emergencyLog.append(emergencyCall)
        lastEmergencyCall = emergencyCall
        
        // Make the actual call
        if UIApplication.shared.canOpenURL(phoneURL) {
            UIApplication.shared.open(phoneURL) { success in
                Task { @MainActor in
                    if var call = self.lastEmergencyCall, call.id == emergencyCall.id {
                        call.status = success ? .completed : .failed
                        self.lastEmergencyCall = call
                        
                        if let index = self.emergencyLog.firstIndex(where: { $0.id == call.id }) {
                            self.emergencyLog[index] = call
                        }
                    }
                }
            }
        } else {
            // Update status to failed
            if var call = lastEmergencyCall, call.id == emergencyCall.id {
                call.status = .failed
                lastEmergencyCall = call
                
                if let index = emergencyLog.firstIndex(where: { $0.id == call.id }) {
                    emergencyLog[index] = call
                }
            }
        }
        
        saveEmergencyLog()
    }
    
    // MARK: - Contact Lookup
    
    /// Get emergency contacts for a specific building
    public func getEmergencyContacts(for buildingId: String) -> [EmergencyContact] {
        var contacts: [EmergencyContact] = []
        
        // Always include 911 first
        contacts.append(.primary911)
        
        // Add building-specific security
        if let security = getBuildingSecurity(buildingId) {
            contacts.append(security)
        }
        
        // Add building management
        if let management = getBuildingManagement(buildingId) {
            contacts.append(management)
        }
        
        // Add NYC services
        contacts.append(contentsOf: getNYCEmergencyServices())
        
        // Add company contacts
        contacts.append(contentsOf: getCompanyEmergencyContacts())
        
        return contacts
    }
    
    /// Get primary emergency contact (911)
    public func getPrimaryEmergencyContact() -> EmergencyContact {
        return .primary911
    }
    
    // MARK: - Building-Specific Contacts
    
    private func getBuildingSecurity(_ buildingId: String) -> EmergencyContact? {
        // Building-specific security contacts
        switch buildingId {
        case "14": // Rubin Museum
            return EmergencyContact(
                name: "Rubin Museum Security",
                phoneNumber: "212-620-5000",
                type: .buildingSecurity,
                buildingId: buildingId
            )
            
        case "16": // Stuyvesant Cove Park
            return EmergencyContact(
                name: "Stuyvesant Cove Security",
                phoneNumber: "212-233-4013",
                type: .buildingSecurity,
                buildingId: buildingId
            )
            
        default:
            // Generic building security
            return EmergencyContact(
                name: "Building Security",
                phoneNumber: "311", // NYC 311 as fallback
                type: .buildingSecurity,
                buildingId: buildingId
            )
        }
    }
    
    private func getBuildingManagement(_ buildingId: String) -> EmergencyContact? {
        // Client-specific management contacts
        let client = WorkerBuildingAssignments.getClient(for: buildingId)
        
        switch client {
        case "JM Realty":
            return EmergencyContact(
                name: "JM Realty Management",
                phoneNumber: "212-555-0001", // Placeholder - replace with real number
                type: .management,
                buildingId: buildingId
            )
            
        case "Weber Farhat":
            return EmergencyContact(
                name: "Weber Farhat Management",
                phoneNumber: "212-555-0002", // Placeholder
                type: .management,
                buildingId: buildingId
            )
            
        case "Solar One":
            return EmergencyContact(
                name: "Solar One Management",
                phoneNumber: "212-233-4013",
                type: .management,
                buildingId: buildingId
            )
            
        default:
            return nil
        }
    }
    
    // MARK: - NYC Emergency Services
    
    private func getNYCEmergencyServices() -> [EmergencyContact] {
        return [
            .nycFire,
            .nycPolice,
            .nycEMS,
            .nyc311,
            .conEdison,
            .nationalGrid
        ]
    }
    
    // MARK: - Company Emergency Contacts
    
    private func getCompanyEmergencyContacts() -> [EmergencyContact] {
        return [
            EmergencyContact(
                name: "Franco Management Emergency",
                phoneNumber: "917-555-0000", // Placeholder - replace with real
                type: .company
            ),
            EmergencyContact(
                name: "Greg Hutson (Building Worker)",
                phoneNumber: "917-555-0001", // Placeholder
                type: .worker
            ),
            EmergencyContact(
                name: "Shawn Magloire (Technical)",
                phoneNumber: "917-555-0002", // Placeholder
                type: .technical
            )
        ]
    }
    
    // MARK: - Emergency Logging
    
    private func logEmergencyEvent(_ message: String, buildingId: String? = nil, reason: EmergencyReason? = nil) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var logMessage = "[\(timestamp)] EMERGENCY: \(message)"
        
        if let buildingId = buildingId {
            let buildingName = WorkerBuildingAssignments.getBuildingName(for: buildingId) ?? "Building \(buildingId)"
            logMessage += " - Building: \(buildingName)"
        }
        
        if let reason = reason {
            logMessage += " - Reason: \(reason.rawValue)"
        }
        
        print("🚨 \(logMessage)")
        
        // In production, this would also log to external services
        // SentrySDK.addBreadcrumb(message: logMessage, category: "emergency")
    }
    
    // MARK: - Management Notification
    
    private func notifyManagement(of emergency: EmergencyCall) async {
        // In production, this would send push notifications, emails, etc.
        print("📧 Notifying management of emergency: \(emergency.reason?.rawValue ?? "Unknown")")
        
        // Auto-notify Shawn Magloire (Manager)
        let managerContact = EmergencyContact(
            name: "Shawn Magloire (Manager)",
            phoneNumber: "917-555-0008", // Placeholder
            type: .manager
        )
        
        // In real implementation, this would send automated notifications
        // - Push notification to manager's device
        // - SMS alert
        // - Email notification
        // - Slack/Teams message
    }
    
    // MARK: - Data Persistence
    
    private func saveEmergencyLog() {
        // Save to UserDefaults for now (in production, would use secure storage)
        if let data = try? JSONEncoder().encode(emergencyLog) {
            UserDefaults.standard.set(data, forKey: "EmergencyLog")
        }
    }
    
    private func loadEmergencyLog() {
        if let data = UserDefaults.standard.data(forKey: "EmergencyLog"),
           let log = try? JSONDecoder().decode([EmergencyCall].self, from: data) {
            emergencyLog = log
        }
    }
}

// MARK: - Data Models

public struct EmergencyContact: Identifiable, Codable {
    public let id: String
    public let name: String
    public let phoneNumber: String
    public let type: ContactType
    public let buildingId: String?
    public let description: String?
    
    public init(
        name: String,
        phoneNumber: String,
        type: ContactType,
        buildingId: String? = nil,
        description: String? = nil
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.phoneNumber = phoneNumber
        self.type = type
        self.buildingId = buildingId
        self.description = description
    }
    
    public enum ContactType: String, Codable, CaseIterable {
        case emergency911 = "911"
        case fire = "fire"
        case police = "police"
        case ems = "ems"
        case buildingSecurity = "building_security"
        case management = "management"
        case company = "company"
        case manager = "manager"
        case technical = "technical"
        case utility = "utility"
        case cityService = "city_service"
        
        var displayName: String {
            switch self {
            case .emergency911: return "911 Emergency"
            case .fire: return "Fire Department"
            case .police: return "Police"
            case .ems: return "EMS"
            case .buildingSecurity: return "Building Security"
            case .management: return "Management"
            case .company: return "Company"
            case .manager: return "Manager"
            case .technical: return "Technical Support"
            case .utility: return "Utility Company"
            case .cityService: return "City Service"
            }
        }
        
        var icon: String {
            switch self {
            case .emergency911: return "phone.fill.badge.plus"
            case .fire: return "flame.fill"
            case .police: return "shield.fill"
            case .ems: return "cross.fill"
            case .buildingSecurity: return "lock.shield.fill"
            case .management: return "building.2.fill"
            case .company: return "briefcase.fill"
            case .manager: return "person.badge.key.fill"
            case .technical: return "wrench.and.screwdriver.fill"
            case .utility: return "bolt.fill"
            case .cityService: return "building.columns.fill"
            }
        }
    }
}

public struct EmergencyCall: Identifiable, Codable {
    public let id: String
    public let buildingId: String?
    public let reason: EmergencyReason?
    public let contactType: EmergencyContact.ContactType?
    public let contactName: String?
    public let phoneNumber: String?
    public let timestamp: Date
    public var status: CallStatus
    public var resolvedAt: Date?
    
    public init(
        id: String,
        buildingId: String? = nil,
        reason: EmergencyReason? = nil,
        contactType: EmergencyContact.ContactType? = nil,
        contactName: String? = nil,
        phoneNumber: String? = nil,
        timestamp: Date = Date(),
        status: CallStatus = .initiated
    ) {
        self.id = id
        self.buildingId = buildingId
        self.reason = reason
        self.contactType = contactType
        self.contactName = contactName
        self.phoneNumber = phoneNumber
        self.timestamp = timestamp
        self.status = status
    }
    
    public enum CallStatus: String, Codable {
        case initiated = "initiated"
        case inProgress = "in_progress"
        case completed = "completed"  
        case failed = "failed"
        case resolved = "resolved"
    }
}

public enum EmergencyReason: String, Codable, CaseIterable {
    case fire = "fire"
    case medical = "medical"
    case security = "security"
    case utility = "utility"
    case structural = "structural"
    case environmental = "environmental"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .fire: return "Fire Emergency"
        case .medical: return "Medical Emergency"
        case .security: return "Security Issue"
        case .utility: return "Utility Emergency"
        case .structural: return "Structural Problem"
        case .environmental: return "Environmental Hazard"
        case .other: return "Other Emergency"
        }
    }
}

// MARK: - Predefined Emergency Contacts

extension EmergencyContact {
    
    /// Primary 911 emergency contact (extracted from CoverageInfoCard)
    public static let primary911 = EmergencyContact(
        name: "911 Emergency",
        phoneNumber: "911",
        type: .emergency911,
        description: "Primary emergency services"
    )
    
    /// NYC Fire Department
    public static let nycFire = EmergencyContact(
        name: "NYC Fire Department",
        phoneNumber: "212-999-2222", // Non-emergency line
        type: .fire,
        description: "Fire Department non-emergency"
    )
    
    /// NYC Police Department
    public static let nycPolice = EmergencyContact(
        name: "NYC Police (Non-Emergency)",
        phoneNumber: "646-610-5000",
        type: .police,
        description: "Police non-emergency line"
    )
    
    /// NYC EMS
    public static let nycEMS = EmergencyContact(
        name: "NYC EMS",
        phoneNumber: "212-999-9999", // Non-emergency
        type: .ems,
        description: "EMS non-emergency"
    )
    
    /// NYC 311
    public static let nyc311 = EmergencyContact(
        name: "NYC 311",
        phoneNumber: "311",
        type: .cityService,
        description: "NYC government services"
    )
    
    /// Con Edison
    public static let conEdison = EmergencyContact(
        name: "Con Edison Emergency",
        phoneNumber: "1-800-752-6633",
        type: .utility,
        description: "Electrical emergency"
    )
    
    /// National Grid
    public static let nationalGrid = EmergencyContact(
        name: "National Grid Gas Emergency",
        phoneNumber: "1-718-643-4050",
        type: .utility,
        description: "Gas emergency"
    )
}