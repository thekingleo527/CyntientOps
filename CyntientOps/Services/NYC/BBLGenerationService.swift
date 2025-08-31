//
//  BBLGenerationService.swift
//  CyntientOps
//
//  Utility for normalizing NYC BBL to a 10-character string (B + 5-digit block + 4-digit lot)
//

import Foundation

public enum BBLGenerationService {
    /// Normalize a BBL string into NYC's 10-character format: B (1) + BLOCK (5, zero-padded) + LOT (4, zero-padded)
    /// Accepts inputs like "1-849-17", "108490017", or already normalized strings.
    public static func normalize(_ raw: String) -> String {
        // Strip non-digits
        let digits = raw.filter { $0.isNumber }
        if digits.count == 10 { return digits }

        // If looks like borough-block-lot separated by hyphens, try to parse
        let parts = raw.replacingOccurrences(of: " ", with: "").split(separator: "-")
        if parts.count == 3,
           let b = parts.first, let blk = parts.dropFirst().first, let lot = parts.last,
           let borough = Int(b), let block = Int(blk), let lotNum = Int(lot),
           (1...5).contains(borough) {
            return "\(borough)\(String(format: "%05d", block))\(String(format: "%04d", lotNum))"
        }

        // If we only have digits and at least 7, try best-effort (assume first is borough)
        if digits.count >= 7 {
            let bStr = String(digits.prefix(1))
            let rest = String(digits.dropFirst())
            // Heuristic: last 4 are lot, the rest are block
            let lotPart = String(rest.suffix(4))
            let blockPart = String(rest.dropLast(4))
            let borough = Int(bStr) ?? 0
            let block = Int(blockPart) ?? 0
            let lot = Int(lotPart) ?? 0
            if (1...5).contains(borough) {
                return "\(borough)\(String(format: "%05d", block))\(String(format: "%04d", lot))"
            }
        }

        // Fallback: return digits (or empty) to avoid crashing callers
        return digits
    }
}

