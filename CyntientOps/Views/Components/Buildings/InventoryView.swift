//
//  InventoryView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Removed duplicate CoreTypes.InventoryCategory - now uses CoreTypes version
//  ✅ FIXED: Added type aliases to avoid conflicts
//  ✅ DARK ELEGANCE: Full CyntientOpsDesign implementation
//  ✅ GLASS MORPHISM: Consistent with system design
//  ✅ ANIMATIONS: Smooth transitions and effects
//  ✅ ACCESSIBILITY: High contrast options maintained
//

import SwiftUI

// MARK: - Using CoreTypes definitions (globally available)

// MARK: - Main View

public struct InventoryView: View {
    public let buildingId: String
    public let buildingName: String
    
    @State private var inventoryItems: [CoreTypes.InventoryItem] = []
    @State private var filteredItems: [CoreTypes.InventoryItem] = []
    @State private var selectedCategory: CoreTypes.InventoryCategory = .supplies
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var showingStockAlert = false
    @State private var lowStockItems: [CoreTypes.InventoryItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var animateCards = false
    
    private var categories: [CoreTypes.InventoryCategory] = CoreTypes.InventoryCategory.allCases
    
    internal init(buildingId: String, buildingName: String) {
        self.buildingId = buildingId
        self.buildingName = buildingName
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                // Dark elegant background
                CyntientOpsDesign.DashboardGradients.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(message: error)
                    } else {
                        inventoryContent
                    }
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search inventory...")
            .onChange(of: searchText) { _, _ in filterItems() }
            .onChange(of: selectedCategory) { _, _ in filterItems() }
            .sheet(isPresented: $showingAddItem) {
                AddInventoryItemView(buildingId: buildingId) { success in
                    showingAddItem = false
                    if success {
                        loadInventoryData()
                    }
                }
            }
            .alert("Low Stock Alert", isPresented: $showingStockAlert) {
                Button("OK") { }
                Button("Reorder") {
                    // Handle reorder action
                }
            } message: {
                Text("\(lowStockItems.count) items are running low on stock")
            }
            .task {
                loadInventoryData()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(CyntientOpsDesign.DashboardColors.primaryAction)
            
            Text("Loading inventory...")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            
            Text("Error Loading Inventory")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(message)
                .font(.body)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: loadInventoryData) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(CyntientOpsDesign.DashboardColors.primaryAction)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var inventoryContent: some View {
        VStack(spacing: 0) {
            // Stats overview
            inventoryStatsHeader
                .animatedGlassAppear(delay: 0.1)
            
            // Category filter
            categoryFilter
                .animatedGlassAppear(delay: 0.2)
            
            // Inventory list
            inventoryList
        }
    }
    
    private var inventoryStatsHeader: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total Items",
                value: "\(inventoryItems.count)",
                icon: "cube.box.fill",
                color: CyntientOpsDesign.DashboardColors.info
            )
            
            StatCard(
                title: "Low Stock",
                value: "\(lowStockItems.count)",
                icon: "exclamationmark.triangle.fill",
                color: CyntientOpsDesign.DashboardColors.warning
            )
            
            StatCard(
                title: "Total Value",
                value: totalInventoryValue.formatted(.currency(code: "USD")),
                icon: "dollarsign.circle.fill",
                color: CyntientOpsDesign.DashboardColors.success
            )
        }
        .padding()
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                        .stroke(CyntientOpsDesign.DashboardColors.glassOverlay, lineWidth: 1)
                )
        )
    }
    
    private var inventoryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredItems.isEmpty {
                    EmptyStateView(category: selectedCategory)
                        .padding(.top, 60)
                } else {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        InventoryItemRow(item: item) { updatedItem in
                            updateInventoryItem(updatedItem)
                        }
                        .animatedGlassAppear(delay: Double(index) * 0.05)
                    }
                }
            }
            .padding()
        }
    }
    
    private func loadInventoryData() {
        isLoading = true
        errorMessage = nil
        animateCards = false
        
        // Simulate data loading with sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            inventoryItems = [
                CoreTypes.InventoryItem(
                    name: "All-Purpose Cleaner",
                    category: .supplies,
                    currentStock: 5,
                    minimumStock: 10,
                    maxStock: 50,
                    unit: "bottle",
                    cost: 4.99,
                    location: "Storage Room A"
                ),
                CoreTypes.InventoryItem(
                    name: "Vacuum Cleaner",
                    category: .equipment,
                    currentStock: 2,
                    minimumStock: 1,
                    maxStock: 5,
                    unit: "unit",
                    cost: 199.99,
                    location: "Equipment Closet"
                ),
                CoreTypes.InventoryItem(
                    name: "Safety Goggles",
                    category: .safety,
                    currentStock: 8,
                    minimumStock: 5,
                    maxStock: 20,
                    unit: "pair",
                    cost: 12.50,
                    location: "Safety Cabinet"
                ),
                CoreTypes.InventoryItem(
                    name: "Screwdriver Set",
                    category: .tools,
                    currentStock: 3,
                    minimumStock: 2,
                    maxStock: 10,
                    unit: "set",
                    cost: 45.00,
                    location: "Tool Storage"
                ),
                CoreTypes.InventoryItem(
                    name: "Light Bulbs (LED)",
                    category: .supplies,
                    currentStock: 15,
                    minimumStock: 20,
                    maxStock: 100,
                    unit: "piece",
                    cost: 8.00,
                    location: "Electrical Supply"
                ),
                CoreTypes.InventoryItem(
                    name: "Concrete Patch",
                    category: .materials,
                    currentStock: 6,
                    minimumStock: 3,
                    maxStock: 20,
                    unit: "bag",
                    cost: 25.00,
                    location: "Materials Storage"
                )
            ]
            
            // Check for low stock items
            lowStockItems = inventoryItems.filter { $0.currentStock <= $0.minimumStock }
            
            filterItems()
            isLoading = false
            
            withAnimation(.spring(response: 0.4)) {
                animateCards = true
            }
            
            if !lowStockItems.isEmpty {
                showingStockAlert = true
            }
        }
    }
    
    private func filterItems() {
        var filtered = inventoryItems
        
        // Filter by category
        if selectedCategory != .other {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.location ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredItems = filtered.sorted { $0.name < $1.name }
    }
    
    private func updateInventoryItem(_ item: CoreTypes.InventoryItem) {
        if let index = inventoryItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation {
                inventoryItems[index] = item
            }
            filterItems()
        }
    }
    
    private var totalInventoryValue: Double {
        return inventoryItems.reduce(into: 0.0) { total, item in
            total += Double(item.currentStock) * item.cost
        }
    }
}

// MARK: - Supporting Views

// StatCard is imported from Components/Cards/StatCard.swift

public struct CategoryButton: View {
    internal let category: CoreTypes.InventoryCategory
    public let isSelected: Bool
    public let action: () -> Void
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(
                isSelected ? .white : CyntientOpsDesign.DashboardColors.secondaryText
            )
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [CyntientOpsDesign.DashboardColors.primaryAction, CyntientOpsDesign.DashboardColors.primaryAction.opacity(0.8)], 
                            startPoint: .topLeading, 
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.05)
                    }
                }
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

public struct InventoryItemRow: View {
    public let item: CoreTypes.InventoryItem
    public let onUpdate: (CoreTypes.InventoryItem) -> Void
    
    @State private var showingDetail = false
    @State private var isPressed = false
    
    public var body: some View {
        Button(action: { showingDetail = true }) {
            HStack(spacing: 16) {
                // Category icon with glass background
                ZStack {
                    Circle()
                        .fill(item.category.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: item.category.icon)
                        .font(.title3)
                        .foregroundColor(item.category.color)
                }
                
                // Item details
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    HStack(spacing: 12) {
                        Label(item.location ?? "No location", systemImage: "location")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        
                        Spacer()
                        
                        StockIndicator(
                            current: item.currentStock,
                            minimum: item.minimumStock,
                            status: item.status
                        )
                    }
                }
                
                // Stock count
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(item.currentStock)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(item.unit)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding()
            .francoDarkCardBackground()
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.1) {
            // Long press action if needed
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .sheet(isPresented: $showingDetail) {
            InventoryItemDetailView(item: item, onUpdate: onUpdate)
        }
    }
}

public struct StockIndicator: View {
    public let current: Int
    public let minimum: Int
    public let status: CoreTypes.RestockStatus
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                        .blur(radius: 4)
                        .opacity(0.6)
                )
            
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .inStock: return CyntientOpsDesign.DashboardColors.success
        case .lowStock: return CyntientOpsDesign.DashboardColors.warning
        case .outOfStock: return CyntientOpsDesign.DashboardColors.critical
        case .ordered: return CyntientOpsDesign.DashboardColors.info
        }
    }
}

public struct EmptyStateView: View {
    internal let category: CoreTypes.InventoryCategory
    
    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: category.icon)
                    .font(.system(size: 48))
                    .foregroundColor(category.color)
            }
            
            VStack(spacing: 8) {
                Text("No \(category.displayName) Items")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("Add items to track inventory for this category")
                    .font(.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Add Inventory Item View

public struct AddInventoryItemView: View {
    public let buildingId: String
    public let onComplete: (Bool) -> Void
    
    @State private var itemName = ""
    @State private var itemDescription = ""
    @State private var selectedCategory: CoreTypes.InventoryCategory = .supplies
    @State private var quantity = 1
    @State private var minimumStock = 5
    @State private var maxStock = 50
    @State private var unit = "unit"
    @State private var supplier = ""
    @State private var costPerUnit: Double = 0.0
    @State private var isSubmitting = false
    @State private var location = "Storage"
    
    @Environment(\.dismiss) private var dismiss
    
    private let commonUnits = ["unit", "box", "bottle", "pack", "case", "piece", "gallon", "liter"]
    
    public var body: some View {
        NavigationView {
            ZStack {
                CyntientOpsDesign.DashboardGradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        itemDetailsSection
                        quantityStockSection
                        categoryDetailsSection
                        supplierCostSection
                        submitSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Inventory Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var itemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Item Details")
            
            VStack(spacing: 16) {
                FloatingTextField(
                    text: $itemName,
                    placeholder: "Item Name",
                    icon: "cube.box"
                )
                
                FloatingTextField(
                    text: $itemDescription,
                    placeholder: "Description (optional)",
                    icon: "text.alignleft",
                    axis: .vertical
                )
            }
            .padding()
            .francoDarkCardBackground()
        }
    }
    
    private var quantityStockSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Quantity & Stock")
            
            VStack(spacing: 16) {
                StepperRow(
                    title: "Initial Quantity",
                    value: $quantity,
                    range: 0...1000
                )
                
                StepperRow(
                    title: "Minimum Stock",
                    value: $minimumStock,
                    range: 1...100
                )
                
                StepperRow(
                    title: "Maximum Stock",
                    value: $maxStock,
                    range: minimumStock...1000
                )
                
                HStack {
                    Label("Unit", systemImage: "scalemass")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Picker("Unit", selection: $unit) {
                        ForEach(commonUnits, id: \.self) { unitOption in
                            Text(unitOption).tag(unitOption)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
    }
    
    private var categoryDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Category & Details")
            
            VStack(spacing: 16) {
                // Category Picker
                HStack {
                    Label("Category", systemImage: "tag")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(CoreTypes.InventoryCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Label(category.displayName, systemImage: category.icon)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: selectedCategory.icon)
                                .foregroundColor(selectedCategory.color)
                            Text(selectedCategory.displayName)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                FloatingTextField(
                    text: $location,
                    placeholder: "Storage Location",
                    icon: "location"
                )
            }
            .padding()
            .francoDarkCardBackground()
        }
    }
    
    private var supplierCostSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Supplier & Cost")
            
            VStack(spacing: 16) {
                FloatingTextField(
                    text: $supplier,
                    placeholder: "Supplier (optional)",
                    icon: "shippingbox"
                )
                
                HStack {
                    Label("Cost per Unit", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    TextField("0.00", value: $costPerUnit, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
    }
    
    private var submitSection: some View {
        Button(action: addItem) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Item")
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if itemName.isEmpty {
                        Color.gray.opacity(0.3)
                    } else {
                        LinearGradient(
                            colors: [CyntientOpsDesign.DashboardColors.primaryAction, CyntientOpsDesign.DashboardColors.primaryAction.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(itemName.isEmpty || isSubmitting)
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
    }
    
    private func addItem() {
        isSubmitting = true
        
        let newItem = CoreTypes.InventoryItem(
            name: itemName,
            category: selectedCategory,
            currentStock: quantity,
            minimumStock: minimumStock,
            maxStock: maxStock,
            unit: unit,
            cost: costPerUnit,
            supplier: supplier.isEmpty ? nil : supplier,
            location: location.isEmpty ? "Storage" : location
        )
        
        // TODO: Save item to database
        print("Adding inventory item: \(newItem)")
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onComplete(true)
        }
    }
}

// MARK: - Helper Components

struct FloatingTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var axis: Axis = .horizontal
    
    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                .frame(width: 20)
            
            if axis == .vertical {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(2...4)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
        }
    }
}

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { if value > range.lowerBound { value -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(
                            value > range.lowerBound ?
                            CyntientOpsDesign.DashboardColors.primaryAction :
                            CyntientOpsDesign.DashboardColors.tertiaryText
                        )
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .frame(minWidth: 40)
                
                Button(action: { if value < range.upperBound { value += 1 } }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(
                            value < range.upperBound ?
                            CyntientOpsDesign.DashboardColors.primaryAction :
                            CyntientOpsDesign.DashboardColors.tertiaryText
                        )
                }
                .disabled(value >= range.upperBound)
            }
        }
    }
}

// MARK: - Inventory Item Detail View

public struct InventoryItemDetailView: View {
    public let item: CoreTypes.InventoryItem
    public let onUpdate: (CoreTypes.InventoryItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentStock: Int
    @State private var isUpdating = false
    @State private var showingEditMode = false
    @State private var adjustmentAmount = 0
    
    internal init(item: CoreTypes.InventoryItem, onUpdate: @escaping (CoreTypes.InventoryItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        self._currentStock = State(initialValue: item.currentStock)
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                CyntientOpsDesign.DashboardGradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header with item icon and name
                        itemHeaderView
                            .animatedGlassAppear(delay: 0.1)
                        
                        // Stock status card
                        stockStatusCard
                            .animatedGlassAppear(delay: 0.2)
                        
                        // Quick adjustment buttons
                        quickAdjustmentSection
                            .animatedGlassAppear(delay: 0.3)
                        
                        // Item details
                        itemDetailsSection
                            .animatedGlassAppear(delay: 0.4)
                        
                        // Cost information
                        costInformationSection
                            .animatedGlassAppear(delay: 0.5)
                    }
                    .padding()
                }
            }
            .navigationTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showingEditMode = true }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var itemHeaderView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(item.category.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: item.category.icon)
                    .font(.system(size: 40))
                    .foregroundColor(item.category.color)
            }
            
            Text(item.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var stockStatusCard: some View {
        VStack(spacing: 20) {
            // Current stock display
            VStack(spacing: 8) {
                Text("Current Stock")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(currentStock)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(stockStatusColor)
                    
                    Text(item.unit)
                        .font(.title3)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        .padding(.bottom, 8)
                }
                
                StockIndicator(
                    current: currentStock,
                    minimum: item.minimumStock,
                    status: currentStockStatus
                )
            }
            
            // Stock level progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stock Level")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(stockPercentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stockStatusColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(stockStatusColor)
                            .frame(width: geometry.size.width * (stockPercentage / 100), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("Min: \(item.minimumStock)")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                    
                    Text("Max: \(item.maxStock)")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var quickAdjustmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Adjust")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            HStack(spacing: 12) {
                QuickAdjustButton(amount: -10, action: { adjustStock(by: -10) })
                QuickAdjustButton(amount: -5, action: { adjustStock(by: -5) })
                QuickAdjustButton(amount: -1, action: { adjustStock(by: -1) })
                QuickAdjustButton(amount: 1, action: { adjustStock(by: 1) })
                QuickAdjustButton(amount: 5, action: { adjustStock(by: 5) })
                QuickAdjustButton(amount: 10, action: { adjustStock(by: 10) })
            }
        }
    }
    
    private var itemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Item Information")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                DetailRow(label: "Category", value: item.category.displayName, icon: "tag")
                DetailRow(label: "Location", value: item.location ?? "Not specified", icon: "location")
                DetailRow(label: "Unit", value: item.unit, icon: "scalemass")
                
                if let supplier = item.supplier {
                    DetailRow(label: "Supplier", value: supplier, icon: "shippingbox")
                }
                
                if let lastRestocked = item.lastRestocked {
                    DetailRow(
                        label: "Last Restocked",
                        value: lastRestocked.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar"
                    )
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
    }
    
    private var costInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Information")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                HStack {
                    Label("Cost per Unit", systemImage: "dollarsign.circle")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text(item.cost.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                HStack {
                    Label("Total Value", systemImage: "creditcard")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text(totalValue.formatted(.currency(code: "USD")))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                }
            }
            .padding()
            .francoDarkCardBackground()
        }
    }
    
    // MARK: - Helper Properties & Methods
    
    private var currentStockStatus: CoreTypes.RestockStatus {
        if currentStock <= 0 {
            return .outOfStock
        } else if currentStock <= item.minimumStock {
            return .lowStock
        } else {
            return .inStock
        }
    }
    
    private var stockStatusColor: Color {
        switch currentStockStatus {
        case .inStock: return CyntientOpsDesign.DashboardColors.success
        case .lowStock: return CyntientOpsDesign.DashboardColors.warning
        case .outOfStock: return CyntientOpsDesign.DashboardColors.critical
        case .ordered: return CyntientOpsDesign.DashboardColors.info
        }
    }
    
    private var stockPercentage: Double {
        let percentage = (Double(currentStock) / Double(item.maxStock)) * 100
        return min(100, max(0, percentage))
    }
    
    private var totalValue: Double {
        return Double(currentStock) * item.cost
    }
    
    private func adjustStock(by amount: Int) {
        let newStock = currentStock + amount
        if newStock >= 0 && newStock <= item.maxStock {
            withAnimation(.spring(response: 0.3)) {
                currentStock = newStock
            }
            updateItem()
        }
    }
    
    private func updateItem() {
        let updatedItem = CoreTypes.InventoryItem(
            id: item.id,
            name: item.name,
            category: item.category,
            currentStock: currentStock,
            minimumStock: item.minimumStock,
            maxStock: item.maxStock,
            unit: item.unit,
            cost: item.cost,
            supplier: item.supplier,
            location: item.location,
            lastRestocked: currentStock > item.currentStock ? Date() : item.lastRestocked
        )
        
        onUpdate(updatedItem)
    }
}

// MARK: - Detail View Components

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
}

struct QuickAdjustButton: View {
    let amount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(amount > 0 ? "+\(amount)" : "\(amount)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(
                    amount > 0 ?
                    CyntientOpsDesign.DashboardColors.success :
                    CyntientOpsDesign.DashboardColors.warning
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    (amount > 0 ?
                     CyntientOpsDesign.DashboardColors.success :
                     CyntientOpsDesign.DashboardColors.warning
                    ).opacity(0.1)
                )
                .cornerRadius(8)
        }
    }
}

// MARK: - Extensions

extension CoreTypes.InventoryCategory {
    var icon: String {
        switch self {
        case .tools: return "wrench.and.screwdriver"
        case .supplies: return "shippingbox"
        case .equipment: return "gear"
        case .materials: return "cube.box"
        case .safety: return "shield"
        case .cleaning: return "sparkles"
        case .electrical: return "bolt.circle"
        case .plumbing: return "drop.circle"
        case .general: return "square.grid.2x2"
        case .office: return "paperclip"
        case .maintenance: return "hammer"
        case .other: return "folder"
        @unknown default: return "questionmark.folder"
        }
    }
    
    var color: Color {
        switch self {
        case .tools: return .orange
        case .supplies: return .blue
        case .equipment: return .purple
        case .materials: return .brown
        case .safety: return .red
        case .cleaning: return .green
        case .electrical: return .yellow
        case .plumbing: return .cyan
        case .general: return .gray
        case .office: return .indigo
        case .maintenance: return .mint
        case .other: return .gray
        @unknown default: return .gray
        }
    }
    
    var displayName: String {
        switch self {
        case .tools: return "Tools"
        case .supplies: return "Supplies"
        case .equipment: return "Equipment"
        case .materials: return "Materials"
        case .safety: return "Safety"
        case .cleaning: return "Cleaning"
        case .electrical: return "Electrical"
        case .plumbing: return "Plumbing"
        case .general: return "General"
        case .office: return "Office"
        case .maintenance: return "Maintenance"
        case .other: return "Other"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Preview

struct InventoryView_Previews: PreviewProvider {
    static var previews: some View {
        InventoryView(
            buildingId: "14",
            buildingName: "Rubin Museum"
        )
        .preferredColorScheme(.dark)
    }
}
