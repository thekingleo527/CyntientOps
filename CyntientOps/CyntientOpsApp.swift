//
//  CyntientOpsApp.swift
//  CyntientOps (formerly CyntientOps) v6.0
//
//  ✅ PHASE 0-2 INTEGRATED: ServiceContainer + Nova AI + Existing Features
//  ✅ PRESERVED: All Sentry, database init, and daily ops functionality
//  ✅ ENHANCED: Added ServiceContainer architecture and Nova AI persistence
//  ✅ PRODUCTION READY: Complete initialization flow maintained
//

import SwiftUI
import Sentry
import GRDB
import Combine

// Removed legacy DirectDataInitializer. DatabaseInitializer.shared is the single source of initialization.

@main
struct CyntientOpsApp: App {
    // MARK: - State Management & Services
    
    // Phase 0-2 Additions
    @StateObject private var coordinator = AppStartupCoordinator.shared
    @State private var serviceContainer: ServiceContainer?
    
    // Core Services (simplified)
    @ObservedObject private var dbInitializer = DatabaseInitializer.shared
    @StateObject private var authManager = NewAuthManager.shared
    @ObservedObject private var session = CoreTypes.Session.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var memoryMonitor = MemoryPressureMonitor.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
    private let locationManager = LocationManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingSplash = true
    @State private var containerError: Error?
    // PRODUCTION: No QuickLogin in production-ready builds
    
    init() {
        // Initialize Sentry as the very first step of the app's lifecycle.
        initializeSentry()
        
        // Log production configuration
        print("🚀 CyntientOps Production Ready")
    }
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            ZStack {
                // The main app flow is determined by a series of state checks,
                // ensuring the correct view is shown at each stage of the launch sequence.
                if showingSplash {
                    SplashView()
                        .task {
                            // Show splash for a brief period then transition.
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showingSplash = false
                            }
                        }
                } else if !dbInitializer.isInitialized {
                    // Initialize database and services via DatabaseInitializer
                    VStack(spacing: 12) {
                        ProgressView("Initializing database…")
                        Text(dbInitializer.currentStep)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .task {
                        do {
                            try await DatabaseInitializer.shared.initializeIfNeeded()
                            await createServiceContainer()
                        } catch {
                            containerError = error
                        }
                    }
                } else if !hasCompletedOnboarding {
                    // Step 3: Show the onboarding flow for first-time users.
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                    })
                    .environmentObject(languageManager) // Always English for onboarding
                    .transition(.opacity)
                } else if authManager.isAuthenticated {
                    // Step 4: If the user is authenticated, show the main app content.
                    if let container = serviceContainer {
                        ContentView()
                            .environmentObject(authManager)
                            .environmentObject(notificationManager)
                            .environmentObject(locationManager)
                            .environmentObject(contextEngine)
                            .environmentObject(dbInitializer)
                            .environmentObject(languageManager) // Language management
                            .environmentObject(container) // Phase 2: Service Container
                            .environmentObject(container.novaManager) // Nova AI from Container
                            .environmentObject(container.dashboardSync) // Dashboard Sync Service
                            .environmentObject(session)
                            .transition(.opacity)
                    } else {
                        // Show loading while container initializes
                        VStack {
                            ProgressView("Initializing services...")
                            if let error = containerError {
                                Text("Error: \(error.localizedDescription)")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                        .task {
                            await createServiceContainer()
                        }
                    }
                } else {
                    // Step 5: Ensure data is properly initialized before showing login
                    if dbInitializer.isInitialized {
                        // Data ready - show login (always English)
                        LoginView()
                            .environmentObject(authManager)
                            .environmentObject(languageManager) // Always English for login
                            .transition(.opacity)
                            // PRODUCTION: No debug toolbar in field deployment
                    } else {
                        // Data not ready - show initialization
                        VStack(spacing: 12) {
                            ProgressView("Preparing data…")
                            if let error = containerError {
                                Text(error.localizedDescription).foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            // Animate transitions between the major app states for a smoother experience.
            .animation(.easeInOut(duration: 0.3), value: showingSplash)
            .animation(.easeInOut(duration: 0.3), value: dbInitializer.isInitialized)
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.3), value: serviceContainer != nil)
            .onAppear(perform: setupApp)
            .onChange(of: authManager.currentUser) { _, newValue in
                updateSentryUserContext(newValue)
            }
        }
    }
    
    // MARK: - Phase 0-2: Service Container Creation
    
    private func createServiceContainer() async {
        guard serviceContainer == nil else { return }

        do {
            // Drive all init via the coordinator
            try await coordinator.startInitialization()

            // Use container created by coordinator
            if let container = coordinator.serviceContainer {
                await MainActor.run {
                    self.serviceContainer = container
                }
                print("✅ Service container acquired from coordinator")
            } else {
                throw StartupError.servicesInitializationFailed("Coordinator did not provide ServiceContainer")
            }
        } catch {
            await MainActor.run { self.containerError = error }
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.error)
                scope.setTag(value: "service_container", key: "initialization")
            }
            print("❌ Failed to acquire service container: \(error)")
        }
    }
    
    // MARK: - Sentry Initialization (PRESERVED)
    
    private func initializeSentry() {
        // PRODUCTION-READY: Always use production Sentry DSN for field deployment readiness
        let productionDSN = "https://c77b2dddf9eca868ead5142d23a438cf@o4509764891901952.ingest.us.sentry.io/4509764893081600"
        
        SentrySDK.start { options in
            options.dsn = productionDSN
            
            // PRODUCTION SETTINGS: Simulator identical to iPhone in field
            options.debug = false
            options.environment = "production"
            
            // Reduced sampling to improve performance during initialization
            options.tracesSampleRate = 0.05   // 5% sampling
            options.profilesSampleRate = 0.02 // 2% profiling - critical reduction
            
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "cyntientops@\(version)+\(build)"
            }
            
            options.enableAutoBreadcrumbTracking = true
            options.maxBreadcrumbs = 100
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            
            options.beforeSend = { event in
                return self.sanitizeEvent(event)
            }
            
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30000
            
            options.enableNetworkTracking = false
            options.enableNetworkBreadcrumbs = false
            
            options.enableUIViewControllerTracing = true
            options.enableUserInteractionTracing = true
            options.enableSwizzling = true
            
            options.enableTimeToFullDisplayTracing = true
            options.enablePreWarmedAppStartTracing = true
        }
        
        SentrySDK.configureScope { scope in
            scope.setTag(value: UIDevice.current.model, key: "device.model")
            scope.setTag(value: UIDevice.current.systemVersion, key: "ios.version")
            scope.setContext(value: [
                "initialized": dbInitializer.isInitialized,
                "onboardingCompleted": hasCompletedOnboarding,
                "environment": "production"
            ], key: "app_state")
        }
        
        print("✅ Sentry initialized successfully")
    }
    
    // MARK: - Sentry Helper Methods (PRESERVED)
    
    private func sanitizeEvent(_ event: Event) -> Event? {
        if let message = event.message {
            event.message = SentryMessage(
                formatted: message.formatted.replacingOccurrences(
                    of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
                    with: "[REDACTED_EMAIL]",
                    options: .regularExpression
                )
            )
        }
        
        event.breadcrumbs = event.breadcrumbs?.compactMap { breadcrumb in
            let sanitizedBreadcrumb = breadcrumb
            if var data = sanitizedBreadcrumb.data {
                data.removeValue(forKey: "password")
                data.removeValue(forKey: "token")
                sanitizedBreadcrumb.data = data
            }
            return sanitizedBreadcrumb
        }
        
        if let request = event.request, let url = request.url, url.contains("password") || url.contains("token") {
            event.request?.url = "[REDACTED_URL]"
        }
        
        return event
    }
    
    private func updateSentryUserContext(_ user: CoreTypes.User?) {
        SentrySDK.configureScope { scope in
            if let user = user {
                // ✅ FIXED: Using the correct Sentry.User initializer.
                let sentryUser = Sentry.User(userId: user.workerId)
                sentryUser.username = user.name
                
                scope.setUser(sentryUser)
                scope.setContext(value: ["role": user.role], key: "user_info")
                scope.setTag(value: user.role, key: "user.role")
            } else {
                scope.setUser(nil)
                scope.removeContext(key: "user_info")
                scope.removeTag(key: "user.role")
            }
        }
    }
    
    // MARK: - App Setup & Lifecycle (PRESERVED + ENHANCED)
    
    private func setupApp() {
        configureAppearance()
        
        let breadcrumb = Breadcrumb(level: .info, category: "app.lifecycle")
        breadcrumb.message = "App setup started"
        SentrySDK.addBreadcrumb(breadcrumb)
        
        if authManager.isAuthenticated {
            locationManager.startUpdatingLocation()
        }
        
        // Note: Data loading is now handled by DirectDataInitializer.initializeIfNeeded()
        // This ensures proper initialization flow and avoids conflicts
    }
    
    // Simplified data refresh - no complex migration logic needed
    private func refreshAppData() async {
        do {
            // BuildingMetricsService cache invalidation handled per-instance
            
            if let currentUser = authManager.currentUser {
                try await contextEngine.loadContext(for: currentUser.workerId)
            }
            
            let breadcrumb = Breadcrumb(level: .info, category: "app.data")
            breadcrumb.message = "App data refreshed"
            SentrySDK.addBreadcrumb(breadcrumb)
            print("✅ App data refreshed.")
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.warning)
            }
            print("⚠️ Failed to refresh app data: \(error)")
        }
    }
    
    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .systemBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        
        UITableView.appearance().backgroundColor = .systemBackground
    }
}

// MARK: - Sentry Crash Reporter Wrapper (PRESERVED)

@MainActor
enum CrashReporter {
    static func captureError(_ error: Error, context: [String: Any]? = nil) {
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "custom_error_context")
            }
        }
    }
}

// MARK: - DirectInitializationView (Moved here to resolve scope issues)

struct DirectInitializationView: View {
    @EnvironmentObject private var initializer: DatabaseInitializer
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // Dark background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .scaleEffect(animateIcon ? 1.2 : 0.8)
                    
                    Image(systemName: "server.rack")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                }
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateIcon)
                
                // Title
                Text("Loading Real-World Data")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Status Message
                Text(initializer.currentStep)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.3), value: initializer.currentStep)
                
                // Progress
                VStack(spacing: 16) {
                    ProgressView(value: initializer.initializationProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .scaleEffect(y: 2.0)
                        .padding(.horizontal, 60)
                    
                    Text("\(Int(initializer.initializationProgress * 100))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                // Error Handling
                if let error = initializer.error {
                    VStack(spacing: 12) {
                        Text("Initialization Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Retry") {
                            Task {
                                try? await initializer.initializeIfNeeded()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                // Data Source Info
                VStack(spacing: 8) {
                    Text("Loading from:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 16) {
                        Label("OperationalDataManager", systemImage: "building.2")
                        Label("NYC APIs", systemImage: "network")
                        Label("Real Buildings", systemImage: "location")
                    }
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)
            }
            .onAppear {
                withAnimation {
                    animateIcon = true
                }
            }
        }
    }
}

// MARK: - Placeholder SplashView (PRESERVED)

struct SplashView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .scaleEffect(animate ? 1.2 : 0.8)
                    
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .scaleEffect(animate ? 1.0 : 0.8)
                }
                
                Text("CyntientOps")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(animate ? 1.0 : 0.0)
                
                Text("Property Management Excellence")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(animate ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
            }
        }
    }
}
