import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    
    @State private var currentStep = 0
    @State private var shortcutFileURL: URL?
    @State private var showShortcutShare = false
    @State private var isGenerating = true
    
    private let steps = [
        OnboardingStep(
            icon: "square.and.arrow.down",
            title: "安装快捷指令",
            description: "点击下方按钮，安装「记账助手」快捷指令。安装后只需按一下操作按钮，即可自动记账。"
        ),
        OnboardingStep(
            icon: "rectangle.3.group.fill",
            title: "绑定操作按钮",
            description: "打开 设置 → 操作按钮 → 选择「快捷指令」→ 选择「记账助手」"
        ),
        OnboardingStep(
            icon: "checkmark.circle.fill",
            title: "开始使用",
            description: "付款后按一下操作按钮，App 自动识别金额并弹出记账面板。全程只需两步。"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            VStack(spacing: 8) {
                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 8)
                
                Text(steps[currentStep].title)
                    .font(.system(size: 24, weight: .bold))
                
                Text(steps[currentStep].description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
            .padding(.bottom, 40)
            
            Spacer()
            
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { i in
                    Circle()
                        .fill(i == currentStep ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentStep)
                }
            }
            .padding(.bottom, 24)
            
            // Action button
            Button(action: handleAction) {
                HStack(spacing: 8) {
                    if currentStep == 0 && isGenerating {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(currentStep == 0 ? "安装快捷指令" :
                         currentStep == 1 ? "下一步" :
                         "开始记账")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isGenerating && currentStep == 0 ? Color.accentColor.opacity(0.5) : Color.accentColor)
                .cornerRadius(14)
            }
            .disabled(isGenerating && currentStep == 0)
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
            
            // Skip button
            if currentStep < 2 {
                Button {
                    completeOnboarding()
                } label: {
                    Text("跳过，稍后设置")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
            } else {
                Color.clear.frame(height: 52).padding(.bottom, 40)
            }
        }
        .onAppear {
            generateShortcut()
        }
        .sheet(isPresented: $showShortcutShare) {
            if let url = shortcutFileURL {
                ShareSheet(items: [url])
                    .onAppear {
                        // Give user time to share, then auto-advance after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            // Don't auto-advance, let user come back
                        }
                    }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func generateShortcut() {
        isGenerating = true
        DispatchQueue.global().async {
            let url = ShortcutGenerator.generateShortcutFile()
            DispatchQueue.main.async {
                shortcutFileURL = url
                isGenerating = false
            }
        }
    }
    
    private func handleAction() {
        switch currentStep {
        case 0:
            // Present share sheet with shortcut file
            if shortcutFileURL != nil {
                showShortcutShare = true
            }
        case 1:
            withAnimation {
                currentStep = 2
            }
        case 2:
            completeOnboarding()
        default:
            break
        }
    }
    
    private func completeOnboarding() {
        withAnimation {
            isCompleted = true
        }
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }
}

private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}
