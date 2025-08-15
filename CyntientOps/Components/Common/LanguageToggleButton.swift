//
//  LanguageToggleButton.swift
//  CyntientOps
//
//  Language toggle button for users with language switching capability
//

import SwiftUI

struct LanguageToggleButton: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Group {
            if languageManager.canToggleLanguage {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        languageManager.toggleLanguage()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(languageManager.isSpanish ? "ES" : "EN")
                            .font(.system(size: 12, weight: .bold))
                            .frame(minWidth: 20)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .help("Toggle between English and Spanish")
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Header Language Toggle

struct HeaderLanguageToggle: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Group {
            if languageManager.canToggleLanguage {
                Menu {
                    Button(action: {
                        if languageManager.currentLanguage != "en" {
                            languageManager.toggleLanguage()
                        }
                    }) {
                        HStack {
                            Text("English")
                            if languageManager.isEnglish {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        if languageManager.currentLanguage != "es" {
                            languageManager.toggleLanguage()
                        }
                    }) {
                        HStack {
                            Text("Español")
                            if languageManager.isSpanish {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .font(.system(size: 16))
                        Text(languageManager.currentLanguage.uppercased())
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Settings Language Toggle

struct SettingsLanguageToggle: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        Group {
            if languageManager.canToggleLanguage {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language")
                                .font(.system(size: 16, weight: .medium))
                            Text("Switch between English and Spanish")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Picker("Language", selection: Binding(
                        get: { languageManager.currentLanguage },
                        set: { newValue in
                            if newValue != languageManager.currentLanguage {
                                languageManager.toggleLanguage()
                            }
                        }
                    )) {
                        Text("English").tag("en")
                        Text("Español").tag("es")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 120)
                }
                .padding(.vertical, 8)
            } else {
                // Show current language (read-only) for users without toggle capability
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Language")
                                .font(.system(size: 16, weight: .medium))
                            Text(languageManager.isSpanish ? "Español (Fixed)" : "English (Fixed)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(languageManager.isSpanish ? "ES" : "EN")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LanguageToggleButton()
        HeaderLanguageToggle()
        SettingsLanguageToggle()
    }
    .padding()
    .environmentObject(LanguageManager.shared)
}