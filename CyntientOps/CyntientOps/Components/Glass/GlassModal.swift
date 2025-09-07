//
//  GlassModal.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Generic parameter inference issues resolved
//  ✅ FIXED: Type conversion errors resolved
//  ✅ FIXED: ViewBuilder and generic constraints properly defined
//  ✅ ALIGNED: Updated for v6.0 architecture with proper SwiftUI patterns
//  ✅ OPTIMIZED: Glass modal system for three-dashboard experience
//

import SwiftUI

// MARK: - Glass Modal
struct GlassModal<Content: View>: View {
    @Binding var isPresented: Bool
    
    let intensity: GlassIntensity
    let cornerRadius: CGFloat
    let showCloseButton: Bool
    let onDismiss: (() -> Void)?
    let content: Content
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    // MARK: - Animation Constants
    private let dismissThreshold: CGFloat = 100
    private let animationDuration: Double = 0.3
    private let springAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
    
    init(
        isPresented: Binding<Bool>,
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 20,
        showCloseButton: Bool = true,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.showCloseButton = showCloseButton
        self.onDismiss = onDismiss
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black
                .opacity(backgroundOpacity * 0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content
            modalContent
                .scaleEffect(scale)
                .opacity(opacity)
                .offset(offset)
                .gesture(dragGesture)
        }
        .onAppear {
            presentModal()
        }
        .onChange(of: isPresented) { presented in
            if presented {
                presentModal()
            } else {
                dismissModal()
            }
        }
    }
    
    // MARK: - Modal Content
    private var modalContent: some View {
        VStack(spacing: 0) {
            // Close button (if enabled)
            if showCloseButton {
                closeButtonHeader
            }
            
            // Main content
            GlassCard(intensity: intensity) {
                content
            }
            .cornerRadius(cornerRadius)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, showCloseButton ? 0 : 20)
    }
    
    private var closeButtonHeader: some View {
        HStack {
            Spacer()
            
            Button(action: dismissModal) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 32, height: 32)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
                
                // Reduce scale as user drags down
                let dragAmount = abs(value.translation.height)
                scale = max(0.85, 1.0 - (dragAmount / 1000))
                opacity = max(0.3, 1.0 - (dragAmount / 500))
            }
            .onEnded { value in
                if abs(value.translation.height) > dismissThreshold {
                    dismissModal()
                } else {
                    // Snap back to original position
                    withAnimation(springAnimation) {
                        offset = .zero
                        scale = 1.0
                        opacity = 1.0
                    }
                }
            }
    }
    
    // MARK: - Animation Methods
    private func presentModal() {
        withAnimation(springAnimation) {
            scale = 1.0
            opacity = 1.0
            backgroundOpacity = 1.0
        }
    }
    
    private func dismissModal() {
        withAnimation(.easeIn(duration: animationDuration)) {
            scale = 0.9
            opacity = 0.0
            backgroundOpacity = 0.0
            offset = CGSize(width: 0, height: 50)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isPresented = false
            onDismiss?()
        }
    }
}

// MARK: - Modal Styles
enum ModalStyle {
    case fullScreen
    case large
    case medium
    case small
    case compact
    
    var maxWidth: CGFloat? {
        switch self {
        case .fullScreen: return nil
        case .large: return 600
        case .medium: return 500
        case .small: return 400
        case .compact: return 300
        }
    }
    
    var maxHeight: CGFloat? {
        switch self {
        case .fullScreen: return nil
        case .large: return 700
        case .medium: return 500
        case .small: return 400
        case .compact: return 250
        }
    }
}

// MARK: - Styled Glass Modal
struct StyledGlassModal<Content: View>: View {
    @Binding var isPresented: Bool
    
    let style: ModalStyle
    let intensity: GlassIntensity
    let title: String?
    let content: Content
    
    init(
        isPresented: Binding<Bool>,
        style: ModalStyle = .medium,
        intensity: GlassIntensity = .regular,
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.style = style
        self.intensity = intensity
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        GlassModal(
            isPresented: $isPresented,
            intensity: intensity
        ) {
            VStack(spacing: 20) {
                // Title header
                if let title = title {
                    modalTitle(title)
                }
                
                // Content
                content
            }
            .padding(24)
            .frame(maxWidth: style.maxWidth, maxHeight: style.maxHeight)
        }
    }
    
    private func modalTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Confirmation Modal
struct ConfirmationModal: View {
    @Binding var isPresented: Bool
    
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        StyledGlassModal(
            isPresented: $isPresented,
            style: .compact,
            title: title
        ) {
            VStack(spacing: 20) {
                Text(message)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 16) {
                    // Cancel button
                    Button(action: {
                        isPresented = false
                        onCancel()
                    }) {
                        Text(cancelTitle)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    // Confirm button
                    Button(action: {
                        isPresented = false
                        onConfirm()
                    }) {
                        Text(confirmTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func glassModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        intensity: GlassIntensity = .regular,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    GlassModal(
                        isPresented: isPresented,
                        intensity: intensity,
                        onDismiss: onDismiss,
                        content: content
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        )
    }
    
    func confirmationModal(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        cancelTitle: String = "Cancel",
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    ConfirmationModal(
                        isPresented: isPresented,
                        title: title,
                        message: message,
                        confirmTitle: confirmTitle,
                        cancelTitle: cancelTitle,
                        onConfirm: onConfirm,
                        onCancel: onCancel
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        )
    }
}

// MARK: - Preview Support
#if DEBUG
struct GlassModal_Previews: PreviewProvider {
    @State static var showModal = true
    @State static var showConfirmation = false
    
    static var previews: some View {
        VStack {
            Button("Show Modal") {
                showModal = true
            }
            
            Button("Show Confirmation") {
                showConfirmation = true
            }
        }
        .glassModal(isPresented: $showModal) {
            VStack(spacing: 20) {
                Text("Modal Content")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("This is a sample glass modal with beautiful animations and gesture support.")
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("Close") {
                    showModal = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
        }
        .confirmationModal(
            isPresented: $showConfirmation,
            title: "Delete Item",
            message: "Are you sure you want to delete this item? This action cannot be undone.",
            onConfirm: {
                print("Confirmed")
            }
        )
        .background(
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}
#endif
