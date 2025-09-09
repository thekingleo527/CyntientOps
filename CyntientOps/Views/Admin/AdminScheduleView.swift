import SwiftUI

public struct AdminScheduleView: View {
    @StateObject private var vm: PortfolioScheduleViewModel
    @State private var viewMode: ViewMode = .week
    @State private var selectedWeekRef = Date()
    @State private var selectedWorkerId: String? = nil
    @State private var selectedBuildingId: String? = nil
    @State private var weatherOptimized: Bool = false
    @State private var workerList: [CoreTypes.WorkerProfile] = []
    @State private var buildingList: [CoreTypes.NamedCoordinate] = []

    private let container: ServiceContainer

    public init(container: ServiceContainer) {
        self.container = container
        _vm = StateObject(wrappedValue: PortfolioScheduleViewModel(container: container))
    }

    public var body: some View {
        VStack(spacing: 12) {
            header
            content
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
        .task {
            await vm.loadWeek(starting: selectedWeekRef)
            await loadReferenceLists()
        }
        .onChange(of: selectedWeekRef) { _, new in Task { await reload(for: new) } }
        .onChange(of: selectedWorkerId) { _, new in vm.filterWorkerId = new; Task { await reload(for: selectedWeekRef) } }
        .onChange(of: selectedBuildingId) { _, new in vm.filterBuildingId = new; Task { await reload(for: selectedWeekRef) } }
    }

    private func reload(for ref: Date) async {
        if viewMode == .week { await vm.loadWeek(starting: ref) } else { await vm.loadMonth(reference: ref) }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Schedule")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
                Picker("View", selection: $viewMode) {
                    Text("Week").tag(ViewMode.week)
                    Text("Month").tag(ViewMode.month)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            HStack(spacing: 12) {
                DatePicker("Week", selection: $selectedWeekRef, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                Spacer()
                workerPicker
                buildingPicker
                Toggle("Weather optimized", isOn: $weatherOptimized)
                    .toggleStyle(.switch)
                    .onChange(of: weatherOptimized) { _, new in
                        vm.useWeatherOptimized = new
                        Task { await reload(for: selectedWeekRef) }
                    }
            }
        }
        .cyntientOpsDarkCardBackground()
    }

    private var content: some View {
        Group {
            switch viewMode {
            case .week:
                ScrollView {
                    ForEach(vm.weekSections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            ForEach(section.items) { item in
                                ScheduleRow(item: item, container: container)
                            }
                        }
                        .padding()
                        .cyntientOpsDarkCardBackground()
                        .padding(.bottom, 8)
                    }
                }
            case .month:
                MonthGridView(reference: selectedWeekRef, dayMap: vm.monthMap) { day in
                    if let items = vm.monthMap[day], !items.isEmpty {
                        ForEach(items.prefix(3)) { it in
                            ScheduleRow(item: it, container: container)
                        }
                    } else {
                        Text("No items")
                            .font(.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                }
                .task { await vm.loadMonth(reference: selectedWeekRef) }
            }
        }
    }

    private var workerPicker: some View {
        Menu {
            Button("All Workers") { selectedWorkerId = nil }
            ForEach(workerList, id: \.id) { w in
                Button(w.name) { selectedWorkerId = w.id }
            }
        } label: {
            Label(selectedWorkerId == nil ? "All Workers" : (CanonicalIDs.Workers.getName(for: selectedWorkerId!) ?? "Worker"), systemImage: "person.2")
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }

    private var buildingPicker: some View {
        Menu {
            Button("All Buildings") { selectedBuildingId = nil }
            ForEach(buildingList, id: \.id) { b in
                Button(b.name) { selectedBuildingId = b.id }
            }
        } label: {
            Label(selectedBuildingId == nil ? "All Buildings" : (buildingList.first { $0.id == selectedBuildingId }?.name ?? "Building"), systemImage: "building.2")
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }

enum ViewMode { case week, month }
}

private struct MonthGridView<Content: View>: View {
    let reference: Date
    let dayMap: [Int: [PortfolioScheduleViewModel.ScheduleItem]]
    let cellContent: (Int) -> Content

    init(reference: Date,
         dayMap: [Int: [PortfolioScheduleViewModel.ScheduleItem]],
         @ViewBuilder cellContent: @escaping (Int) -> Content) {
        self.reference = reference
        self.dayMap = dayMap
        self.cellContent = cellContent
    }
    
    var body: some View {
        let cal = Calendar.current
        let range: Range<Int> = cal.range(of: .day, in: .month, for: reference) ?? (1..<29)
        let components = cal.dateComponents([.year, .month], from: reference)
        let firstOfMonth = cal.date(from: components) ?? reference
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (weekdayOfFirst - cal.firstWeekday + 7) % 7
        
        let days = Array(repeating: 0, count: leadingEmpty) + Array(range)
        let rows = stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0+7, days.count)]) }
        
        return VStack(spacing: 8) {
            HStack {
                ForEach(["Sun","Mon","Tue","Wed","Thu","Fri","Sat"], id: \.self) { d in
                    Text(d).font(.caption2).foregroundColor(.secondary).frame(maxWidth: .infinity)
                }
            }
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(alignment: .top, spacing: 6) {
                    ForEach(rows[r], id: \.self) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            if day > 0 {
                                Text("\(day)").font(.caption).foregroundColor(.secondary)
                                cellContent(day)
                            } else {
                                Spacer(minLength: 20)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
                        .padding(6)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(8)
        .cyntientOpsDarkCardBackground()
    }
}

private struct ScheduleRow: View {
    let item: PortfolioScheduleViewModel.ScheduleItem
    let container: ServiceContainer
    @State private var dsnyText: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(item.startTime.formatted(date: .omitted, time: .shortened)) - \(item.endTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                HStack(spacing: 6) {
                    Chip(text: item.buildingName, color: .blue)
                    Chip(text: item.workerName, color: .gray)
                    if let dsnyText { Chip(text: dsnyText, color: CyntientOpsDesign.DashboardColors.warning) }
                }
            }
            Spacer()
        }
        .padding(10)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .task { await computeDSNYIfNeeded() }
    }

    private func computeDSNYIfNeeded() async {
        guard dsnyText == nil else { return }
        // Try compliance cache first
        if !container.nycCompliance.getDSNYSchedule(for: item.buildingId).isEmpty {
            // Best-effort label from compliance windows
            await MainActor.run { dsnyText = "DSNY 8p–12p" }
            return
        }
        // Resolve NamedCoordinate
        if let building = try? await container.buildings.getBuilding(buildingId: item.buildingId) {
            if let schedule = try? await DSNYAPIService.shared.getSchedule(for: building) {
                let label = buildDSNYWindowLabel(schedule: schedule)
                await MainActor.run { dsnyText = label }
            }
        }
    }

    private func buildDSNYWindowLabel(schedule: DSNY.BuildingSchedule) -> String {
        // Compose per-category window times if present; fallback to generic
        var parts: [String] = []
        func add(_ type: DSNY.CollectionType, name: String) {
            if let w = schedule.complianceWindows[type] {
                // Attempt to use human-readable fields if available via mirror
                let setOut = Mirror(reflecting: w).children.first { $0.label == "setOutTime" }?.value as? String ?? "8 PM"
                let pickup = Mirror(reflecting: w).children.first { $0.label == "pickupTime" }?.value as? String ?? "12 PM"
                parts.append("\(name): after \(setOut) • by \(pickup)")
            }
        }
        add(.refuse, name: "Refuse")
        add(.recycling, name: "Recycling")
        add(.organics, name: "Organics")
        return parts.isEmpty ? "DSNY 8p–12p" : parts.joined(separator: "; ")
    }
}

// MARK: - Private helpers
extension AdminScheduleView {
    fileprivate func loadReferenceLists() async {
        let workers = (try? await container.operationalData.fetchAllWorkers()) ?? []
        let buildings = (try? await container.operationalData.fetchAllBuildings()) ?? []
        self.workerList = workers
        self.buildingList = buildings
    }
}

private struct Chip: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
