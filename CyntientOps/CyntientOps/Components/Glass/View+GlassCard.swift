//
//  View+GlassCard.swift
//  CyntientOps
//
//  Convenience modifier to wrap content in a GlassCard
//

import SwiftUI

public extension View {
    func glassCard(cornerRadius: CGFloat = 12, intensity: GlassIntensity = .regular, padding: CGFloat = 20) -> some View {
        GlassCard(intensity: intensity, cornerRadius: cornerRadius, padding: padding) {
            self
        }
    }
}

