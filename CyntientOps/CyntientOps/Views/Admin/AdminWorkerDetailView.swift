//
//  AdminWorkerDetailView.swift
//  CyntientOps
//

import SwiftUI

public struct AdminWorkerDetailView: View {
    let workerId: String
    let container: ServiceContainer
    
    public var body: some View {
        VStack {
            Text("Worker Detail")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Worker ID: \(workerId)")
                .foregroundColor(.secondary)
                
            Text("Worker details will be implemented here")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}