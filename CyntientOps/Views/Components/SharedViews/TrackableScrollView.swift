//
//  TrackableScrollView.swift
//  CyntientOps
//
//  ✅ FIXED: Binding vs State assignment issue resolved
//  ✅ ALIGNED: With current phase implementation
//  ✅ COMPATIBLE: Works with three-dashboard system
//

import SwiftUI

struct TrackableScrollView<Content: View>: View {
    @Binding var contentOffset: CGFloat  // ✅ FIXED: Use @Binding instead of @State
    let contentInset: UIEdgeInsets
    let content: () -> Content
    
    init(
        contentOffset: Binding<CGFloat>,
        contentInset: UIEdgeInsets = UIEdgeInsets(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._contentOffset = contentOffset  // ✅ FIXED: Now correctly assigns Binding to @Binding
        self.contentInset = contentInset
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                // Invisible tracking view
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)
                
                // Content with insets
                VStack(spacing: 0) {
                    Color.clear.frame(height: contentInset.top)
                    content()
                    Color.clear.frame(height: contentInset.bottom)
                }
                .padding(.leading, contentInset.left)
                .padding(.trailing, contentInset.right)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            contentOffset = value
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

 
