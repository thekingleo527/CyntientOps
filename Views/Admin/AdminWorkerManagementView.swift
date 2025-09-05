//
//  AdminWorkerManagementView.swift
//  CyntientOps
//

import SwiftUI

public struct AdminWorkerManagementView: View {
    let clientBuildings: [CoreTypes.NamedCoordinate]
    
    public var body: some View {
        VStack {
            Text("Worker Management")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Worker management features will be implemented here")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}