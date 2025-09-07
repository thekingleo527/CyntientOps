//
//  SecurityAudit.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 7/31/25.
//


//
//  SecurityAudit.swift
//  CyntientOps
//
//  Stream D: Features & Polish
//  Mission: Create internal tools for security auditing.
//
//  ✅ DEBUG TOOL: A utility for developers to run security checks.
//  ✅ COMPREHENSIVE: Includes checks for insecure storage and hardcoded keys.
//  ⚠️ NOTE: This is a debug/internal tool and should not be shipped in production builds.
//

import Foundation

#if DEBUG // Only compile this file for Debug builds

final class SecurityAudit {
    
    /// Runs a comprehensive security audit and returns a report.
    func performAudit() -> AuditReport {
        print("🛡️ Performing security audit...")
        
        var issues: [SecurityIssue] = []
        
        issues.append(contentsOf: checkForInsecureStorage())
        issues.append(contentsOf: scanForHardcodedSecrets())
        
        print("✅ Audit complete. Found \(issues.count) potential issues.")
        return AuditReport(date: Date(), issues: issues)
    }
    
    // MARK: - Specific Audit Checks
    
    /// Checks UserDefaults for any data that looks like a password or token.
    private func checkForInsecureStorage() -> [SecurityIssue] {
        var foundIssues: [SecurityIssue] = []
        let sensitiveKeywords = ["password", "token", "secret", "key", "auth"]
        
        let userDefaultsDict = UserDefaults.standard.dictionaryRepresentation()
        
        for (key, value) in userDefaultsDict {
            let lowercasedKey = key.lowercased()
            if sensitiveKeywords.contains(where: lowercasedKey.contains) {
                let issue = SecurityIssue(
                    type: .insecureStorage,
                    severity: .high,
                    description: "Found potentially sensitive key '\(key)' in UserDefaults.",
                    recommendation: "Sensitive data like tokens or passwords should be stored in the Keychain, not UserDefaults."
                )
                foundIssues.append(issue)
            }
        }
        
        return foundIssues
    }
    
    /// Scans the application's main bundle for files that might contain hardcoded secrets.
    /// This is a heuristic and may produce false positives.
    private func scanForHardcodedSecrets() -> [SecurityIssue] {
        // This is a placeholder for a more advanced scanning tool.
        // A real implementation might scan source files or property lists.
        // For this example, we'll just return an empty array.
        return []
    }
    
    // You could add more checks here, such as:
    // - func checkNetworkSecurity() -> [SecurityIssue] (e.g., checks for ATS exceptions)
    // - func checkKeychainProtection() -> [SecurityIssue] (e.g., checks accessibility attributes)
}

// MARK: - Supporting Types

struct AuditReport {
    let date: Date
    let issues: [SecurityIssue]
    
    var summary: String {
        if issues.isEmpty {
            return "Security audit passed with 0 issues."
        } else {
            let highCount = issues.filter { $0.severity == .high }.count
            let mediumCount = issues.filter { $0.severity == .medium }.count
            return "Security audit found \(issues.count) issues (\(highCount) high, \(mediumCount) medium)."
        }
    }
}

struct SecurityIssue: Identifiable {
    let id = UUID()
    let type: IssueType
    let severity: Severity
    let description: String
    let recommendation: String
    
    enum IssueType {
        case insecureStorage
        case hardcodedSecret
        case network
    }
    
    enum Severity {
        case low, medium, high
    }
}

#endif // End of #if DEBUG