#!/usr/bin/env swift

//
//  SeedDatabase.swift
//  Quick database seeding script
//

import Foundation
import GRDB
import CryptoKit

// Initialize database and seed users
print("🌱 Initializing and seeding database...")

// Create database manager
let grdbManager = GRDBManager.shared
print("✅ Database manager created")

// Wait for initialization
await Task.sleep(nanoseconds: 1_000_000_000)

// Seed accounts
let seeder = UserAccountSeeder()
try await seeder.seedAccounts()

print("✅ Database seeded successfully!")