//
//  CyntientOpsDesign.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Removed duplicate Color init(hex:) extension
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Animation naming conflicts resolved
//  ✅ FIXED: Color initialization ambiguities resolved
//  ✅ FIXED: Type annotations added for gradient arrays
//  ✅ ENHANCED: Aligned with v6.0 three-dashboard system
//  ✅ INTEGRATED: Actor-compatible design patterns
//  ✅ ADDED: Centralized color system for all CoreTypes enums
//  ✅ MERGED: Incorporated utilities from ModelColorsExtensions
//  ✅ UPDATED: Dark Elegance theme implementation
//  ✅ ADDED: Dashboard gradients for all views
//  ✅ REMOVED: Placeholder CoreTypes enum - now uses actual CoreTypes from Models
//

import SwiftUI

// MARK: - Design System
enum CyntientOpsDesign {
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Card spacing
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 24
        
        // Navigation
        static let navBarHeight: CGFloat = 60
        static let tabBarHeight: CGFloat = 80
        
        // Dashboard-specific spacing (NEW for v6.0)
        static let dashboardSectionSpacing: CGFloat = 32
        static let propertyCardSpacing: CGFloat = 16
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 9999
        
        // PropertyCard specific (NEW for v6.0)
        static let propertyCard: CGFloat = 16
        static let glassCard: CGFloat = 20
    }
    
    // MARK: - Shadows (Updated for Dark Theme)
    enum Shadow {
        static let sm = ShadowStyle(radius: 5, x: 0, y: 2, color: .black.opacity(0.3))
        static let md = ShadowStyle(radius: 10, x: 0, y: 5, color: .black.opacity(0.3))
        static let lg = ShadowStyle(radius: 20, x: 0, y: 10, color: .black.opacity(0.3))
        static let xl = ShadowStyle(radius: 30, x: 0, y: 15, color: .black.opacity(0.3))
        
        // PropertyCard shadows (NEW for v6.0)
        static let propertyCard = ShadowStyle(radius: 8, x: 0, y: 4, color: .black.opacity(0.3))
        static let glassCard = ShadowStyle(radius: 12, x: 0, y: 6, color: .black.opacity(0.3))
        
        struct ShadowStyle {
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
            let color: Color
        }
    }
    
    // MARK: - Typography
    enum Typography {
        // Headings
        static let largeTitle = FontStyle(size: 34, weight: .bold, design: .rounded)
        static let title = FontStyle(size: 28, weight: .bold, design: .rounded)
        static let title2 = FontStyle(size: 22, weight: .semibold, design: .rounded)
        static let title3 = FontStyle(size: 20, weight: .semibold, design: .rounded)
        
        // Body
        static let headline = FontStyle(size: 17, weight: .semibold, design: .rounded)
        static let body = FontStyle(size: 17, weight: .regular, design: .rounded)
        static let callout = FontStyle(size: 16, weight: .regular, design: .rounded)
        static let subheadline = FontStyle(size: 15, weight: .regular, design: .rounded)
        static let footnote = FontStyle(size: 13, weight: .regular, design: .rounded)
        
        // Captions
        static let caption = FontStyle(size: 12, weight: .regular, design: .rounded)
        static let caption2 = FontStyle(size: 11, weight: .regular, design: .rounded)
        
        // Dashboard-specific typography (NEW for v6.0)
        static let dashboardTitle = FontStyle(size: 24, weight: .bold, design: .rounded)
        static let propertyCardTitle = FontStyle(size: 16, weight: .semibold, design: .rounded)
        static let metricsValue = FontStyle(size: 20, weight: .bold, design: .rounded)
        static let metricsLabel = FontStyle(size: 12, weight: .medium, design: .rounded)
        
        struct FontStyle {
            let size: CGFloat
            let weight: Font.Weight
            let design: Font.Design
            
            var font: Font {
                Font.system(size: size, weight: weight, design: design)
            }
        }
    }
    
    // MARK: - Animations (FIXED naming conflict)
    enum Animations {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.4)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.7)
        
        // PropertyCard animations (NEW for v6.0)
        static let propertyCardHover: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.6)
        static let dashboardTransition: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)
        static let metricsUpdate: SwiftUI.Animation = .easeInOut(duration: 0.5)
    }
    
    // MARK: - Blur
    enum Blur {
        static let ultraLight: CGFloat = 10
        static let light: CGFloat = 20
        static let medium: CGFloat = 30
        static let heavy: CGFloat = 40
        static let ultraHeavy: CGFloat = 50
        
        // Dashboard-specific blur (NEW for v6.0)
        static let dashboardBackground: CGFloat = 25
        static let propertyCard: CGFloat = 15
    }
    
    // MARK: - Glass Properties (Updated for Dark Theme)
    enum Glass {
        static let backgroundOpacity: Double = 0.02    // Very subtle for dark theme
        static let borderOpacity: Double = 0.05        // Barely visible
        static let gradientOpacity: Double = 0.03      // Subtle highlight
        static let shadowOpacity: Double = 0.3         // Deeper shadows
        
        // Component-specific
        static let cardBackgroundOpacity: Double = 0.03
        static let panelBackgroundOpacity: Double = 0.95
        static let overlayBackgroundOpacity: Double = 0.98
        static let headerOpacity: Double = 0.9
    }
    
    // MARK: - Dashboard Gradients (NEW for v6.0)
    enum DashboardGradients {
        // Main background gradient
        static let backgroundGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 10/255, green: 10/255, blue: 10/255),  // baseBackground
                Color(red: 15/255, green: 15/255, blue: 15/255)   // cardBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Role-specific gradients - Fixed with explicit type annotations
        static let workerGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 31/255, green: 41/255, blue: 55/255),   // gray-800
                Color(red: 55/255, green: 65/255, blue: 81/255)    // gray-700
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let adminGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 49/255, green: 46/255, blue: 129/255),  // indigo-900
                Color(red: 76/255, green: 29/255, blue: 149/255)   // purple-900
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let clientGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 20/255, green: 83/255, blue: 45/255),   // green-900
                Color(red: 22/255, green: 101/255, blue: 52/255)   // green-800
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Glass effect gradients
        static let glassOverlay: LinearGradient = LinearGradient(
            colors: [
                Color.white.opacity(0.05),
                Color.white.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Status gradients - Fixed with explicit Color types
        static let successGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 16/255, green: 185/255, blue: 129/255),
                Color(red: 16/255, green: 185/255, blue: 129/255).opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warningGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 245/255, green: 158/255, blue: 11/255),
                Color(red: 245/255, green: 158/255, blue: 11/255).opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let criticalGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 239/255, green: 68/255, blue: 68/255),
                Color(red: 239/255, green: 68/255, blue: 68/255).opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let infoGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 14/255, green: 165/255, blue: 233/255),
                Color(red: 14/255, green: 165/255, blue: 233/255).opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Subtle card gradients
        static let cardGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 15/255, green: 15/255, blue: 15/255),
                Color(red: 15/255, green: 15/255, blue: 15/255).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Shine effect for interactive elements
        static let shineGradient: LinearGradient = LinearGradient(
            colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.1),
                Color.white.opacity(0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Hero card gradients (matching role colors) - Fixed with arrays
        static let workerHeroGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 31/255, green: 41/255, blue: 55/255),   // gray-800
                Color(red: 55/255, green: 65/255, blue: 81/255)    // gray-700
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let adminHeroGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 49/255, green: 46/255, blue: 129/255),  // indigo-900
                Color(red: 76/255, green: 29/255, blue: 149/255)   // purple-900
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let clientHeroGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 20/255, green: 83/255, blue: 45/255),   // green-900
                Color(red: 22/255, green: 101/255, blue: 52/255)   // green-800
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Progress bar gradients
        static let progressGradient: LinearGradient = LinearGradient(
            colors: [
                Color(red: 16/255, green: 185/255, blue: 129/255),
                Color(red: 52/255, green: 211/255, blue: 153/255)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        // Overlay gradients for depth
        static let depthGradient: LinearGradient = LinearGradient(
            colors: [
                Color.black.opacity(0.4),
                Color.black.opacity(0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Dashboard Colors (DARK ELEGANCE THEME)
    enum DashboardColors {
        // Base colors - Using RGB values to avoid hex ambiguity
        static let baseBackground = Color(red: 10/255, green: 10/255, blue: 10/255)       // #0a0a0a
        static let cardBackground = Color(red: 15/255, green: 15/255, blue: 15/255)       // #0f0f0f
        static let glassOverlay = Color.white.opacity(0.05)
        static let borderSubtle = Color.white.opacity(0.05)
        
        // Action colors
        static let primaryAction = Color(red: 16/255, green: 185/255, blue: 129/255)      // #10b981 Success green
        static let secondaryAction = Color(red: 14/255, green: 165/255, blue: 233/255)    // #0ea5e9 Sky blue
        static let tertiaryAction = Color(red: 139/255, green: 92/255, blue: 246/255)     // #8b5cf6 Purple
        
        // Status colors
        static let success = Color(red: 16/255, green: 185/255, blue: 129/255)            // #10b981
        static let warning = Color(red: 245/255, green: 158/255, blue: 11/255)            // #f59e0b
        static let critical = Color(red: 239/255, green: 68/255, blue: 68/255)            // #ef4444
        static let info = Color(red: 14/255, green: 165/255, blue: 233/255)               // #0ea5e9
        static let inactive = Color.white.opacity(0.3)
        
        // Text colors (Dark theme optimized)
        static let primaryText = Color.white.opacity(0.9)
        static let secondaryText = Color.white.opacity(0.7)
        static let tertiaryText = Color.white.opacity(0.5)
        
        // Worker Dashboard specific
        static let workerPrimary = Color(red: 16/255, green: 185/255, blue: 129/255)      // #10b981 Green
        static let workerSecondary = Color(red: 14/255, green: 165/255, blue: 233/255)    // #0ea5e9 Blue
        static let workerAccent = Color(red: 6/255, green: 182/255, blue: 212/255)        // #06b6d4 Cyan
        static let workerHeroGradient: [Color] = [
            Color(red: 31/255, green: 41/255, blue: 55/255),   // gray-800
            Color(red: 55/255, green: 65/255, blue: 81/255)    // gray-700
        ]
        
        // Admin Dashboard specific
        static let adminPrimary = Color(red: 139/255, green: 92/255, blue: 246/255)       // #8b5cf6 Purple
        static let adminSecondary = Color(red: 168/255, green: 85/255, blue: 247/255)     // #a855f7 Light purple
        static let adminAccent = Color(red: 236/255, green: 72/255, blue: 153/255)        // #ec4899 Pink
        static let adminHeroGradient: [Color] = [
            Color(red: 49/255, green: 46/255, blue: 129/255),  // indigo-900
            Color(red: 76/255, green: 29/255, blue: 149/255)   // purple-900
        ]
        
        // Client Dashboard specific
        static let clientPrimary = Color(red: 16/255, green: 185/255, blue: 129/255)      // #10b981 Green
        static let clientSecondary = Color(red: 52/255, green: 211/255, blue: 153/255)    // #34d399 Light green
        static let clientAccent = Color(red: 110/255, green: 231/255, blue: 183/255)      // #6ee7b7 Mint
        static let clientHeroGradient: [Color] = [
            Color(red: 20/255, green: 83/255, blue: 45/255),   // green-900
            Color(red: 22/255, green: 101/255, blue: 52/255)   // green-800
        ]
        
        // Status Colors (Updated for dark theme)
        static let compliant = Color(red: 16/255, green: 185/255, blue: 129/255)          // #10b981
        static let pending = Color(red: 245/255, green: 158/255, blue: 11/255)            // #f59e0b
        static let violation = Color(red: 239/255, green: 68/255, blue: 68/255)           // #ef4444
    }
    
    // MARK: - Enum Colors (Updated for Dark Theme - Now uses actual CoreTypes)
    enum EnumColors {
        
        // MARK: AI Priority Colors
        static func aiPriority(_ priority: CoreTypes.AIPriority) -> Color {
            switch priority {
            case .low: return DashboardColors.success
            case .medium: return Color(red: 251/255, green: 191/255, blue: 36/255)    // Amber
            case .high: return DashboardColors.warning
            case .critical: return DashboardColors.critical
            }
        }
        
        // MARK: Insight Category Colors
        static func insightCategory(_ category: CoreTypes.InsightCategory) -> Color {
            switch category {
            case .efficiency: return DashboardColors.info
            case .cost: return DashboardColors.success
            case .safety: return DashboardColors.critical
            case .compliance: return DashboardColors.warning
            case .quality: return DashboardColors.tertiaryAction
            case .operations: return Color.white.opacity(0.6)
            case .maintenance: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .routing: return DashboardColors.info
            case .weather: return Color(red: 135/255, green: 206/255, blue: 235/255)
            case .performance: return DashboardColors.success
            }
        }
        
        // MARK: Task Status Colors
        static func taskStatus(_ status: CoreTypes.TaskStatus) -> Color {
            switch status {
            case .pending: return DashboardColors.inactive
            case .inProgress: return DashboardColors.info
            case .completed: return DashboardColors.success
            case .overdue: return DashboardColors.critical
            case .cancelled: return DashboardColors.inactive
            case .paused: return DashboardColors.warning
            case .waiting: return Color(red: 251/255, green: 191/255, blue: 36/255)
            }
        }
        
        // MARK: Task Urgency Colors
        static func taskUrgency(_ urgency: CoreTypes.TaskUrgency) -> Color {
            switch urgency {
            case .low: return DashboardColors.success
            case .medium: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .normal: return Color.white.opacity(0.6)
            case .high: return DashboardColors.warning
            case .urgent: return DashboardColors.tertiaryAction
            case .critical: return DashboardColors.critical
            case .emergency: return DashboardColors.critical
            }
        }
        
        // MARK: Compliance Status Colors
        static func complianceStatus(_ status: CoreTypes.ComplianceStatus) -> Color {
            switch status {
            case .compliant: return DashboardColors.compliant
            case .warning: return DashboardColors.warning
            case .violation, .nonCompliant: return DashboardColors.violation
            case .pending, .needsReview: return DashboardColors.pending
            case .atRisk: return DashboardColors.warning
            case .open: return DashboardColors.critical
            case .inProgress: return DashboardColors.info
            case .resolved: return DashboardColors.info
            }
        }
        
        // MARK: Compliance Severity Colors
        static func complianceSeverity(_ severity: CoreTypes.ComplianceSeverity) -> Color {
            switch severity {
            case .low: return DashboardColors.success
            case .medium: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .high: return DashboardColors.warning
            case .critical: return DashboardColors.critical
            }
        }
        
        // MARK: Compliance Issue Type Colors
        static func complianceIssueType(_ type: CoreTypes.ComplianceIssueType) -> Color {
            switch type {
            case .safety: return DashboardColors.critical
            case .environmental: return DashboardColors.success
            case .regulatory: return DashboardColors.info
            case .financial: return DashboardColors.warning
            case .operational: return DashboardColors.tertiaryAction
            case .documentation: return DashboardColors.inactive
            }
        }
        
        // MARK: Worker Status Colors
        static func workerStatus(_ status: CoreTypes.WorkerStatus) -> Color {
            switch status {
            case .available: return DashboardColors.success
            case .clockedIn: return DashboardColors.info
            case .onBreak: return DashboardColors.warning
            case .offline: return DashboardColors.inactive
            }
        }
        
        // MARK: User Role Colors
        static func userRole(_ role: CoreTypes.UserRole) -> Color {
            switch role {
            case .admin: return DashboardColors.adminPrimary
            case .manager: return DashboardColors.warning
            case .worker: return DashboardColors.workerPrimary
            case .client: return DashboardColors.clientPrimary
            }
        }
        
        // MARK: Building Type Colors
        static func buildingType(_ type: CoreTypes.BuildingType) -> Color {
            switch type {
            case .office: return DashboardColors.info
            case .residential: return DashboardColors.success
            case .retail: return DashboardColors.tertiaryAction
            case .industrial: return DashboardColors.warning
            case .warehouse: return Color(red: 146/255, green: 64/255, blue: 14/255)  // Brown
            case .medical: return DashboardColors.critical
            case .educational: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .mixed: return DashboardColors.inactive
            }
        }
        
        // MARK: Dashboard Sync Status Colors
        static func dashboardSyncStatus(_ status: CoreTypes.DashboardSyncStatus) -> Color {
            switch status {
            case .synced: return DashboardColors.success
            case .syncing: return DashboardColors.info
            case .failed: return DashboardColors.critical
            case .offline: return DashboardColors.inactive
            case .error: return DashboardColors.critical
            }
        }
        
        // MARK: Verification Status Colors
        static func verificationStatus(_ status: CoreTypes.VerificationStatus) -> Color {
            switch status {
            case .pending: return DashboardColors.warning
            case .verified: return DashboardColors.success
            case .rejected: return DashboardColors.critical
            case .notRequired: return DashboardColors.inactive
            case .needsReview: return DashboardColors.warning
            }
        }
        
        // MARK: Outdoor Work Risk Colors
        static func outdoorWorkRisk(_ risk: CoreTypes.OutdoorWorkRisk) -> Color {
            switch risk {
            case .low: return DashboardColors.success
            case .medium: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .moderate: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .high: return DashboardColors.warning
            case .extreme: return DashboardColors.critical
            }
        }
        
        // MARK: Trend Direction Colors
        static func trendDirection(_ direction: CoreTypes.TrendDirection) -> Color {
            switch direction {
            case .up, .improving: return DashboardColors.success
            case .down, .declining: return DashboardColors.critical
            case .stable: return DashboardColors.info
            case .unknown: return DashboardColors.inactive
            }
        }
        
        // MARK: Skill Level Colors
        static func skillLevel(_ level: CoreTypes.SkillLevel) -> Color {
            switch level {
            case .beginner: return DashboardColors.critical
            case .intermediate: return DashboardColors.warning
            case .advanced: return Color(red: 251/255, green: 191/255, blue: 36/255)
            case .expert: return DashboardColors.success
            }
        }
        
        // MARK: Restock Status Colors
        static func restockStatus(_ status: CoreTypes.RestockStatus) -> Color {
            switch status {
            case .inStock: return DashboardColors.success
            case .lowStock: return DashboardColors.warning
            case .outOfStock: return DashboardColors.critical
            case .ordered: return DashboardColors.info
            }
        }
        
        // MARK: Data Health Status Colors
        static func dataHealthStatus(_ status: CoreTypes.DataHealthStatus) -> Color {
            switch status {
            case .healthy: return DashboardColors.success
            case .warning: return DashboardColors.warning
            case .critical: return DashboardColors.critical
            case .error: return DashboardColors.critical
            case .unknown: return DashboardColors.inactive
            }
        }
        
        // MARK: - Generic Helpers (Merged from ModelColorsExtensions)
        
        /// Generic status color helper for string-based statuses
        static func genericStatusColor(for status: String) -> Color {
            switch status.lowercased() {
            case "verified", "completed", "success", "compliant": return DashboardColors.success
            case "pending", "in progress", "processing": return DashboardColors.warning
            case "failed", "error", "rejected": return DashboardColors.critical
            case "warning", "caution": return Color(red: 251/255, green: 191/255, blue: 36/255)
            default: return DashboardColors.inactive
            }
        }
        
        /// Generic category color helper for string-based categories
        static func genericCategoryColor(for category: String) -> Color {
            switch category.lowercased() {
            case "maintenance": return DashboardColors.warning
            case "cleaning": return DashboardColors.info
            case "repair": return DashboardColors.critical
            case "inspection": return DashboardColors.tertiaryAction
            case "emergency": return DashboardColors.critical
            case "safety": return Color(red: 251/255, green: 191/255, blue: 36/255)
            case "equipment": return Color(red: 99/255, green: 102/255, blue: 241/255)  // Indigo
            case "supplies": return DashboardColors.success
            case "sanitation": return DashboardColors.workerAccent
            default: return DashboardColors.inactive
            }
        }
    }
    
    // MARK: - Icon Helpers (Merged from ModelColorsExtensions)
    enum Icons {
        
        /// Returns SF Symbol icon for status strings
        static func statusIcon(for status: String) -> String {
            switch status.lowercased() {
            case "verified", "completed", "success": return "checkmark.circle.fill"
            case "pending", "processing": return "clock.fill"
            case "failed", "error": return "xmark.circle.fill"
            case "in progress": return "gear"
            case "warning": return "exclamationmark.triangle.fill"
            case "rejected": return "xmark.octagon.fill"
            default: return "questionmark.circle"
            }
        }
        
        /// Returns SF Symbol icon for category strings
        static func categoryIcon(for category: String) -> String {
            switch category.lowercased() {
            case "maintenance": return "wrench.and.screwdriver"
            case "cleaning": return "sparkles"
            case "repair": return "hammer"
            case "inspection": return "magnifyingglass"
            case "emergency": return "exclamationmark.triangle.fill"
            case "safety": return "shield.fill"
            case "equipment": return "gear"
            case "supplies": return "shippingbox"
            case "sanitation": return "trash.fill"
            default: return "square.grid.3x3"
            }
        }
        
        /// Returns SF Symbol icon for inventory categories
        static func inventoryIcon(for category: CoreTypes.InventoryCategory) -> String {
            switch category {
            case .cleaning: return "sparkles"
            case .equipment: return "wrench.fill"
            case .building: return "house.fill"
            case .sanitation: return "trash.fill"
            case .office: return "briefcase.fill"
            case .seasonal: return "snowflake"
            case .supplies: return "shippingbox"
            case .maintenance: return "hammer"
            case .electrical: return "bolt.circle"
            case .safety: return "shield.fill"
            case .tools: return "wrench.and.screwdriver"
            case .materials: return "cube.box"
            case .plumbing: return "drop.circle"
            case .general: return "square.grid.2x2"
            case .other: return "folder"
            }
        }
    }
    
    // MARK: - Metrics Display (NEW for v6.0)
    enum MetricsDisplay {
        static let progressBarHeight: CGFloat = 6
        static let progressBarCornerRadius: CGFloat = 3
        static let statusIndicatorSize: CGFloat = 8
        static let trendArrowSize: CGFloat = 12
    }
}

// MARK: - Color Hex Extension
// REMOVED: Duplicate init(hex:) extension for Color
// This is likely already defined elsewhere in the project

// MARK: - String Extensions (Merged from ModelColorsExtensions)
extension String {
    /// Returns color for string-based status
    var statusColor: Color {
        CyntientOpsDesign.EnumColors.genericStatusColor(for: self)
    }
    
    /// Returns SF Symbol icon for status strings
    var statusIcon: String {
        CyntientOpsDesign.Icons.statusIcon(for: self)
    }
    
    /// Returns SF Symbol icon for category strings
    var categoryIcon: String {
        CyntientOpsDesign.Icons.categoryIcon(for: self)
    }
    
    /// Returns color for string-based category
    var categoryColor: Color {
        CyntientOpsDesign.EnumColors.genericCategoryColor(for: self)
    }
}

// MARK: - View Extensions (ENHANCED)
extension View {
    // Typography
    func francoTypography(_ style: CyntientOpsDesign.Typography.FontStyle) -> some View {
        self.font(style.font)
    }
    
    // Spacing
    func francoPadding(_ spacing: CGFloat = CyntientOpsDesign.Spacing.md) -> some View {
        self.padding(spacing)
    }
    
    // Card padding
    func francoCardPadding() -> some View {
        self.padding(CyntientOpsDesign.Spacing.cardPadding)
    }
    
    // Property card padding (NEW for v6.0)
    func francoPropertyCardPadding() -> some View {
        self.padding(CyntientOpsDesign.Spacing.propertyCardSpacing)
    }
    
    // Shadow
    func francoShadow(_ shadow: CyntientOpsDesign.Shadow.ShadowStyle = CyntientOpsDesign.Shadow.md) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    // Corner radius
    func francoCornerRadius(_ radius: CGFloat = CyntientOpsDesign.CornerRadius.lg) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
    
    // Glass background - Updated for Dark Theme
    func francoGlassBackground(
        cornerRadius: CGFloat = CyntientOpsDesign.CornerRadius.xl,
        opacity: Double = CyntientOpsDesign.Glass.backgroundOpacity
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
        .francoShadow()
    }
    
    // Dark card background
    func francoDarkCardBackground(
        cornerRadius: CGFloat = CyntientOpsDesign.CornerRadius.lg
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: CyntientOpsDesign.DashboardColors.workerHeroGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
        .francoShadow()
    }
    
    // PropertyCard glass background (NEW for v6.0)
    func francoPropertyCardBackground() -> some View {
        self.francoGlassBackground(
            cornerRadius: CyntientOpsDesign.CornerRadius.propertyCard,
            opacity: CyntientOpsDesign.Glass.cardBackgroundOpacity
        )
    }
    
    // Dashboard role-specific styling (NEW for v6.0)
    func francoDashboardStyle(for role: DashboardRole) -> some View {
        self.foregroundColor(role.primaryColor)
    }
}

// MARK: - Animation Modifiers (FIXED)
extension View {
    func francoAnimation<V: Equatable>(_ animation: SwiftUI.Animation = CyntientOpsDesign.Animations.standard, value: V) -> some View {
        self.animation(animation, value: value)
    }
    
    // Property card hover animation (NEW for v6.0)
    func francoPropertyCardAnimation<V: Equatable>(value: V) -> some View {
        self.animation(CyntientOpsDesign.Animations.propertyCardHover, value: value)
    }
    
    // Dashboard transition animation (NEW for v6.0)
    func francoDashboardTransition<V: Equatable>(value: V) -> some View {
        self.animation(CyntientOpsDesign.Animations.dashboardTransition, value: value)
    }
}

// MARK: - Dashboard Role Support (Updated for Dark Theme)
enum DashboardRole: String, CaseIterable {
    case worker = "worker"
    case admin = "admin"
    case client = "client"
    
    var displayName: String {
        switch self {
        case .worker: return "Worker"
        case .admin: return "Admin"
        case .client: return "Client"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .worker: return CyntientOpsDesign.DashboardColors.workerPrimary
        case .admin: return CyntientOpsDesign.DashboardColors.adminPrimary
        case .client: return CyntientOpsDesign.DashboardColors.clientPrimary
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .worker: return CyntientOpsDesign.DashboardColors.workerSecondary
        case .admin: return CyntientOpsDesign.DashboardColors.adminSecondary
        case .client: return CyntientOpsDesign.DashboardColors.clientSecondary
        }
    }
    
    var accentColor: Color {
        switch self {
        case .worker: return CyntientOpsDesign.DashboardColors.workerAccent
        case .admin: return CyntientOpsDesign.DashboardColors.adminAccent
        case .client: return CyntientOpsDesign.DashboardColors.clientAccent
        }
    }
    
    var heroGradient: [Color] {
        switch self {
        case .worker: return CyntientOpsDesign.DashboardColors.workerHeroGradient
        case .admin: return CyntientOpsDesign.DashboardColors.adminHeroGradient
        case .client: return CyntientOpsDesign.DashboardColors.clientHeroGradient
        }
    }
}

// MARK: - Safe Area Helper (UNCHANGED)
struct SafeAreaHelper: ViewModifier {
    let edges: Edge.Set
    
    func body(content: Content) -> some View {
        content
            .padding(.top, edges.contains(.top) ? safeAreaInsets.top : 0)
            .padding(.bottom, edges.contains(.bottom) ? safeAreaInsets.bottom : 0)
            .padding(.leading, edges.contains(.leading) ? safeAreaInsets.leading : 0)
            .padding(.trailing, edges.contains(.trailing) ? safeAreaInsets.trailing : 0)
    }
    
    private var safeAreaInsets: EdgeInsets {
        let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
        let insets = window?.safeAreaInsets ?? UIEdgeInsets()
        return insets.toEdgeInsets()
    }
}

extension UIEdgeInsets {
    func toEdgeInsets() -> EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension View {
    func francoSafeArea(_ edges: Edge.Set = .all) -> some View {
        self.modifier(SafeAreaHelper(edges: edges))
    }
}

// MARK: - Loading State (Updated for Dark Theme)
struct FrancoLoadingView: View {
    let message: String
    let role: DashboardRole?
    
    init(message: String = "Loading...", role: DashboardRole? = nil) {
        self.message = message
        self.role = role
    }
    
    var body: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: role?.primaryColor ?? CyntientOpsDesign.DashboardColors.primaryText))
                .scaleEffect(1.2)
            
            Text(message)
                .francoTypography(CyntientOpsDesign.Typography.body)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .francoCardPadding()
        .francoGlassBackground()
    }
}

// MARK: - Empty State (Updated for Dark Theme)
struct FrancoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    let role: DashboardRole?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil,
        role: DashboardRole? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
        self.role = role
    }
    
    var body: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor((role?.primaryColor ?? CyntientOpsDesign.DashboardColors.primaryText).opacity(0.6))
            
            VStack(spacing: CyntientOpsDesign.Spacing.sm) {
                Text(title)
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(message)
                    .francoTypography(CyntientOpsDesign.Typography.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle) {
                    action()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(role?.primaryColor ?? CyntientOpsDesign.DashboardColors.primaryAction)
                .cornerRadius(8)
                .padding(.top, CyntientOpsDesign.Spacing.sm)
            }
        }
        .francoCardPadding()
        .frame(maxWidth: 400)
    }
}

// MARK: - Metrics Display Components (Updated for Dark Theme)
struct FrancoMetricsProgress: View {
    let value: Double
    let role: DashboardRole?
    
    var body: some View {
        ProgressView(value: value)
            .progressViewStyle(LinearProgressViewStyle(tint: role?.primaryColor ?? CyntientOpsDesign.DashboardColors.primaryAction))
            .frame(height: CyntientOpsDesign.MetricsDisplay.progressBarHeight)
            .cornerRadius(CyntientOpsDesign.MetricsDisplay.progressBarCornerRadius)
    }
}

struct FrancoStatusIndicator: View {
    let isActive: Bool
    let role: DashboardRole?
    
    var body: some View {
        Circle()
            .fill(isActive ? (role?.primaryColor ?? CyntientOpsDesign.DashboardColors.success) : CyntientOpsDesign.DashboardColors.inactive)
            .frame(
                width: CyntientOpsDesign.MetricsDisplay.statusIndicatorSize,
                height: CyntientOpsDesign.MetricsDisplay.statusIndicatorSize
            )
    }
}

// MARK: - Preview Helpers (Updated for Dark Theme)
#Preview("Loading States") {
    VStack(spacing: 20) {
        FrancoLoadingView(message: "Loading worker data...", role: .worker)
        FrancoLoadingView(message: "Loading admin panel...", role: .admin)
        FrancoLoadingView(message: "Loading client reports...", role: .client)
    }
    .padding()
    .background(CyntientOpsDesign.DashboardColors.baseBackground)
}

#Preview("Empty States") {
    VStack(spacing: 20) {
        FrancoEmptyState(
            icon: "building.2",
            title: "No Buildings Assigned",
            message: "You don't have any buildings assigned yet.",
            action: { print("Refresh tapped") },
            actionTitle: "Refresh",
            role: .worker
        )
    }
    .padding()
    .background(CyntientOpsDesign.DashboardColors.baseBackground)
}

#Preview("Metrics Components") {
    VStack(spacing: 20) {
        FrancoMetricsProgress(value: 0.75, role: .worker)
        FrancoMetricsProgress(value: 0.45, role: .admin)
        FrancoMetricsProgress(value: 0.92, role: .client)
        
        HStack(spacing: 16) {
            FrancoStatusIndicator(isActive: true, role: .worker)
            FrancoStatusIndicator(isActive: false, role: .admin)
            FrancoStatusIndicator(isActive: true, role: .client)
        }
    }
    .padding()
    .background(CyntientOpsDesign.DashboardColors.baseBackground)
}

#Preview("Color Swatches") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            Text("Dark Elegance Color Palette")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Group {
                Text("Base Colors").font(.headline)
                HStack(spacing: 16) {
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.baseBackground, label: "Base")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.cardBackground, label: "Card")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.glassOverlay, label: "Glass")
                }
                
                Text("Action Colors").font(.headline).padding(.top)
                HStack(spacing: 16) {
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.primaryAction, label: "Primary")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.secondaryAction, label: "Secondary")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.tertiaryAction, label: "Tertiary")
                }
                
                Text("Status Colors").font(.headline).padding(.top)
                HStack(spacing: 16) {
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.success, label: "Success")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.warning, label: "Warning")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.critical, label: "Critical")
                    ColorSwatch(color: CyntientOpsDesign.DashboardColors.info, label: "Info")
                }
            }
        }
        .padding()
    }
    .background(CyntientOpsDesign.DashboardColors.baseBackground)
}

// Helper view for color preview
struct ColorSwatch: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(CyntientOpsDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
            
            Text(label)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
    }
}
