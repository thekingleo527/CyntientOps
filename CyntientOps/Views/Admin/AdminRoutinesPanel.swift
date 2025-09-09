//
//  AdminRoutinesPanel.swift
//  CyntientOps
//
//  Created by Gemini on 2025-09-08.
//

import SwiftUI

struct AdminRoutinesPanel: View {
    
    @StateObject var viewModel: AdminRoutinesViewModel
    @State private var lookahead: [RouteItem] = []
    @State private var loadedLookahead = false
    
    var body: some View {
        Group {
            if viewModel.routines.isEmpty && !lookahead.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming")
                        .font(.headline)
                    ForEach(lookahead.prefix(2), id: \.id) { item in
                        HStack {
                            Image(systemName: item.icon)
                            VStack(alignment: .leading) {
                                Text(item.buildingName)
                                    .font(.subheadline).fontWeight(.semibold)
                                Text(item.time)
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            } else {
                List(viewModel.routines, id: \.route.id) { workerRoutine in
                    Section(header: Text(workerRoutine.workerName)) {
                        ForEach(workerRoutine.route.sequences, id: \.id) { sequence in
                            VStack(alignment: .leading) {
                                Text(sequence.buildingName)
                                    .font(.headline)
                                Text("Arrival: \(sequence.arrivalTime, formatter: Self.timeFormatter)")
                                ForEach(sequence.operations, id: \.id) { operation in
                                    Text("- \(operation.name)")
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRoutines()
                if lookahead.isEmpty {
                    lookahead = await viewModel.computeLookahead(limit: 2)
                }
            }
        }
    }
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private func loadLookahead() async { /* superseded by viewModel.computeLookahead */ }
}
