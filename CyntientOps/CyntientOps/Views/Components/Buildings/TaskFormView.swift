
import Foundation

// Type aliases for CoreTypes

// CyntientOps Types Import
// (This comment helps identify our import)

//
//  TaskFormView.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 3/13/25.
//

import SwiftUI

// Type aliases for CoreTypes

// CyntientOps Types Import
// (This comment helps identify our import)

struct TaskFormView: View {
    let buildingID: String
    var onTaskCreated: ((MaintenanceTask) -> Void)?
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                    TextField("Task Description", text: $taskDescription)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Create a new task with basic data. Customize as needed.
                        let newTask = MaintenanceTask(
                            title: taskName,
                            description: taskDescription,
                            category: .maintenance,
                            urgency: .medium,
                            buildingId: buildingID,
                            dueDate: Date()
                        )
                        onTaskCreated?(newTask)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
