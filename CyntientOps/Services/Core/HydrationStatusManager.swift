//
//  HydrationStatusManager.swift
//  CyntientOps
//
//  Tracks readiness of key hydration gates for lightweight HUDs

import Foundation

@MainActor
public final class HydrationStatusManager: ObservableObject {
    public static let shared = HydrationStatusManager()

    @Published public var userReady = false
    @Published public var buildingsReady = false
    @Published public var routesReady = false
    @Published public var weatherReady = false
    @Published public var dsnyReady = false
    @Published public var scheduleReady = false

    private init() {}

    public func isReady(section: Section) -> Bool {
        switch section {
        case .user: return userReady
        case .buildings: return buildingsReady
        case .routes: return routesReady
        case .weather: return weatherReady
        case .dsny: return dsnyReady
        case .schedule: return scheduleReady
        }
    }

    public enum Section { case user, buildings, routes, weather, dsny, schedule }
}

