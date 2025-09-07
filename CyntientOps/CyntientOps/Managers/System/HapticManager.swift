//
//  HapticManager.swift
//  CyntientOps
//
//  ✅ V6.0: Added missing 'success' haptic feedback type.
//

import SwiftUI

public enum HapticManager {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    public static func success() {
        notification(.success)
    }
}
