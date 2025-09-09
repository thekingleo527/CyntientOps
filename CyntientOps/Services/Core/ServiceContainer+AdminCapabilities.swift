//
//  ServiceContainer+AdminCapabilities.swift
//  CyntientOps
//
//  Lightweight admin capability check for gating queries/filters.
//

import Foundation

extension ServiceContainer {
    public var isAdminUser: Bool {
        let role = NewAuthManager.shared.userRole
        switch role {
        case .admin, .manager, .superAdmin:
            return true
        default:
            return false
        }
    }
}

