import SwiftUI
import UserNotifications

@main
struct BillsApp: App {
    @StateObject private var store = ExpenseStore()
    @StateObject private var screenshotHandler = ScreenshotHandler()
    
    @State private var showPopup = false
    @State private var popupAmount: Double?
    @State private var isManualEntry = false
    @State private var isProcessing = false
    @State private var processingError: String?
    
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    
    var body: some Scene {
        WindowGroup {
            if !onboardingCompleted {
                OnboardingView(isCompleted: $onboardingCompleted)
                    .transition(.opacity)
            } else {
                mainTabView
                    .onOpenURL { url in handleURL(url) }
                    .onAppear {
                        requestNotificationPermission()
                        scheduleMonthlyReport()
                    }
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .active { handleAppForeground() }
                    }
                    .sheet(isPresented: $showPopup) {
                        ExpensePopupView(
                            store: store,
                            initialAmount: isManualEntry ? nil : popupAmount,
                            onDismiss: {
                                showPopup = false
                                popupAmount = nil
                                isManualEntry = false
                            }
                        )
                        .presentationDetents([.height(480)])
                        .presentationDragIndicator(.hidden)
                    }
                    .overlay(processingOverlay)
                    .overlay(errorToastOverlay)
            }
        }
    }
    
    // MARK: - Main Tab View
    
    private var mainTabView: some View {
        TabView {
            ExpenseListView(
                store: store,
                showPopup: $showPopup,
                popupAmount: $popupAmount,
                isManualEntry: $isManualEntry
            )
            .tabItem {
                Image(systemName: "list.bullet")
                Text("记录")
            }
            
            MonthlyReportView(store: store)
                .tabItem {
                    Image(systemName: "chart.pie")
                    Text("月报")
                }
            
            SettingsView(store: store)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
        }
    }
    
    // MARK: - Processing Overlay
    
    @ViewBuilder
    private var processingOverlay: some View {
        if isProcessing {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("正在识别金额…")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
        }
    }
    
    @ViewBuilder
    private var errorToastOverlay: some View {
        if let error = processingError {
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                    Spacer()
                    Button("知道了") {
                        withAnimation { processingError = nil }
                    }
                    .font(.system(size: 14, weight: .medium))
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: processingError)
        }
    }
    
    // MARK: - URL Handling
    
    private func handleURL(_ url: URL) {
        guard let host = url.host else { return }
        
        switch host {
        case "process":
            processScreenshotFromCamera()
        case "add":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let amountItem = components.queryItems?.first(where: { $0.name == "amount" }),
               let amountStr = amountItem.value,
               let amount = Double(amountStr) {
                isManualEntry = false
                popupAmount = amount
                showPopup = true
            }
        default:
            break
        }
    }
    
    // MARK: - Screenshot Processing
    
    private func processScreenshotFromCamera() {
        isProcessing = true
        
        Task {
            let amount = await screenshotHandler.processFromPhotoLibrary()
            
            await MainActor.run {
                isProcessing = false
                
                if let amount = amount, amount > 0 {
                    isManualEntry = false
                    popupAmount = amount
                    showPopup = true
                } else if let error = screenshotHandler.error {
                    processingError = error
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { processingError = nil }
                    }
                }
            }
        }
    }
    
    // MARK: - App Foreground
    
    private func handleAppForeground() {
        // URL scheme handles screenshot processing
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleMonthlyReport() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "账单月报已生成"
        content.body = "查看上个月的消费分析报告"
        content.sound = .default
        
        var components = DateComponents()
        components.day = 1
        components.hour = 8
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monthly_report",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
