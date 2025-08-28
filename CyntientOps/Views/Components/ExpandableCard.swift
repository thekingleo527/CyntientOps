//
//  ExpandableCard.swift
//  CyntientOps v6.0
//
//  ✅ SHARED COMPONENT: Accordion-style expandable card for Intelligence Panel
//  ✅ REUSABLE: Works across Worker/Client/Admin dashboards
//  ✅ ANIMATED: Smooth expand/collapse with accessibility support
//  ✅ FLEXIBLE: Supports custom content in both compact and expanded states
//

import SwiftUI

// MARK: - ExpandableCard

public struct ExpandableCard<CompactContent: View, ExpandedContent: View>: View {
    
    // MARK: - Properties
    
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    let compactContent: () -> CompactContent
    let expandedContent: () -> ExpandedContent
    
    // MARK: - Optional Configuration
    
    let onTap: (() -> Void)?
    let backgroundColor: Color
    let titleColor: Color
    let iconColor: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let animationDuration: Double
    
    // MARK: - Initializers
    
    public init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder compactContent: @escaping () -> CompactContent,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent,
        onTap: (() -> Void)? = nil,
        backgroundColor: Color = Color(.systemBackground),
        titleColor: Color = .primary,
        iconColor: Color = .blue,
        cornerRadius: CGFloat = 12,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        animationDuration: Double = 0.3
    ) {
        self.title = title
        self.icon = icon
        self._isExpanded = isExpanded
        self.compactContent = compactContent
        self.expandedContent = expandedContent
        self.onTap = onTap
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
        self.iconColor = iconColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.animationDuration = animationDuration
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row (always visible)
            headerView
            
            // Content Area (collapsible)
            if isExpanded {
                contentView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .animation(.easeInOut(duration: animationDuration), value: isExpanded)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isExpanded ? [.isExpanded] : [])
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            // Title
            Text(title)
                .font(.system(.headline, design: .default))
                .foregroundColor(titleColor)
                .lineLimit(1)
            
            Spacer()
            
            // Compact content (when collapsed) or expand/collapse indicator
            if !isExpanded {
                compactContent()
                    .transition(.opacity)
            }
            
            // Expand/Collapse Button
            Button(action: toggleExpansion) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : 0))
                    .animation(.easeInOut(duration: animationDuration), value: isExpanded)
            }
            .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
        }
        .padding(padding)
        .contentShape(Rectangle())
        .onTapGesture(perform: toggleExpansion)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Divider
            Divider()
                .padding(.horizontal, padding.leading)
            
            // Expanded Content
            expandedContent()
                .padding(.horizontal, padding.leading)
                .padding(.bottom, padding.bottom)
        }
    }
    
    // MARK: - Actions
    
    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isExpanded.toggle()
        }
        onTap?()
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        "\(title), \(isExpanded ? "expanded" : "collapsed")"
    }
    
    private var accessibilityHint: String {
        "Double-tap to \(isExpanded ? "collapse" : "expand")"
    }
}

// MARK: - Convenience Initializers

public extension ExpandableCard where CompactContent == EmptyView {
    
    /// Initializer for cards that don't need compact content
    init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent,
        onTap: (() -> Void)? = nil,
        backgroundColor: Color = Color(.systemBackground),
        titleColor: Color = .primary,
        iconColor: Color = .blue,
        cornerRadius: CGFloat = 12,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        animationDuration: Double = 0.3
    ) {
        self.init(
            title: title,
            icon: icon,
            isExpanded: isExpanded,
            compactContent: { EmptyView() },
            expandedContent: expandedContent,
            onTap: onTap,
            backgroundColor: backgroundColor,
            titleColor: titleColor,
            iconColor: iconColor,
            cornerRadius: cornerRadius,
            padding: padding,
            animationDuration: animationDuration
        )
    }
}

public extension ExpandableCard where ExpandedContent == EmptyView {
    
    /// Initializer for cards that are always compact (just for consistency)
    init(
        title: String,
        icon: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder compactContent: @escaping () -> CompactContent,
        onTap: (() -> Void)? = nil,
        backgroundColor: Color = Color(.systemBackground),
        titleColor: Color = .primary,
        iconColor: Color = .blue,
        cornerRadius: CGFloat = 12,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        animationDuration: Double = 0.3
    ) {
        self.init(
            title: title,
            icon: icon,
            isExpanded: isExpanded,
            compactContent: compactContent,
            expandedContent: { EmptyView() },
            onTap: onTap,
            backgroundColor: backgroundColor,
            titleColor: titleColor,
            iconColor: iconColor,
            cornerRadius: cornerRadius,
            padding: padding,
            animationDuration: animationDuration
        )
    }
}

// MARK: - Preview

#if DEBUG
struct ExpandableCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Example with compact content
            ExpandableCard(
                title: "Tasks",
                icon: "list.bullet",
                isExpanded: .constant(false),
                compactContent: {
                    Text("3 pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                },
                expandedContent: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Daily Sidewalk Sweep")
                            Spacer()
                            Text("High")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            Text("Garbage Collection")
                            Spacer()
                            Text("Medium")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Button("View All Tasks") {
                            // Action
                        }
                        .foregroundColor(.blue)
                        .font(.caption)
                    }
                }
            )
            
            // Example with expanded state
            ExpandableCard(
                title: "Analytics",
                icon: "chart.bar",
                isExpanded: .constant(true),
                compactContent: {
                    Text("92%")
                        .font(.caption)
                        .foregroundColor(.green)
                },
                expandedContent: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Completion Rate")
                            Spacer()
                            Text("92%")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Efficiency")
                            Spacer()
                            Text("87%")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Average Time")
                            Spacer()
                            Text("24 min")
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.system(.body, design: .rounded))
                }
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif