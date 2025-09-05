//
//  SeededCredentials.swift
//  Debug-only helper to use seeded passwords for developer login
//

import Foundation

#if DEBUG
enum SeededCredentials {
    private static let map: [String: String] = [
        // Admins / System
        "admin@cyntientops.com": "CyntientAdmin2025!",
        // Managers / Workers (from UserAccountSeeder)
        "greg.hutson@cyntientops.com": "GregWorker2025!",
        "shawn.magloire@cyntientops.com": "ShawnHVAC2025!",
        "edwin.lema@cyntientops.com": "EdwinPark2025!",
        "kevin.dutan@cyntientops.com": "KevinRubin2025!",
        "mercedes.inamagua@cyntientops.com": "MercedesGlass2025!",
        "luis.lopez@cyntientops.com": "LuisElizabeth2025!",
        "angel.guiracocha@cyntientops.com": "AngelDSNY2025!",
        // Clients/Admins
        "jm@jmrealty.com": "JMRealty2025!",
        "David@jmrealty.org": "DavidJM2025!",
        "jedelman@jmrealty.org": "JerryJM2025!",
        "mfarhat@farhatrealtymanagement.com": "MoisesFarhat2025!",
        "candace@solar1.org": "CandaceSolar2025!",
        "michelle@remidgroup.com": "Michelle41E2025!",
        "sshapiro@citadelre.com": "StephenCit2025!",
        "paul@corbelpm.com": "PaulCorbel2025!",
        // Other known
        "maria@solarone.org": "MariaSolar2025!", // if present; falls back to dev login if not seeded
    ]

    static func password(for email: String) -> String? {
        map[email]
    }
}
#endif
