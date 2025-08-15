#!/usr/bin/env swift

//
//  TestAuthenticationFlow.swift
//  CyntientOps
//
//  Test script to debug authentication failure issue
//  Run from terminal: swift TestAuthenticationFlow.swift
//

import Foundation

@main
struct AuthenticationTester {
    static func main() async {
        print("🔍 Testing CyntientOps Authentication Flow...")
        
        do {
            // Initialize database manager
            let grdbManager = GRDBManager.shared
            
            // Wait for database initialization
            await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            print("✅ Database initialized")
            print("📍 Database location: \(grdbManager.databaseURL)")
            print("📊 Database size: \(grdbManager.getDatabaseSize()) bytes")
            
            // Check if database is ready
            let isReady = await grdbManager.isDatabaseReady()
            print("🏥 Database ready: \(isReady)")
            
            // Check database stats
            let stats = grdbManager.getDatabaseStats()
            print("📈 Database stats: \(stats.summary)")
            
            // If database is empty, seed it
            if stats.workers == 0 {
                print("🌱 Database is empty, seeding accounts...")
                let seeder = UserAccountSeeder()
                try await seeder.seedAccounts()
                
                // Check stats again
                let newStats = grdbManager.getDatabaseStats()
                print("📈 After seeding: \(newStats.summary)")
            }
            
            // Test specific user credentials
            print("\n🔑 Testing authentication with known credentials...")
            
            let testCredentials = [
                ("admin@cyntientops.com", "CyntientAdmin2025!"),
                ("shawn.magloire@cyntientops.com", "ShawnHVAC2025!"),
                ("greg.hutson@cyntientops.com", "GregWorker2025!"),
                ("admin@test.com", "password"),  // Debug credentials
                ("shawn@test.com", "password")   // Debug credentials
            ]
            
            let authManager = NewAuthManager.shared
            
            for (email, password) in testCredentials {
                print("\n📧 Testing: \(email)")
                
                // First check if user exists in database
                do {
                    let users = try await grdbManager.query(
                        "SELECT id, name, email, role FROM workers WHERE email = ? AND isActive = 1", 
                        [email]
                    )
                    
                    if users.isEmpty {
                        print("  ❌ User not found in database")
                    } else {
                        let user = users[0]
                        print("  ✅ User found: \(user["name"] ?? "Unknown") (Role: \(user["role"] ?? "Unknown"))")
                        
                        // Try authentication
                        do {
                            try await authManager.authenticate(email: email, password: password)
                            print("  ✅ Authentication successful!")
                            await authManager.logout()
                        } catch {
                            print("  ❌ Authentication failed: \(error.localizedDescription)")
                            
                            // Check password hash if it's a NewAuthError
                            if let authError = error as? NewAuthError {
                                switch authError {
                                case .authenticationFailed(let message):
                                    print("    Details: \(message)")
                                default:
                                    break
                                }
                            }
                        }
                    }
                } catch {
                    print("  ❌ Database query failed: \(error)")
                }
                
                // Small delay between tests
                await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            print("\n🔍 Final diagnosis:")
            print("1. Check that the database is properly initialized")
            print("2. Verify user accounts exist with correct credentials") 
            print("3. Check password hashing compatibility between seeder and auth manager")
            print("4. Ensure salts are properly stored in keychain")
            
        } catch {
            print("❌ Test failed with error: \(error)")
        }
    }
}