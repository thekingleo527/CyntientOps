//  EmergencyContactsSheet.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Emergency contacts for quick actions
//

import SwiftUI

struct EmergencyContactsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                emergencyHeader
                
                // Emergency contacts list
                ScrollView {
                    VStack(spacing: 16) {
                        // Critical emergency contacts
                        criticalContactsSection
                        
                        // Building management contacts
                        managementContactsSection
                        
                        // Utility emergency contacts
                        utilityContactsSection
                    }
                    .padding()
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var emergencyHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emergency Contacts")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Critical contact information")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("Close") { dismiss() }
                    .foregroundColor(.white)
            }
            
            // Emergency warning banner
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("For life-threatening emergencies, always call 911 first")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .background(.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var criticalContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Critical Emergency")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                EmergencyContactCardRow(
                    title: "911 Emergency Services",
                    subtitle: "Police, Fire, Medical",
                    number: "911",
                    icon: "phone.fill",
                    color: .red,
                    isPrimary: true
                )
                
                EmergencyContactCardRow(
                    title: "Poison Control",
                    subtitle: "24/7 Poison Emergency",
                    number: "1-800-222-1222",
                    icon: "cross.case.fill",
                    color: .red
                )
            }
        }
        .padding()
        .background(.red.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var managementContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Management")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                EmergencyContactCardRow(
                    title: "J&M Realty",
                    subtitle: "David Edelman - Property Manager",
                    number: "(212) 721-0424",
                    icon: "person.fill",
                    color: .blue
                )
                
                EmergencyContactCardRow(
                    title: "Property Security",
                    subtitle: "24/7 security services",
                    number: "(555) 234-5678",
                    icon: "shield.fill",
                    color: .orange
                )
                
                EmergencyContactCardRow(
                    title: "Maintenance Emergency",
                    subtitle: "After-hours maintenance",
                    number: "(555) 345-6789",
                    icon: "wrench.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var utilityContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Utility Emergencies")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                EmergencyContactCardRow(
                    title: "Con Edison Gas Emergency",
                    subtitle: "Gas leaks and emergencies",
                    number: "1-800-752-6633",
                    icon: "flame.fill",
                    color: .orange
                )
                
                EmergencyContactCardRow(
                    title: "NYC Water Emergency",
                    subtitle: "Water main breaks",
                    number: "311",
                    icon: "drop.fill",
                    color: .blue
                )
                
                EmergencyContactCardRow(
                    title: "Electrical Emergency",
                    subtitle: "Power outages and electrical",
                    number: "1-800-752-6633",
                    icon: "bolt.fill",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// Renamed to avoid conflicts
struct EmergencyContactCardRow: View {
    let title: String
    let subtitle: String
    let number: String
    let icon: String
    let color: Color
    var isPrimary: Bool = false
    
    var body: some View {
        Button(action: callNumber) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                // Contact info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if isPrimary {
                            Text("PRIMARY")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(number)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
                
                Spacer()
                
                // Call button
                Image(systemName: "phone.circle.fill")
                    .font(.title)
                    .foregroundColor(color)
            }
            .padding()
            .background(.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private func callNumber() {
        let cleanNumber = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        if let url = URL(string: "tel:\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
}
