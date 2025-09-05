//
//  ProductionDeploymentView.swift
//  CyntientOps v7.0
//
//  🚀 PRODUCTION DEPLOYMENT INTERFACE
//  SwiftUI interface for executing production deployment
//

import SwiftUI

public struct ProductionDeploymentView: View {
    @StateObject private var deploymentRunner = DeploymentRunner()
    @State private var showingLogs = false
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                
                // Header
                VStack(spacing: 8) {
                    Text("🚀 Production Deployment")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("CyntientOps v7.0")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("NYC API Integration & Real-World Data Generation")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Status Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Status:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(deploymentRunner.deploymentStatus)
                            .foregroundColor(statusColor)
                    }
                    
                    // Progress Bar
                    VStack(spacing: 8) {
                        ProgressView(value: deploymentRunner.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        
                        HStack {
                            Text("\(Int(deploymentRunner.progress * 100))% Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    
                    // Recent Log Entry
                    if let lastLog = deploymentRunner.logs.last {
                        Text(lastLog)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
                
                // Deployment Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deployment Phases:")
                        .fontWeight(.semibold)
                    
                    deploymentPhase("Dependencies", "Verify services and NYC API connectivity", 1)
                    deploymentPhase("Property Data", "Generate BBL data for all 15 buildings", 2)
                    deploymentPhase("Database", "Seed user accounts and relationships", 3)
                    deploymentPhase("Validation", "Verify worker assignments and config", 4)
                    deploymentPhase("Final Check", "Complete production readiness check", 5)
                }
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(12)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await deploymentRunner.executeFullDeployment()
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Execute Production Deployment")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(deploymentRunner.deploymentStatus == "Ready" ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(deploymentRunner.deploymentStatus != "Ready" && deploymentRunner.deploymentStatus != "Deployment Complete" && deploymentRunner.deploymentStatus != "Deployment Failed")
                    
                    Button(action: { showingLogs = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("View Deployment Logs")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .navigationTitle("Production Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingLogs) {
            deploymentLogsView
        }
    }
    
    private var statusColor: Color {
        switch deploymentRunner.deploymentStatus {
        case "Ready": return .blue
        case "Deployment Complete": return .green
        case "Deployment Failed": return .red
        default: return .orange
        }
    }
    
    private func deploymentPhase(_ title: String, _ description: String, _ phase: Int) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(phaseColor(phase))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                    .font(.callout)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func phaseColor(_ phase: Int) -> Color {
        let currentPhase = Int(deploymentRunner.progress * 5) + 1
        if phase < currentPhase {
            return .green
        } else if phase == currentPhase && deploymentRunner.progress > 0 {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var deploymentLogsView: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(deploymentRunner.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Deployment Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingLogs = false
                    }
                }
            }
        }
    }
}

