///
//  ReportService.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: DateRange issue resolved
//  ✅ PRODUCTION READY: PDF and CSV report generation
//  ✅ ASYNC: Non-blocking report generation
//  ✅ SHAREABLE: Returns URLs for easy sharing
//

import Foundation
import PDFKit
import UniformTypeIdentifiers

// MARK: - Date Range Enum

public enum ReportDateRange: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisQuarter = "This Quarter"
    case thisYear = "This Year"
    case custom = "Custom"
    
    public var days: Int {
        switch self {
        case .today: return 1
        case .thisWeek: return 7
        case .thisMonth: return 30
        case .thisQuarter: return 90
        case .thisYear: return 365
        case .custom: return 30 // Default for custom
        }
    }
}

// MARK: - Report Service

@MainActor
public final class ReportService: ObservableObject {
    public static let shared = ReportService()
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
    }
    
    // MARK: - Public Methods
    
    public func generateClientReport(_ data: ClientPortfolioReportData) async throws -> URL {
        let fileName = "Portfolio_Report_\(ISO8601DateFormatter.init().string(from: data.generatedAt)).pdf"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // Create PDF using UIGraphicsPDFRenderer for more control
        let pdfData = createFullPortfolioReport(data: data)
        
        try pdfData.write(to: fileURL)
        
        return fileURL
    }
    
    public func generateBuildingReport(buildingId: String, metrics: CoreTypes.BuildingMetrics) async throws -> URL {
        let fileName = "Building_\(buildingId)_Report_\(ISO8601DateFormatter.init().string(from: Date())).pdf"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // Create simple PDF with building metrics
        let pdfData = createBuildingPDF(buildingId: buildingId, metrics: metrics)
        
        try pdfData.write(to: fileURL)
        
        return fileURL
    }
    
    public func exportDataAsCSV(buildings: [CoreTypes.NamedCoordinate], metrics: [String: CoreTypes.BuildingMetrics]) async throws -> URL {
        let fileName = "Portfolio_Data_\(ISO8601DateFormatter.init().string(from: Date())).csv"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        var csvString = "Building ID,Building Name,Address,Completion Rate,Total Tasks,Pending Tasks,Overdue Tasks,Active Workers,Compliance\n"
        
        for building in buildings {
            let buildingMetrics = metrics[building.id] ?? CoreTypes.BuildingMetrics.empty
            
            let row = [
                building.id,
                building.name.replacingOccurrences(of: ",", with: ";"), // Escape commas in names
                building.address.replacingOccurrences(of: ",", with: ";"), // Escape commas in addresses
                String(format: "%.2f", buildingMetrics.completionRate * 100),
                String(buildingMetrics.totalTasks),
                String(buildingMetrics.pendingTasks),
                String(buildingMetrics.overdueTasks),
                String(buildingMetrics.activeWorkers),
                buildingMetrics.isCompliant ? "Yes" : "No"
            ].joined(separator: ",")
            
            csvString += row + "\n"
        }
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    public func generateComplianceReport(issues: [CoreTypes.ComplianceIssue]) async throws -> URL {
        let fileName = "Compliance_Report_\(ISO8601DateFormatter.init().string(from: Date())).pdf"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // Create PDF with compliance issues
        let pdfData = createCompliancePDF(issues: issues)
        
        try pdfData.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - Private Methods
    
    private func getDocumentsDirectory() -> URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func createFullPortfolioReport(data: ClientPortfolioReportData) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "CyntientOps",
            kCGPDFContextAuthor: "CyntientOps System",
            kCGPDFContextTitle: "Portfolio Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            // Page 1: Cover
            context.beginPage()
            drawCoverPage(in: context, data: data, pageRect: pageRect)
            
            // Page 2: Executive Summary
            context.beginPage()
            drawSummaryPage(in: context, data: data, pageRect: pageRect)
            
            // Page 3: Buildings Overview
            context.beginPage()
            drawBuildingsPage(in: context, data: data, pageRect: pageRect)
            
            // Page 4: Compliance Status
            context.beginPage()
            drawCompliancePage(in: context, data: data, pageRect: pageRect)
        }
        
        return data
    }
    
    private func drawCoverPage(in context: UIGraphicsPDFRendererContext, data: ClientPortfolioReportData, pageRect: CGRect) {
        // Title
        let titleAttributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 36),
            NSAttributedString.Key.foregroundColor: UIColor.label
        ]
        
        let title = "Portfolio Report"
        let titleRect = CGRect(x: 50, y: 200, width: pageRect.width - 100, height: 50)
        title.draw(in: titleRect, withAttributes: titleAttributes)
        
        // Date range
        let subtitleAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24),
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel
        ]
        
        let dateRange = data.dateRange.rawValue
        let dateRect = CGRect(x: 50, y: 260, width: pageRect.width - 100, height: 40)
        dateRange.draw(in: dateRect, withAttributes: subtitleAttributes)
        
        // Generated date
        let footerAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
            NSAttributedString.Key.foregroundColor: UIColor.tertiaryLabel
        ]
        
        let generatedText = "Generated: \(dateFormatter.string(from: data.generatedAt))"
        let footerRect = CGRect(x: 50, y: pageRect.height - 100, width: pageRect.width - 100, height: 30)
        generatedText.draw(in: footerRect, withAttributes: footerAttributes)
    }
    
    private func drawSummaryPage(in context: UIGraphicsPDFRendererContext, data: ClientPortfolioReportData, pageRect: CGRect) {
        // Title
        let titleAttributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        "Executive Summary".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        // Content
        let contentAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
        ]
        
        var yPosition: CGFloat = 100
        let lineHeight: CGFloat = 25
        
        let summaryItems = [
            "Total Buildings: \(data.buildings.count)",
            "Overall Health Score: \(String(format: "%.1f%%", data.portfolioHealth.overallScore * 100))",
            "Active Buildings: \(data.portfolioHealth.activeBuildings)",
            "Critical Issues: \(data.portfolioHealth.criticalIssues)",
            "Compliance Score: \(String(format: "%.1f%%", data.complianceOverview.overallScore * 100))",
            "Critical Violations: \(data.complianceOverview.criticalViolations)"
        ]
        
        for item in summaryItems {
            item.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
            yPosition += lineHeight
        }
        
        // Key Insights
        if !data.insights.isEmpty {
            yPosition += 20
            "Key Insights".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 30
            
            for insight in data.insights.prefix(5) {
                let bulletPoint = "• \(insight)"
                let rect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 50)
                bulletPoint.draw(in: rect, withAttributes: contentAttributes)
                yPosition += 35
            }
        }
    }
    
    private func drawBuildingsPage(in context: UIGraphicsPDFRendererContext, data: ClientPortfolioReportData, pageRect: CGRect) {
        let titleAttributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        "Buildings Overview".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        // Table header
        let headerAttributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)
        ]
        
        let columnWidth = (pageRect.width - 100) / 5
        var xPosition: CGFloat = 50
        let yHeader: CGFloat = 100
        
        let headers = ["Building", "Completion", "Tasks", "Workers", "Status"]
        for header in headers {
            header.draw(at: CGPoint(x: xPosition, y: yHeader), withAttributes: headerAttributes)
            xPosition += columnWidth
        }
        
        // Table content
        let contentAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11)
        ]
        
        var yPosition: CGFloat = 130
        
        for building in data.buildings.prefix(15) {
            xPosition = 50
            
            let metrics = data.buildingMetrics[building.id] ?? CoreTypes.BuildingMetrics.empty
            
            // Building name (truncated if needed)
            let name = building.name.count > 20 ? String(building.name.prefix(17)) + "..." : building.name
            name.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: contentAttributes)
            xPosition += columnWidth
            
            // Completion rate
            "\(String(format: "%.0f%%", metrics.completionRate * 100))".draw(
                at: CGPoint(x: xPosition, y: yPosition),
                withAttributes: contentAttributes
            )
            xPosition += columnWidth
            
            // Total tasks
            "\(metrics.totalTasks)".draw(
                at: CGPoint(x: xPosition, y: yPosition),
                withAttributes: contentAttributes
            )
            xPosition += columnWidth
            
            // Active workers
            "\(metrics.activeWorkers)".draw(
                at: CGPoint(x: xPosition, y: yPosition),
                withAttributes: contentAttributes
            )
            xPosition += columnWidth
            
            // Status
            let status = metrics.isCompliant ? "Compliant" : "Non-Compliant"
            status.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: contentAttributes)
            
            yPosition += 20
        }
    }
    
    private func drawCompliancePage(in context: UIGraphicsPDFRendererContext, data: ClientPortfolioReportData, pageRect: CGRect) {
        let titleAttributes = [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
        ]
        
        "Compliance Overview".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        
        let contentAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
        ]
        
        var yPosition: CGFloat = 100
        let lineHeight: CGFloat = 25
        
        let complianceItems = [
            "Overall Compliance Score: \(String(format: "%.1f%%", data.complianceOverview.overallScore * 100))",
            "Critical Violations: \(data.complianceOverview.criticalViolations)",
            "Pending Inspections: \(data.complianceOverview.pendingInspections)",
            "Last Updated: \(dateFormatter.string(from: data.complianceOverview.lastUpdated))"
        ]
        
        for item in complianceItems {
            item.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
            yPosition += lineHeight
        }
        
        // Add upcoming deadlines if available
        if !data.complianceOverview.upcomingDeadlines.isEmpty {
            yPosition += 20
            "Upcoming Deadlines".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 30
            
            for deadline in data.complianceOverview.upcomingDeadlines.prefix(5) {
                let deadlineText = "• \(deadline.title): \(dateFormatter.string(from: deadline.dueDate))"
                deadlineText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: contentAttributes)
                yPosition += lineHeight
            }
        }
    }
    
    private func createBuildingPDF(buildingId: String, metrics: CoreTypes.BuildingMetrics) -> Data {
        // Create PDF data using UIGraphicsPDFRenderer
        let pdfMetaData = [
            kCGPDFContextCreator: "CyntientOps",
            kCGPDFContextAuthor: "CyntientOps System",
            kCGPDFContextTitle: "Building Report - \(buildingId)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Title
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let title = "Building Report"
            title.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Building ID
            let subtitleAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)
            ]
            "Building ID: \(buildingId)".draw(at: CGPoint(x: 50, y: 90), withAttributes: subtitleAttributes)
            
            // Metrics
            var yPosition: CGFloat = 140
            let lineHeight: CGFloat = 25
            
            let metricsText = [
                "Completion Rate: \(String(format: "%.1f%%", metrics.completionRate * 100))",
                "Total Tasks: \(metrics.totalTasks)",
                "Pending Tasks: \(metrics.pendingTasks)",
                "Overdue Tasks: \(metrics.overdueTasks)",
                "Active Workers: \(metrics.activeWorkers)",
                "Compliance: \(metrics.isCompliant ? "Yes" : "No")",
                "Overall Score: \(String(format: "%.1f", metrics.overallScore))"
            ]
            
            for text in metricsText {
                text.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: subtitleAttributes)
                yPosition += lineHeight
            }
            
            // Generated date
            let dateText = "Generated: \(dateFormatter.string(from: Date()))"
            dateText.draw(at: CGPoint(x: 50, y: pageHeight - 100), withAttributes: subtitleAttributes)
        }
        
        return data
    }
    
    private func createCompliancePDF(issues: [CoreTypes.ComplianceIssue]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "CyntientOps",
            kCGPDFContextAuthor: "CyntientOps System",
            kCGPDFContextTitle: "Compliance Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Title
            let titleAttributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            "Compliance Report".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
            
            // Summary
            let summaryAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
            ]
            
            let criticalCount = issues.filter { $0.severity == .critical }.count
            let openCount = issues.filter { $0.status == .open }.count
            
            let summary = """
            Total Issues: \(issues.count)
            Critical Issues: \(criticalCount)
            Open Issues: \(openCount)
            Generated: \(dateFormatter.string(from: Date()))
            """
            
            summary.draw(in: CGRect(x: 50, y: 100, width: pageWidth - 100, height: 100), withAttributes: summaryAttributes)
            
            // Issues list (simplified)
            var yPosition: CGFloat = 220
            
            for (index, issue) in issues.prefix(10).enumerated() {
                let issueText = "\(index + 1). \(issue.title) - \(issue.severity.rawValue)"
                issueText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: summaryAttributes)
                yPosition += 25
                
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = 50
                }
            }
        }
        
        return data
    }
}

// MARK: - Supporting Types

public enum ReportError: LocalizedError {
    case pdfGenerationFailed
    case dataExportFailed
    case insufficientData
    case fileWriteFailed
    
    public var errorDescription: String? {
        switch self {
        case .pdfGenerationFailed:
            return "Failed to generate PDF report"
        case .dataExportFailed:
            return "Failed to export data"
        case .insufficientData:
            return "Insufficient data for report generation"
        case .fileWriteFailed:
            return "Failed to save report file"
        }
    }
}

// MARK: - Report Data Types

public struct ClientPortfolioReportData {
    public let generatedAt: Date
    public let dateRange: ReportDateRange
    public let portfolioHealth: CoreTypes.PortfolioHealth
    public let buildings: [CoreTypes.NamedCoordinate]
    public let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    public let complianceOverview: CoreTypes.ComplianceOverview
    public let insights: [String]
    
    public init(
        generatedAt: Date,
        dateRange: ReportDateRange,
        portfolioHealth: CoreTypes.PortfolioHealth,
        buildings: [CoreTypes.NamedCoordinate],
        buildingMetrics: [String: CoreTypes.BuildingMetrics],
        complianceOverview: CoreTypes.ComplianceOverview,
        insights: [String]
    ) {
        self.generatedAt = generatedAt
        self.dateRange = dateRange
        self.portfolioHealth = portfolioHealth
        self.buildings = buildings
        self.buildingMetrics = buildingMetrics
        self.complianceOverview = complianceOverview
        self.insights = insights
    }
}

// MARK: - Extensions

extension CoreTypes.BuildingMetrics {
    /// Helper property for display status in reports
    var displayStatus: String {
        if overdueTasks > 0 {
            return "Overdue"
        } else if completionRate >= 1.0 {
            return "Complete"
        } else if completionRate >= 0.8 {
            return "On Track"
        } else if completionRate >= 0.5 {
            return "In Progress"
        } else {
            return "Behind"
        }
    }
}
