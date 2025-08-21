//
//  AssetImageDebugger.swift
//  CyntientOps
//
//  🔧 COMPILATION FIXED - Using BuildingService for building data
//  ✅ Fixed: Made buildingIdToAssetName internal for access from view
//  ✅ Fixed: Broke up complex expression for compiler
//

import SwiftUI
import Foundation

// --------------------------------------------------------------------
//  Fixed type alias to match BuildingService return type
// --------------------------------------------------------------------
typealias DebugBuilding = NamedCoordinate

/// Utility for verifying that every building points at a valid image
/// asset and for listing the contents of the Assets catalogue.
final class AssetImageDebugger {

    static let shared = AssetImageDebugger()
    private init() {}

    // MARK: – Console diagnostics
    func debugAllBuildingImages() async {
        // ✅ FIX: Use BuildingService to get all buildings
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            
            logInfo("🏢 DIAGNOSING BUILDING IMAGES:")
            logInfo("==============================")
            logInfo("Number of buildings: \(buildings.count)")
            logInfo("==============================")
            
            for building in buildings {
                debugBuildingImage(building)
            }
            
            logInfo("==============================")
            logInfo("Diagnosis complete")
            logInfo("==============================")
        } catch {
            logInfo("❌ Failed to load buildings: \(error)")
        }
    }

    private func debugBuildingImage(_ building: DebugBuilding) {
        logInfo("🏢 Building: \(building.name) (ID: \(building.id))")

        // 1️⃣ Check if building has imageAssetName property
        // Note: NamedCoordinate doesn't have imageAssetName in CoreTypes
        // Using building ID to asset name mapping instead
        let assetName = buildingIdToAssetName(building.id)
        let assetExists = UIImage(named: assetName) != nil
        logInfo("   • Asset name: \"\(assetName)\"  →  \(assetExists ? "✅ found" : "❌ missing")")

        // 2️⃣ A "standardised" fallback asset name
        let standardName = building.name
                            .replacingOccurrences(of: "[\\s,()\\-]", with: "_",
                                                  options: .regularExpression)
        let standardExist = UIImage(named: standardName) != nil
        logInfo("   • Standard name : \"\(standardName)\"  →  \(standardExist ? "✅ found" : "❌ missing")")
        
        // 3️⃣ Check if this is a special case (Kevin's Rubin Museum)
        if building.id == "14" && building.name.contains("Rubin") {
            logInfo("   • ✅ KEVIN ASSIGNMENT: Rubin Museum correctly assigned")
        }
        
        // 4️⃣ Check for deprecated Franklin Street assignment
        if building.name.contains("104 Franklin") {
            logInfo("   • ⚠️  DEPRECATED: 104 Franklin Street should not be used (Kevin now works at Rubin Museum)")
        }
        
        logInfo("")
    }
    
    // MARK: - Building ID to Asset Name Mapping
    // ✅ FIXED: Changed from private to internal for access from SwiftUI view
    func buildingIdToAssetName(_ buildingId: String) -> String {
        // Same mapping used in MapRevealContainer
        let buildingAssetMap: [String: String] = [
            "1": "12_West_18th_Street",
            "2": "29_31_East_20th_Street",
            "3": "36_Walker_Street",
            "4": "41_Elizabeth_Street",
            "5": "68_Perry_Street",
            "6": "104_Franklin_Street",
            "7": "112_West_18th_Street",
            "8": "117_West_17th_Street",
            "9": "123_1st_Avenue",
            "10": "131_Perry_Street",
            "11": "133_East_15th_Street",
            "12": "135West17thStreet",
            "13": "136_West_17th_Street",
            "14": "Rubin_Museum_142_148_West_17th_Street",
            "15": "138West17thStreet",
            "16": "41_Elizabeth_Street",
            "park": "Stuyvesant_Cove_Park"
        ]
        
        return buildingAssetMap[buildingId] ?? "placeholder"
    }

    // MARK: – Asset-catalogue listing
    func debugAllAssetNames() {
        let assets = listAllAssetNames()

        logInfo("📁 ASSETS CATALOG CONTENTS:")
        logInfo("===========================")
        logInfo("Number of assets: \(assets.count)")
        logInfo("===========================")

        for asset in assets.sorted() { logInfo("   • \(asset)") }

        logInfo("===========================")
    }

    private func listAllAssetNames() -> [String] {
        // **Updated asset candidates including Kevin's corrected assignment**
        let candidates = [
            "12_West_18th_Street",
            "29_31_East_20th_Street",
            "36_Walker_Street",
            "41_Elizabeth_Street",
            "68_Perry_Street",
            "104_Franklin_Street",              // ⚠️ DEPRECATED (Kevin no longer works here)
            "112_West_18th_Street",
            "117_West_17th_Street",
            "123_1st_Avenue",
            "131_Perry_Street",
            "133_East_15th_Street",
            "135-139_W_17th_Street",
            "136_West_17th_Street",
            "138_West_17th_Street",
            "rubin_museum",                     // ✅ CORRECTED: Kevin's actual workplace
            "Rubin_Museum_17th_Street",         // Alternative naming
            "Rubin_Museum_142_148_West_17th_Street", // Full address variant
            "Stuyvesant_Cove_Park",
            
            // Additional building assets that might exist
            "178_Spring_Street",
            "west17_135",
            "west17_136",
            "west17_138",
            "perry_131",
            "perry_68",
            "east20_29",
            "spring_178"
        ]

        return candidates.filter { UIImage(named: $0) != nil }
    }
    
    // MARK: - Enhanced Debugging for Kevin Assignment
    func debugKevinAssignment() async {
        logInfo("🔍 KEVIN ASSIGNMENT VALIDATION:")
        logInfo("===============================")
        
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            
            // Check for Rubin Museum
            let rubinMuseum = buildings.first { $0.id == "14" && $0.name.contains("Rubin") }
            if let rubin = rubinMuseum {
                logInfo("✅ Kevin's Rubin Museum found:")
                logInfo("   • ID: \(rubin.id)")
                logInfo("   • Name: \(rubin.name)")
                let assetName = buildingIdToAssetName(rubin.id)
                logInfo("   • Asset: \(assetName)")
                logInfo("   • Image exists: \(UIImage(named: assetName) != nil ? "✅" : "❌")")
            } else {
                logInfo("❌ Kevin's Rubin Museum NOT FOUND!")
            }
            
            // Check for deprecated Franklin Street
            let franklinStreet = buildings.first { $0.name.contains("104 Franklin") }
            if let franklin = franklinStreet {
                logInfo("⚠️  DEPRECATED Franklin Street still exists:")
                logInfo("   • ID: \(franklin.id)")
                logInfo("   • Name: \(franklin.name)")
                logInfo("   • This should be removed from Kevin's assignments")
            } else {
                logInfo("✅ No deprecated Franklin Street assignments found")
            }
        } catch {
            logInfo("❌ Failed to load buildings: \(error)")
        }
        
        logInfo("===============================")
    }
    
    // MARK: - Building Statistics
    func getBuildingImageStatistics() async -> (total: Int, found: Int, missing: Int, foundPercentage: Double) {
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            let total = buildings.count
            let found = buildings.filter { building in
                let assetName = buildingIdToAssetName(building.id)
                return UIImage(named: assetName) != nil
            }.count
            let missing = total - found
            let percentage = total > 0 ? (Double(found) / Double(total)) * 100 : 0
            
            return (total: total, found: found, missing: missing, foundPercentage: percentage)
        } catch {
            logInfo("❌ Failed to get building statistics: \(error)")
            return (total: 0, found: 0, missing: 0, foundPercentage: 0)
        }
    }
    
    // MARK: - Synchronous Helper for Legacy Code
    func debugAllBuildingImagesSync() {
        Task {
            await debugAllBuildingImages()
        }
    }
}

// MARK: – SwiftUI helper view
/// A simple UI wrapper so you can eyeball which images resolve correctly.
struct AssetDebuggerView: View {

    @State private var buildingImages: [(building: DebugBuilding, image: UIImage?)] = []
    @State private var isLoading = true
    @State private var statistics: (total: Int, found: Int, missing: Int, foundPercentage: Double) = (0, 0, 0, 0)
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading buildings...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section("Building Assets") {
                            ForEach(buildingImages, id: \.building.id) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.building.name).font(.headline)
                                        Text("ID: \(item.building.id)")
                                            .font(.caption).foregroundColor(.secondary)
                                        
                                        // ✅ FIXED: Broke up complex expression
                                        let assetName = AssetImageDebugger.shared.buildingIdToAssetName(item.building.id)
                                        Text("Asset: \(assetName)")
                                            .font(.caption2).foregroundColor(.blue)
                                        
                                        // ✅ Special indicators for Kevin's assignments
                                        if item.building.id == "14" && item.building.name.contains("Rubin") {
                                            Text("✅ KEVIN'S WORKPLACE")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                                .fontWeight(.bold)
                                        }
                                        
                                        if item.building.name.contains("104 Franklin") {
                                            Text("⚠️ DEPRECATED FOR KEVIN")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                                .fontWeight(.bold)
                                        }
                                    }

                                    Spacer()

                                    if let image = item.image {
                                        Image(uiImage: image)
                                            .resizable().scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.green, lineWidth: 2))
                                    } else {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 24)).foregroundColor(.red)
                                    }
                                }
                            }
                        }

                        Section("Debug Actions") {
                            Button("Print Diagnostics to Console") {
                                Task {
                                    await AssetImageDebugger.shared.debugAllBuildingImages()
                                    AssetImageDebugger.shared.debugAllAssetNames()
                                }
                            }
                            
                            Button("Validate Kevin Assignment") {
                                Task {
                                    await AssetImageDebugger.shared.debugKevinAssignment()
                                }
                            }
                            
                            Button("Reload Building Images") {
                                loadBuildingImages()
                            }
                        }
                        
                        Section("Statistics") {
                            HStack {
                                Text("Total Buildings:")
                                Spacer()
                                Text("\(statistics.total)")
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Images Found:")
                                Spacer()
                                Text("\(statistics.found)")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Missing Images:")
                                Spacer()
                                Text("\(statistics.missing)")
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Text("Success Rate:")
                                Spacer()
                                Text("\(String(format: "%.1f", statistics.foundPercentage))%")
                                    .foregroundColor(statistics.foundPercentage > 75 ? .green : .orange)
                            }
                            
                            HStack {
                                Text("Kevin Assignment:")
                                Spacer()
                                let hasRubin = buildingImages.contains {
                                    $0.building.id == "14" && $0.building.name.contains("Rubin")
                                }
                                Text(hasRubin ? "✅ Rubin Museum" : "❌ Not Found")
                                    .foregroundColor(hasRubin ? .green : .red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Asset Debugger")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .onAppear {
                loadBuildingImages()
            }
        }
    }

    private func loadBuildingImages() {
        isLoading = true
        
        Task {
            do {
                let buildings = try await BuildingService.shared.getAllBuildings()
                let images = buildings.map { building in
                    let assetName = AssetImageDebugger.shared.buildingIdToAssetName(building.id)
                    return (building, UIImage(named: assetName))
                }
                
                self.buildingImages = images
                self.statistics = await AssetImageDebugger.shared.getBuildingImageStatistics()
                self.isLoading = false
            } catch {
                logInfo("❌ Failed to load buildings: \(error)")
                self.isLoading = false
            }
        }
    }
}

// MARK: - Legacy Compatibility Extension
extension AssetImageDebugger {
    /// For calling from non-async contexts
    func debugSync() {
        Task {
            await self.debugAllBuildingImages()
            self.debugAllAssetNames()
            await self.debugKevinAssignment()
        }
    }
}

struct AssetDebuggerView_Previews: PreviewProvider {
    static var previews: some View { AssetDebuggerView() }
}

// MARK: - Quick Access Functions for Console Debugging

extension AssetImageDebugger {
    /// Quick console validation of all systems
    func validateEverything() async {
        logInfo("\n🚀 CYNTIENTOPS ASSET VALIDATION")
        logInfo("=================================")
        
        await debugAllBuildingImages()
        logInfo("\n")
        await debugKevinAssignment()
        logInfo("\n")
        debugAllAssetNames()
        
        let stats = await getBuildingImageStatistics()
        logInfo("\n📊 FINAL STATISTICS:")
        logInfo("====================")
        logInfo("Total Buildings: \(stats.total)")
        logInfo("Images Found: \(stats.found)")
        logInfo("Missing Images: \(stats.missing)")
        logInfo("Success Rate: \(String(format: "%.1f", stats.foundPercentage))%")
        logInfo("=================================\n")
    }
}
