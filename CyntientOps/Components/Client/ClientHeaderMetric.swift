
//
//  ClientHeaderMetric.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

struct ClientHeaderMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}
