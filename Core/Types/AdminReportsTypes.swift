//
//  AdminReportsTypes.swift
//  CyntientOps
//
//  Shared report model types used across services and views.
//

import Foundation

public struct AdminGeneratedReport: Identifiable, Codable {
    public let id: String
    public let title: String
    public let type: String
    public let dateRange: String?
    public let generatedDate: Date
    public let filePath: String
    public let fileSize: Int
    public var isFavorite: Bool
    public let isScheduled: Bool
    public let isArchived: Bool

    public init(
        id: String = UUID().uuidString,
        title: String,
        type: String,
        dateRange: String? = nil,
        generatedDate: Date,
        filePath: String,
        fileSize: Int,
        isFavorite: Bool = false,
        isScheduled: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.dateRange = dateRange
        self.generatedDate = generatedDate
        self.filePath = filePath
        self.fileSize = fileSize
        self.isFavorite = isFavorite
        self.isScheduled = isScheduled
        self.isArchived = isArchived
    }

    public var displayFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}

