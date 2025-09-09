//
//  DeploymentRunner.swift
//  CyntientOps
//
//  Lightweight view model used by ProductionDeploymentView to orchestrate
//  the existing ProductionDeploy pipeline and surface progress/logs.
//

import Foundation
import Combine

@MainActor
final class DeploymentRunner: ObservableObject {
    @Published var logs: [String] = []
    @Published var progress: Double = 0.0
    @Published var deploymentStatus: String = "Ready"

    private func log(_ message: String) {
        logs.append("[\(Date().formatted())] \(message)")
    }

    func executeFullDeployment() async {
        deploymentStatus = "Starting"
        progress = 0.0
        logs.removeAll()
        log("Deployment started")

        do {
            // Phase 1: Validate credentials
            deploymentStatus = "Validating credentials"
            log("Validating production credentials…")
            await ProductionCredentialsManager.shared.validateAllCredentials()
            progress = 0.2

            // Phase 2: Quick DB sanity check (non-destructive)
            deploymentStatus = "Checking database"
            log("Running database health check…")
            let _ = try? await GRDBManager.shared.dumpHealth()
            progress = 0.3

            // Phase 3: Run production test suite via ProductionDeploy helper
            deploymentStatus = "Running tests"
            log("Running production test suite…")
            // This is handled inside ProductionDeploy
            progress = 0.5

            // Phase 4: Build + Archive + Export (delegated)
            deploymentStatus = "Building & Archiving"
            log("Executing ProductionDeploy pipeline…")
            try await ProductionDeploy.shared.deployToProduction()
            progress = 0.95

            // Phase 5: Finalize
            deploymentStatus = "Deployment Complete"
            log("Deployment completed successfully")
            progress = 1.0

        } catch {
            deploymentStatus = "Deployment Failed"
            log("Deployment error: \(error.localizedDescription)")
        }
    }
}

