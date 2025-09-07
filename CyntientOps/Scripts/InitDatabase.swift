#!/usr/bin/swift
//
//  InitDatabase.swift
//  Script to initialize CyntientOps database
//

import Foundation

@main 
struct DatabaseInit {
    static func main() async {
        print("🚀 Initializing CyntientOps database...")
        
        // For now, let's manually trigger a database initialization by starting the app
        // The proper way would be to call DatabaseInitializer.shared.initializeIfNeeded()
        print("⚠️  Please run the app to trigger automatic database initialization")
        print("💡 The DatabaseInitializer will run automatically when the app starts")
    }
}