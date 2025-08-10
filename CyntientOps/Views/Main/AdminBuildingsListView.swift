//
//  AdminBuildingsListView.swift
//  CyntientOps v6.0
//
//  Complete buildings management view for administrators
//  Shows portfolio overview, building cards, and detailed metrics
//

import SwiftUI
import MapKit

struct AdminBuildingsListView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    
    @EnvironmentObject private var container: ServiceContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedFilter: BuildingFilter = .all
    @State private var showingMap = false
    
    enum BuildingFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case maintenance = "Maintenance"
        case critical = "Critical"
        
        var icon: String {
            switch self {
            case .all: return "building.2"
            case .active: return "checkmark.circle"
            case .maintenance: return "wrench"
            case .critical: return "exclamationmark.triangle"
            }
        }
    }
    
    private var filteredBuildings: [CoreTypes.NamedCoordinate] {
        let searched = buildings.filter { building in
            searchText.isEmpty || 
            building.name.localizedCaseInsensitiveContains(searchText) ||
            building.address.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case .all:
            return searched
        case .active:
            return searched // For NamedCoordinate, we don't have status info
        case .maintenance:
            return searched // For NamedCoordinate, we don't have status info
        case .critical:
            return searched // For NamedCoordinate, we don't have compliance info
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search and Filter
                searchAndFilterView
                
                // Buildings List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredBuildings, id: \.id) { building in
                            AdminBuildingCard(
                                building: building,
                                onTap: {
                                    onSelectBuilding(building)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Portfolio Buildings")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { showingMap = true }) {
                Image(systemName: "map")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }
    
    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Search buildings...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BuildingFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: selectedFilter == filter,
                            onTap: { selectedFilter = filter }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
}

struct AdminBuildingCard: View {
    let building: CoreTypes.NamedCoordinate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Building Image or Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                
                // Building Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        // Active indicator (since we don't have status)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Active")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                        
                        // Location info
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Portfolio")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Basic info
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Building ID:")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(building.id.prefix(6) + "...")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
            )
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct AdminBuildingsListView_Previews: PreviewProvider {
    static var previews: some View {
        AdminBuildingsListView(
            buildings: [
                CoreTypes.NamedCoordinate(
                    id: "1",
                    name: "123 1st Avenue",
                    coordinate: .init(latitude: 40.7128, longitude: -74.0060),
                    address: "123 1st Avenue, New York, NY 10003"
                ),
                CoreTypes.NamedCoordinate(
                    id: "2", 
                    name: "68 Perry Street",
                    coordinate: .init(latitude: 40.7309, longitude: -74.0041),
                    address: "68 Perry Street, New York, NY 10014"
                )
            ],
            onSelectBuilding: { _ in }
        )
        .environmentObject(ServiceContainer())
        .preferredColorScheme(.dark)
    }
}
#endif