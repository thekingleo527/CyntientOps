//
//  AIAssistantImageLoader.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 6/16/25.
//

//
//  AIAssistantImageLoader.swift
//  CyntientOps
//
//  ✅ AI ASSISTANT IMAGE LOADING UTILITY
//  ✅ Handles multiple image name variations
//  ✅ Provides fallback options for AIAssistant image
//  ✅ Debug logging to help locate correct image path
//  ✅ Can be used across all AI components
//

import SwiftUI
// CyntientOps Types Import
// (This comment helps identify our import)

import UIKit
// CyntientOps Types Import
// (This comment helps identify our import)

/// Utility for loading the AI Assistant image with multiple fallback options
struct AIAssistantImageLoader {
    
    // MARK: - Image Name Variations
    
    private static let imageNames = [
        "AIAssistant",
        "AIAssistant.png",
        "AI-Assistant",
        "ai-assistant",
        "nova-avatar",
        "Nova-Avatar",
        "NovaAvatar",
        "assistant-avatar",
        "ai_assistant",
        "brain-assistant",
        "BrainAssistant"
    ]
    
    // MARK: - Load AI Assistant Image
    
    /// Attempts to load the AI Assistant image with multiple fallback options
    /// - Returns: UIImage if found, nil if no image found
    static func loadAIAssistantImage() -> UIImage? {
        // Try each image name variation
        for imageName in imageNames {
            if let image = UIImage(named: imageName) {
                print("✅ AIAssistant image found: \(imageName)")
                return image
            }
        }
        
        // Debug logging if no image found
        print("⚠️ AIAssistant image not found. Tried:")
        for imageName in imageNames {
            print("   - \(imageName)")
        }
        
        print("💡 To fix this:")
        print("   1. Add an image named 'AIAssistant' to Assets.xcassets")
        print("   2. Ensure it's 512x512px for best quality")
        print("   3. Use PNG format with transparency")
        
        return nil
    }
    
    /// Creates a SwiftUI Image view with AI Assistant image or fallback
    /// - Parameters:
    ///   - size: The size of the image frame
    ///   - fallbackIcon: System icon to use if image not found
    /// - Returns: SwiftUI Image view
    static func aiAssistantImageView(size: CGFloat = 44, fallbackIcon: String = "brain.head.profile") -> some View {
        Group {
            if let aiImage = loadAIAssistantImage() {
                Image(uiImage: aiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size * 0.7, height: size * 0.7)
                    .clipShape(Circle())
            } else {
                Image(systemName: fallbackIcon)
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    /// Circular AI Assistant image view for avatars
    /// - Parameters:
    ///   - diameter: The diameter of the circular image
    ///   - borderColor: Optional border color
    /// - Returns: SwiftUI view with circular AI Assistant image
    static func circularAIAssistantView(diameter: CGFloat = 60, borderColor: Color? = nil) -> some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: diameter, height: diameter)
            
            // AI Assistant image or fallback
            if let aiImage = loadAIAssistantImage() {
                Image(uiImage: aiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: diameter * 0.8, height: diameter * 0.8)
                    .clipShape(Circle())
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: diameter * 0.4, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Optional border
            if let borderColor = borderColor {
                Circle()
                    .stroke(borderColor, lineWidth: 2)
                    .frame(width: diameter, height: diameter)
            }
        }
    }
    
    // MARK: - Asset Debugging
    
    /// Debug function to list all available images in Assets.xcassets
    static func debugAvailableAssets() {
        print("🔍 DEBUGGING AVAILABLE ASSETS:")
        print("==============================")
        
        // List of common image names to check
        let testNames = [
            "AIAssistant",
            "ai-assistant", 
            "nova",
            "Nova",
            "brain",
            "assistant",
            "avatar"
        ]
        
        var foundImages: [String] = []
        
        for testName in testNames {
            if UIImage(named: testName) != nil {
                foundImages.append(testName)
                print("✅ Found: \(testName)")
            } else {
                print("❌ Missing: \(testName)")
            }
        }
        
        print("==============================")
        print("Found \(foundImages.count) images")
        
        if foundImages.isEmpty {
            print("💡 Suggestions:")
            print("   - Check that images are added to Assets.xcassets")
            print("   - Ensure Target Membership is set correctly")
            print("   - Try 'Clean Build Folder' in Xcode")
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Adds an AI Assistant avatar overlay
    /// - Parameters:
    ///   - size: Size of the avatar
    ///   - position: Position on screen
    ///   - onTap: Tap action
    /// - Returns: View with AI Assistant overlay
    func aiAssistantOverlay(
        size: CGFloat = 60,
        position: Alignment = .topTrailing,
        onTap: @escaping () -> Void = {}
    ) -> some View {
        self.overlay(
            Button(action: onTap) {
                AIAssistantImageLoader.circularAIAssistantView(
                    diameter: size,
                    borderColor: .white.opacity(0.3)
                )
            }
            .buttonStyle(PlainButtonStyle()),
            alignment: position
        )
    }
}

// MARK: - Preview Helper

struct AIAssistantImageLoader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Test different sizes
            AIAssistantImageLoader.circularAIAssistantView(diameter: 40)
            AIAssistantImageLoader.circularAIAssistantView(diameter: 60)
            AIAssistantImageLoader.circularAIAssistantView(diameter: 80, borderColor: .blue)
            
            // Test the debug function
            Button("Debug Available Assets") {
                AIAssistantImageLoader.debugAvailableAssets()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onAppear {
            // Automatically run debug on preview
            AIAssistantImageLoader.debugAvailableAssets()
        }
    }
}
