//
//  WeatherSuggestion.swift
//  CyntientOps
//
//  Shared model for weather-based suggestions used by the engine and view models.

import Foundation

public struct WeatherSuggestion: Identifiable, Equatable {
    public enum Kind: CaseIterable {
        case rain
        case snow
        case heat
        case cold
        case dsny
        case sun
        case wind
        case generic
    }

    public let id: String
    public let kind: Kind
    public let title: String
    public let subtitle: String
    public let taskTemplateId: String?
    public let dueBy: Date?
    public let buildingId: String?

    public init(
        id: String,
        kind: Kind,
        title: String,
        subtitle: String,
        taskTemplateId: String? = nil,
        dueBy: Date? = nil,
        buildingId: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.taskTemplateId = taskTemplateId
        self.dueBy = dueBy
        self.buildingId = buildingId
    }
}

