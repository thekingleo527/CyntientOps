//
//  SignaturePad.swift
//  CyntientOps v6.0
//
//  🎯 SIGNATURE CAPTURE COMPONENT
//  ✅ Smooth signature drawing with PencilKit
//  ✅ Clear and save functionality
//  ✅ Security-focused for vendor authentication
//  ✅ Base64 encoding for storage and transmission
//

import SwiftUI
import PencilKit

struct SignaturePad: View {
    @State private var canvasView = PKCanvasView()
    @State private var isSignatureEmpty = true
    let onSignatureCapture: (String) -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Signature Canvas
            SignatureCanvasView(
                canvasView: $canvasView,
                onSignatureChange: { isEmpty in
                    isSignatureEmpty = isEmpty
                }
            )
            .frame(height: 200)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                // Signature prompt overlay
                Group {
                    if isSignatureEmpty {
                        VStack {
                            Image(systemName: "signature")
                                .font(.system(size: 32))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Vendor Signature Required")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                }
            )
            
            // Action Buttons
            HStack(spacing: 16) {
                // Clear Button
                Button("Clear") {
                    clearSignature()
                }
                .foregroundColor(.red)
                .disabled(isSignatureEmpty)
                
                Spacer()
                
                // Save Button
                Button("Save Signature") {
                    saveSignature()
                }
                .foregroundColor(.blue)
                .disabled(isSignatureEmpty)
            }
            .font(.subheadline)
            .fontWeight(.medium)
        }
    }
    
    private func clearSignature() {
        canvasView.drawing = PKDrawing()
        isSignatureEmpty = true
        onClear()
    }
    
    private func saveSignature() {
        let drawing = canvasView.drawing
        let image = drawing.image(from: canvasView.bounds, scale: 1.0)
        
        if let imageData = image.pngData() {
            let base64String = imageData.base64EncodedString()
            onSignatureCapture(base64String)
        }
    }
}

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let onSignatureChange: (Bool) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: SignatureCanvasView
        
        init(_ parent: SignatureCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let isEmpty = canvasView.drawing.strokes.isEmpty
            parent.onSignatureChange(isEmpty)
        }
    }
}

