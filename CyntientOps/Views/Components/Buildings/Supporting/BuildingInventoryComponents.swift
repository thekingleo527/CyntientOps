
//
//  BuildingInventoryComponents.swift
//  CyntientOps v6.0
//
//  🏢 INVENTORY: Real-time stock tracking with GRDB integration
//  📦 RESTOCK: Automated low-stock alerts and reorder requests
//  🔄 SYNC: Cross-dashboard updates via DashboardSyncService
//

import SwiftUI
import Combine

// MARK: - Main Inventory Category Card

struct InventoryCategoryCard: View {
    let category: CoreTypes.InventoryCategory
    let items: [CoreTypes.InventoryItem]
    let buildingId: String
    @State private var isExpanded = true
    @State private var showingAddItem = false
    @State private var showingReorderRequest = false
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(category.displayName, systemImage: category.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Item count
                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                // Expand/collapse button
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    // Critical alerts first
                    let criticalItems = items.filter({ $0.needsRestock && $0.stockLevel < 0.2 })
                    if !criticalItems.isEmpty {
                        LowStockAlertBanner(
                            items: criticalItems,
                            onReorder: { showingReorderRequest = true }
                        )
                    }
                    
                    // Item list
                    ForEach(items) { item in
                        BuildingInventoryItemRow(
                            item: item,
                            buildingId: buildingId,
                            onQuantityChanged: { newQuantity in
                                updateItemQuantity(item: item, newQuantity: newQuantity)
                            }
                        )
                    }
                    
                    // Add item button (admin only)
                    if authManager.userRole == .admin {
                        Button(action: { showingAddItem = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Item")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemSheet(
                category: category,
                buildingId: buildingId,
                onSave: { newItem in
                    saveNewItem(newItem)
                }
            )
        }
        .sheet(isPresented: $showingReorderRequest) {
            ReorderRequestView(
                items: items.filter { $0.needsRestock },
                buildingId: buildingId
            )
        }
    }
    
    private func updateItemQuantity(item: CoreTypes.InventoryItem, newQuantity: Int) {
        Task {
            do {
                // Update in database via GRDB
                try await GRDBManager.shared.execute("""
                    UPDATE inventory_items 
                    SET current_stock = ?, updated_at = ?
                    WHERE id = ?
                """, [newQuantity, Date().ISO8601Format(), item.id])
                
                // Broadcast update
                let update = CoreTypes.DashboardUpdate(
                    source: .worker,
                    type: .inventoryUpdated,
                    buildingId: buildingId,
                    workerId: authManager.workerId ?? "",
                    data: [
                        "itemId": item.id,
                        "itemName": item.name,
                        "oldQuantity": String(item.currentStock),
                        "newQuantity": String(newQuantity),
                        "category": category.rawValue
                    ]
                )
                dashboardSync.broadcastWorkerUpdate(update)
                
            } catch {
                print("❌ Error updating inventory: \(error)")
            }
        }
    }
    
    private func saveNewItem(_ item: CoreTypes.InventoryItem) {
        Task {
            do {
                // Insert via GRDB
                try await GRDBManager.shared.execute("""
                    INSERT INTO inventory_items 
                    (id, name, category, current_stock, minimum_stock, max_stock, 
                     unit, building_id, created_at, updated_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, [
                    item.id,
                    item.name,
                    item.category.rawValue,
                    item.currentStock,
                    item.minimumStock,
                    item.maxStock ?? NSNull(),
                    item.unit,
                    buildingId,
                    Date().ISO8601Format(),
                    Date().ISO8601Format()
                ])
                
                print("✅ New inventory item saved: \(item.name)")
                
            } catch {
                print("❌ Error saving inventory item: \(error)")
            }
        }
    }
}

// MARK: - Individual Inventory Item Row

struct BuildingInventoryItemRow: View {
    let item: CoreTypes.InventoryItem
    let buildingId: String
    let onQuantityChanged: (Int) -> Void
    
    @State private var showingAdjuster = false
    @State private var currentQuantity: Int
    
    init(item: CoreTypes.InventoryItem, buildingId: String, onQuantityChanged: @escaping (Int) -> Void) {
        self.item = item
        self.buildingId = buildingId
        self.onQuantityChanged = onQuantityChanged
        self._currentQuantity = State(initialValue: item.currentStock)
    }
    
    var body: some View {
        HStack {
            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    // Current stock
                    Text("\(currentQuantity) \(item.unit)")
                        .font(.caption)
                        .foregroundColor(stockColor)
                    
                    // Minimum stock indicator
                    if item.needsRestock {
                        Label("Low", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Stock level visualization
            StockLevelIndicator(
                current: currentQuantity,
                minimum: item.minimumStock,
                maximum: item.maxStock > 0 ? item.maxStock : (item.minimumStock * 3)
            )
            .frame(width: 60)
            
            // Adjust button
            Button(action: { showingAdjuster = true }) {
                Image(systemName: "plus.minus.circle")
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
        .sheet(isPresented: $showingAdjuster) {
            QuantityAdjusterSheet(
                itemName: item.name,
                unit: item.unit,
                currentQuantity: currentQuantity,
                minimum: 0,
                maximum: item.maxStock ?? 999
            ) { newQuantity in
                currentQuantity = newQuantity
                onQuantityChanged(newQuantity)
            }
        }
    }
    
    private var stockColor: Color {
        if item.needsRestock {
            return item.stockLevel < 0.2 ? .red : .orange
        }
        return .white.opacity(0.8)
    }
}

// MARK: - Quantity Adjuster Sheet

struct QuantityAdjusterSheet: View {
    let itemName: String
    let unit: String
    let currentQuantity: Int
    let minimum: Int
    let maximum: Int
    let onSave: (Int) -> Void
    
    @State private var quantity: Int
    @State private var reason = ""
    @Environment(\.dismiss) private var dismiss
    
    init(itemName: String, unit: String, currentQuantity: Int, 
         minimum: Int, maximum: Int, onSave: @escaping (Int) -> Void) {
        self.itemName = itemName
        self.unit = unit
        self.currentQuantity = currentQuantity
        self.minimum = minimum
        self.maximum = maximum
        self.onSave = onSave
        self._quantity = State(initialValue: currentQuantity)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Item name
                Text(itemName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // Current vs New
                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentQuantity) \(unit)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("New")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(quantity) \(unit)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(changeColor)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Quantity selector
                VStack(spacing: 16) {
                    Text("Adjust Quantity")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        // Decrease button
                        Button(action: { adjustQuantity(-10) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(quantity > minimum ? .red : .gray)
                        }
                        .disabled(quantity <= minimum)
                        
                        Button(action: { adjustQuantity(-1) }) {
                            Image(systemName: "minus.circle")
                                .font(.title)
                                .foregroundColor(quantity > minimum ? .red : .gray)
                        }
                        .disabled(quantity <= minimum)
                        
                        // Quantity display
                        Text("\(quantity)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .frame(minWidth: 80)
                        
                        // Increase button
                        Button(action: { adjustQuantity(1) }) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundColor(quantity < maximum ? .green : .gray)
                        }
                        .disabled(quantity >= maximum)
                        
                        Button(action: { adjustQuantity(10) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(quantity < maximum ? .green : .gray)
                        }
                        .disabled(quantity >= maximum)
                    }
                    
                    // Quick select buttons
                    HStack(spacing: 12) {
                        ForEach([0, minimum, currentQuantity, maximum], id: \.self) { value in
                            if value >= minimum && value <= maximum {
                                Button(action: { quantity = value }) {
                                    Text("\(value)")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(quantity == value ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(quantity == value ? .white : .primary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // Reason field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("e.g., Weekly restock, Used for deep clean", text: $reason)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Adjust Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(quantity)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(quantity == currentQuantity)
                }
            }
        }
    }
    
    private func adjustQuantity(_ delta: Int) {
        let newQuantity = quantity + delta
        quantity = max(minimum, min(maximum, newQuantity))
    }
    
    private var changeColor: Color {
        if quantity == currentQuantity { return .primary }
        return quantity < currentQuantity ? .red : .green
    }
}

// MARK: - Reorder Request View

struct ReorderRequestView: View {
    let items: [CoreTypes.InventoryItem]
    let buildingId: String
    
    @State private var selectedItems: Set<String> = []
    @State private var urgency = "Normal"
    @State private var notes = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request Supply Reorder")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select items that need to be reordered")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Urgency selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Urgency")
                        .font(.headline)
                    
                    Picker("Urgency", selection: $urgency) {
                        Text("Normal").tag("Normal")
                        Text("Urgent").tag("Urgent")
                        Text("Critical").tag("Critical")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Items list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Items to Reorder")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                ReorderItemRow(
                                    item: item,
                                    isSelected: selectedItems.contains(item.id),
                                    onToggle: {
                                        if selectedItems.contains(item.id) {
                                            selectedItems.remove(item.id)
                                        } else {
                                            selectedItems.insert(item.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                // Notes field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Notes")
                        .font(.headline)
                    
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Submit button
                Button(action: submitRequest) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        Text(isSubmitting ? "Submitting..." : "Submit Request")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedItems.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(selectedItems.isEmpty || isSubmitting)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func submitRequest() {
        isSubmitting = true
        
        Task {
            // Create reorder request in database
            let requestId = UUID().uuidString
            let selectedItemsList = items.filter { selectedItems.contains($0.id) }
            
            // Broadcast to admin dashboard
            let update = CoreTypes.DashboardUpdate(
                source: .worker,
                type: .inventoryUpdated,
                buildingId: buildingId,
                workerId: authManager.workerId ?? "",
                data: [
                    "type": "reorderRequest",
                    "requestId": requestId,
                    "urgency": urgency,
                    "itemCount": String(selectedItems.count),
                    "items": selectedItemsList.map { $0.name }.joined(separator: ", "),
                    "notes": notes
                ]
            )
            dashboardSync.broadcastWorkerUpdate(update)
            
            // Simulate API call
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - Supporting Views

struct LowStockAlertBanner: View {
    let items: [CoreTypes.InventoryItem]
    let onReorder: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Low Stock Alert")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text("\(items.count) items need reordering")
                    .font(.caption2)
                    .foregroundColor(.orange.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: onReorder) {
                Text("Reorder")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
    }
}

struct AddInventoryItemSheet: View {
    let category: CoreTypes.InventoryCategory
    let buildingId: String
    let onSave: (CoreTypes.InventoryItem) -> Void
    
    @State private var itemName = ""
    @State private var unit = "units"
    @State private var currentStock = 0
    @State private var minimumStock = 10
    @State private var maxStock = 100
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    
                    Picker("Unit", selection: $unit) {
                        Text("Units").tag("units")
                        Text("Boxes").tag("boxes")
                        Text("Cases").tag("cases")
                        Text("Gallons").tag("gallons")
                        Text("Pounds").tag("lbs")
                        Text("Each").tag("each")
                    }
                }
                
                Section(header: Text("Stock Levels")) {
                    Stepper("Current Stock: \(currentStock)", value: $currentStock, in: 0...999)
                    Stepper("Minimum Stock: \(minimumStock)", value: $minimumStock, in: 1...999)
                    Stepper("Maximum Stock: \(maxStock)", value: $maxStock, in: 1...999)
                }
                
                Section(header: Text("Category")) {
                    HStack {
                        Image(systemName: category.icon)
                        Text(category.displayName)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Inventory Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newItem = CoreTypes.InventoryItem(
                            id: UUID().uuidString,
                            name: itemName,
                            category: category,
                            currentStock: currentStock,
                            minimumStock: minimumStock,
                            maxStock: maxStock,
                            unit: unit,
                            lastRestocked: nil
                        )
                        onSave(newItem)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
}

struct InventoryHistoryChart: View {
    let buildingId: String
    let category: CoreTypes.InventoryCategory
    @State private var historyData: [InventoryHistoryPoint] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Trends - \(category.displayName)")
                .font(.headline)
                .foregroundColor(.white)
            
            if isLoading {
                ProgressView("Loading history...")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else if historyData.isEmpty {
                Text("No history data available")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                // Placeholder for chart - would use Swift Charts in iOS 16+
                VStack(spacing: 8) {
                    ForEach(historyData.suffix(7)) { point in
                        HStack {
                            Text(point.date, format: .dateTime.month().day())
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 60, alignment: .leading)
                            
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(Color.blue.opacity(0.6))
                                    .frame(width: geometry.size.width * point.usagePercentage)
                            }
                            .frame(height: 20)
                            
                            Text("\(point.itemsUsed)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .task {
            await loadHistory()
        }
    }
    
    private func loadHistory() async {
        // TODO: Implement actual history loading from GRDB
        isLoading = false
        // Mock data for now
        historyData = (0..<30).map { dayOffset in
            InventoryHistoryPoint(
                date: Date().addingTimeInterval(-Double(dayOffset) * 86400),
                itemsUsed: Int.random(in: 5...25),
                usagePercentage: Double.random(in: 0.2...1.0)
            )
        }
    }
}

struct StockLevelIndicator: View {
    let current: Int
    let minimum: Int
    let maximum: Int
    
    private var fillPercentage: Double {
        guard maximum > 0 else { return 0 }
        return Double(current) / Double(maximum)
    }
    
    private var minimumLinePosition: Double {
        guard maximum > 0 else { return 0 }
        return Double(minimum) / Double(maximum)
    }
    
    private var stockColor: Color {
        if current <= 0 { return .red }
        if current < minimum { return .orange }
        if fillPercentage > 0.8 { return .green }
        return .blue
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                
                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(stockColor.opacity(0.6))
                    .frame(width: geometry.size.width * fillPercentage)
                
                // Minimum line
                Rectangle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 2)
                    .offset(x: geometry.size.width * minimumLinePosition - 1)
            }
        }
        .frame(height: 8)
    }
}

struct ReorderItemRow: View {
    let item: CoreTypes.InventoryItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text("Current: \(item.currentStock) \(item.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Min: \(item.minimumStock)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Stock criticality indicator
            if item.stockLevel < 0.2 {
                Label("Critical", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

struct InventoryHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let itemsUsed: Int
    let usagePercentage: Double
}

extension CoreTypes.InventoryItem {
    var stockLevel: Double {
        guard minimumStock > 0 else { return 1.0 }
        return Double(currentStock) / Double(minimumStock)
    }
    
    var needsRestock: Bool {
        return currentStock <= minimumStock
    }
}
