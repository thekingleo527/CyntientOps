
//
//  ClientPortfolioMetric.swift
//  CyntientOps
//
//  Created by Gemini on 2025-08-17.
//

import SwiftUI

public struct ClientPortfolioMetric: View {
    let title: String
    let value: String
    let color: Color
    
    public var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
