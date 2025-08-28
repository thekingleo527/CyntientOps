//
//  IntelligencePanel.swift
//  CyntientOps v6.0
//
//  ✅ INTELLIGENCE PANEL: Bottom panel for all dashboards
//  ✅ THREE STATES: Mini (tab bar), Expanded (accordion), Full (map mode)
//  ✅ ROLE-BASED: Different tabs for Worker/Client/Admin
//  ✅ ANIMATED: Smooth transitions between states
//

import SwiftUI

// MARK: - Intelligence Panel

public struct IntelligencePanel: View {
    
    // MARK: - Properties
    
    @ObservedObject var model: IntelligencePanelModel
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            switch model.mode {
            case .mini:
                miniView
            case .expanded:
                expandedView
            case .full:
                // Full mode is handled by parent (map full-screen)
                EmptyView()
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            // Top border
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .top
        )
        .animation(.easeInOut(duration: 0.3), value: model.mode)
    }
    
    // MARK: - Mini View (Tab Bar)
    
    private var miniView: some View {
        HStack(spacing: 0) {
            ForEach(model.availableTabs) { tab in
                miniTabButton(tab)
            }
        }
        .frame(height: 60)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Intelligence panel, mini mode")
    }
    
    private func miniTabButton(_ tab: IntelligenceTab) -> some View {
        Button(action: { selectTab(tab) }) {
            VStack(spacing: 2) {
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isTabSelected(tab) ? .blue : .secondary)
                    
                    // Badge
                    if let badgeCount = tab.badgeCount, badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isTabSelected(tab) ? .blue : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(tab.title)
        .accessibilityHint("Double-tap to expand \(tab.title) section")
        .accessibilityAddTraits(isTabSelected(tab) ? [.isSelected] : [])
    }
    
    // MARK: - Expanded View (Accordion Cards)
    
    private var expandedView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(model.availableTabs) { tab in
                    expandableTabCard(tab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        .background(Color(.systemGroupedBackground))
    }
    
    private func expandableTabCard(_ tab: IntelligenceTab) -> some View {
        let isExpanded = Binding(
            get: { model.tabExpansion[tab.key] ?? false },
            set: { _ in model.toggleTabExpansion(tab.key) }
        )
        
        let tabData = model.tabData[tab.key] ?? TabContentData()
        
        return ExpandableCard(
            title: tab.title,
            icon: tab.icon,
            isExpanded: isExpanded,
            compactContent: {
                compactContentView(for: tab, data: tabData)
            },
            expandedContent: {
                expandedContentView(for: tab, data: tabData)
            },
            onTap: {
                model.selectTab(tab.key)
            },
            backgroundColor: Color(.systemBackground),
            iconColor: isTabSelected(tab) ? .blue : .secondary
        )
    }
    
    // MARK: - Tab Content Views
    
    private func compactContentView(for tab: IntelligenceTab, data: TabContentData) -> some View {
        HStack(spacing: 8) {
            if !data.summary.isEmpty {
                Text(data.summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            if let badgeCount = tab.badgeCount, badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
    }
    
    private func expandedContentView(for tab: IntelligenceTab, data: TabContentData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Items
            if !data.items.isEmpty {
                ForEach(data.items) { item in
                    tabItemView(item)
                }
            }
            
            // Actions
            if !data.actions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(data.actions) { action in
                        tabActionButton(action)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func tabItemView(_ item: TabItem) -> some View {
        HStack(spacing: 12) {
            // Icon
            if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(item.color ?? .secondary)
                    .frame(width: 20)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(.body, design: .default))
                    .fontWeight(item.isHighlighted ? .semibold : .regular)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Value
            if let value = item.value {
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(item.color ?? .primary)
            }
        }
        .padding(.vertical, 2)
        .background(
            item.isHighlighted ?
            Color(item.color ?? .blue).opacity(0.1) :
            Color.clear
        )
        .cornerRadius(6)
    }
    
    private func tabActionButton(_ action: TabAction) -> some View {
        Button(action: action.action) {
            HStack(spacing: 6) {
                if let icon = action.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(action.title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(action.isPrimary ? .white : .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(action.isPrimary ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func isTabSelected(_ tab: IntelligenceTab) -> Bool {
        return model.currentTab == tab.key
    }
    
    private func selectTab(_ tab: IntelligenceTab) {
        if model.mode == .mini {
            // Switch to expanded mode and select tab
            model.setMode(.expanded)
            model.selectTab(tab.key)
        } else {
            // Just select tab (accordion behavior)
            model.selectTab(tab.key)
        }
    }
}

// MARK: - Minibar Component (for use when map is full-screen)

public struct IntelligenceMinibar: View {
    
    @ObservedObject var model: IntelligencePanelModel
    
    public var body: some View {
        HStack(spacing: 0) {
            ForEach(model.availableTabs.prefix(4)) { tab in  // Show max 4 tabs in minibar
                Button(action: { 
                    model.setMode(.expanded)
                    model.selectTab(tab.key)
                }) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(model.currentTab == tab.key ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: 44)
        .background(Color(.systemBackground).opacity(0.95))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Preview

#if DEBUG
struct IntelligencePanel_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            // Mini mode
            IntelligencePanel(model: IntelligencePanelModel.preview(role: .worker))
            
            // Expanded mode
            IntelligencePanel(model: {
                let model = IntelligencePanelModel.preview(role: .client)
                model.mode = .expanded
                model.expandTab("priorities")
                return model
            }())
        }
        .previewDisplayName("Intelligence Panel")
        
        // Minibar
        IntelligenceMinibar(model: IntelligencePanelModel.preview(role: .admin))
            .previewDisplayName("Intelligence Minibar")
            .previewLayout(.sizeThatFits)
    }
}
#endif