
//  StringExtensions.swift
//  CyntientOps
//
//  Purpose: Shared String extensions used throughout the app
//  ✅ CONSOLIDATED: Single source of truth for String extensions
//  ✅ FIXED: Resolves duplicate declaration issues
//

import Foundation

// MARK: - String Extensions

extension String {
    
    /// Returns the initials from a name string
    /// Uses PersonNameComponentsFormatter for accurate parsing, with fallback logic
    /// Examples:
    /// - "John Doe" → "JD"
    /// - "Mary Jane Smith" → "MJ"
    /// - "Prince" → "P"
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: self) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        // Fallback for cases where PersonNameComponentsFormatter fails
        let words = self.split(separator: " ")
        let initials = words.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
    
    /// Trims whitespace and newlines from both ends of the string
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Returns true if the string is empty after trimming whitespace
    var isBlank: Bool {
        self.trimmed.isEmpty
    }
    
    /// Capitalizes first letter of each word
    var titleCased: String {
        self.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    /// Truncates string to specified length with ellipsis
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
    
    /// Returns a safe filename by removing invalid characters
    var safeFilename: String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        
        return self.components(separatedBy: invalidCharacters)
            .joined(separator: "_")
            .trimmed
    }
    
    /// Checks if string is a valid email format
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Converts string to a valid phone number format
    var formattedPhoneNumber: String? {
        let numbers = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        guard numbers.count == 10 else { return nil }
        
        let areaCode = String(numbers.prefix(3))
        let prefix = String(numbers.dropFirst(3).prefix(3))
        let suffix = String(numbers.suffix(4))
        
        return "(\(areaCode)) \(prefix)-\(suffix)"
    }
}

// MARK: - Optional String Extensions

extension Optional where Wrapped == String {
    
    /// Returns true if the optional string is nil or empty/blank
    var isNilOrBlank: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            return value.isBlank
        }
    }
    
    /// Returns the string value or a default if nil/empty
    func orDefault(_ defaultValue: String) -> String {
        guard let self = self, !self.isBlank else {
            return defaultValue
        }
        return self
    }
}
