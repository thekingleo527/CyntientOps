//
//  VendorAccessLogSheetLight.swift
//  CyntientOps
//
//  Lightweight vendor access logging sheet for workers
//

import SwiftUI

struct VendorAccessLogSheetLight: View {
    @ObservedObject var viewModel: WorkerDashboardViewModel
    var onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var vendorName = ""
    @State private var vendorCompany = ""
    @State private var vendorType: WorkerDashboardViewModel.VendorType = .other
    @State private var accessType: WorkerDashboardViewModel.VendorAccessType = .routine
    @State private var accessDetails = ""
    @State private var notes = ""
    @State private var selectedBuildingId: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Building")) {
                    Picker("Location", selection: $selectedBuildingId) {
                        ForEach(viewModel.assignedBuildings, id: \.id) { b in
                            Text(b.name).tag(b.id)
                        }
                    }
                }
                Section(header: Text("Vendor")) {
                    TextField("Name", text: $vendorName)
                    TextField("Company", text: $vendorCompany)
                    Picker("Type", selection: $vendorType) {
                        ForEach(WorkerDashboardViewModel.VendorType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                }
                Section(header: Text("Access")) {
                    Picker("Access Type", selection: $accessType) {
                        ForEach(WorkerDashboardViewModel.VendorAccessType.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    TextField("Details (suite, purpose)", text: $accessDetails)
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Vendor Access")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss(); onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(vendorName.isEmpty || selectedBuildingId.isEmpty)
                }
            }
            .onAppear {
                selectedBuildingId = viewModel.currentBuilding?.id ?? viewModel.assignedBuildings.first?.id ?? ""
            }
        }
    }

    private func save() {
        Task {
            await viewModel.logVendorAccess(
                buildingId: selectedBuildingId,
                vendorName: vendorName,
                vendorCompany: vendorCompany,
                vendorType: vendorType,
                accessType: accessType,
                accessDetails: accessDetails,
                notes: notes
            )
            dismiss(); onDismiss()
        }
    }
}

