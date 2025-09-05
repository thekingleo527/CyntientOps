//
//  RouteStatItem.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 6/5/25.
//

// RouteStatItem.swift
// Create this as a new file in the Components folder

import SwiftUI
// CyntientOps Types Import
// (This comment helps identify our import)

struct RouteStatItem: View {
    let title: String
    let value: String
    var color: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}
