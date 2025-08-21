
//  OnboardingView.swift
//  CyntientOps
//
//  Stream A: UI/UX & Spanish
//  Mission: Create an onboarding flow for first-time users.
//
//  ✅ PRODUCTION READY: A welcoming setup screen for new users.
//  ✅ FUNCTIONAL: Allows language and interface selection before first use.
//

import SwiftUI

struct OnboardingView: View {
    
    // Callback to notify the parent view that onboarding is complete.
    var onComplete: () -> Void
    
    @State private var selectedLanguage = "en"
    @State private var useSimplifiedInterface = false
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        .init(image: "globe", title: "Welcome to CyntientOps", description: "Your all-in-one property management tool. Let's get you set up."),
        .init(image: "text.bubble", title: "Choose Your Language", description: "Select your preferred language for the app interface."),
        .init(image: "hand.tap", title: "Select Your Interface", description: "Choose the interface that works best for you. You can change this later in settings."),
        .init(image: "checkmark.circle", title: "You're All Set!", description: "You are now ready to start managing your tasks efficiently.")
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    OnboardingPageView(page: pages[index]) {
                        // Special content for specific pages
                        if index == 1 {
                            languageSelector
                        } else if index == 2 {
                            interfaceSelector
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Bottom Controls
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentPage == pages.count - 1 {
                    Button("Get Started", action: completeOnboarding)
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
            }
            .padding(30)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Custom Page Content
    
    private var languageSelector: some View {
        Picker("Language", selection: $selectedLanguage) {
            Text("English").tag("en")
            Text("Español").tag("es")
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 40)
    }
    
    private var interfaceSelector: some View {
        VStack(spacing: 20) {
            InterfaceOptionCard(
                title: "Standard Interface",
                description: "Full-featured interface with maps, charts, and advanced options.",
                icon: "macwindow",
                isSelected: !useSimplifiedInterface,
                onTap: { useSimplifiedInterface = false }
            )
            
            InterfaceOptionCard(
                title: "Simplified Interface",
                description: "A high-contrast, large-text interface focused on core tasks.",
                icon: "textformat.size",
                isSelected: useSimplifiedInterface,
                onTap: { useSimplifiedInterface = true }
            )
        }
    }
    
    // MARK: - Actions
    
    private func completeOnboarding() {
        // Here, you would save these initial preferences.
        // This is a simplified example; a real app would save this
        // to a ViewModel or directly to UserDefaults/GRDB before login.
        UserDefaults.standard.set(selectedLanguage, forKey: "user_preferred_language")
        UserDefaults.standard.set(useSimplifiedInterface, forKey: "user_prefers_simplified_interface")
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        
        onComplete()
    }
}

// MARK: - Onboarding Page Sub-views
private struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

private struct OnboardingPageView<Content: View>: View {
    let page: OnboardingPage
    @ViewBuilder var customContent: Content
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: page.image)
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
            
            Text(page.title, bundle: .main)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(page.description, bundle: .main)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            customContent
                .padding(.top)
            
            Spacer()
        }
        .padding()
    }
}

private struct InterfaceOptionCard: View {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .frame(width: 50)
                
                VStack(alignment: .leading) {
                    Text(title, bundle: .main)
                        .font(.headline)
                    Text(description, bundle: .main)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onComplete: {
            print("Onboarding completed!")
        })
    }
}
