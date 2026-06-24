import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    
    @State private var currentStep = 0
    @State private var isInstallingShortcut = false
    @State private var installFailed = false
    @State private var showManualGuide = false
    @State private var showShareSheet = false
    @State private var shortcutFileURL: URL?
    @State private var shortcutGenerated = false
    
    private let steps = [
        OnboardingStep(
            icon: "square.and.arrow.down",
            title: "安装快捷指令",
            description: "按下方按钮自动从网络导入，或手动创建（仅需1个操作，10秒搞定）"
        ),
        OnboardingStep(
            icon: "rectangle.3.group.fill",
            title: "绑定操作按钮",
            description: "设置 → 操作按钮 → 选择「快捷指令」→ 选择「记账助手」"
        ),
        OnboardingStep(
            icon: "checkmark.circle.fill",
            title: "开始使用",
            description: "付款后先截屏（音量上+电源键），再按操作按钮自动识别记账"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
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
                    if currentStep == 0 && isInstallingShortcut {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(currentStep == 0 && installFailed ? "重试安装" :
                         currentStep == 0 ? "安装快捷指令" :
                         currentStep == 1 ? "下一步" :
                         "开始记账")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(isInstallingShortcut && currentStep == 0 ? Color.accentColor.opacity(0.5) : Color.accentColor)
                .cornerRadius(14)
            }
            .disabled(isInstallingShortcut && currentStep == 0)
            .padding(.horizontal, 32)
            .padding(.bottom, 12)
            
            if currentStep == 0 && installFailed {
                Button {
                    showManualGuide = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.up")
                            .font(.system(size: 13))
                        Text("手动创建快捷指令（快速 / 10秒）")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                Button {
                    showShareSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13))
                        Text("通过文件导入")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
            
            Button {
                completeOnboarding()
            } label: {
                Text("跳过，稍后设置")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showManualGuide) {
            ManualShortcutGuideView(isPresented: $showManualGuide)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shortcutFileURL {
                ShareSheet(items: [url])
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            generateShortcutFile()
        }
    }
    
    private func generateShortcutFile() {
        guard !shortcutGenerated else { return }
        shortcutFileURL = ShortcutGenerator.generateShortcutFile()
        shortcutGenerated = true
    }
    
    private func handleAction() {
        switch currentStep {
        case 0:
            isInstallingShortcut = true
            installFailed = false
            if let url = ShortcutGenerator.importShortcutURL {
                UIApplication.shared.open(url) { success in
                    isInstallingShortcut = false
                    installFailed = !success
                }
            } else {
                isInstallingShortcut = false
                installFailed = true
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

// MARK: - Manual Shortcut Guide (iOS 18 compatible - 1 action: Open URL)
struct ManualShortcutGuideView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section("快捷指令（1个操作）") {
                    VStack(alignment: .leading, spacing: 16) {
                        manualStep(number: 1,
                                   icon: "square.and.pencil",
                                   title: "新建快捷指令",
                                   detail: "打开「快捷指令」App → 点右上角「+」新建一个")
                        
                        Divider()
                        
                        manualStep(number: 2,
                                   icon: "link",
                                   title: "添加「打开URL」",
                                   detail: "点「添加操作」→ 搜索「打开URL」→ 在 URL 栏输入：bills://process")
                        
                        Divider()
                        
                        manualStep(number: 3,
                                   icon: "character.book.closed",
                                   title: "重命名保存",
                                   detail: "点顶部标题重命名为「记账助手」→ 点「完成」")
                    }
                    .listRowBackground(Color(.systemGray6))
                }
                
                Section("绑定操作按钮") {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "rectangle.3.group.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                        Text("设置 → 操作按钮 → 快捷指令 → 选择「记账助手」")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("使用流程") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("付款后按「音量上 + 电源键」截屏")
                                .font(.system(size: 15))
                        }
                        HStack(spacing: 10) {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("按操作按钮 → 快捷指令打开 App → 自动识别记账")
                                .font(.system(size: 15))
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("更省事的办法（自动化）") {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                        Text("快捷指令 App → 自动化 → 创建个人自动化 → 截屏 → 运行「记账助手」→ 关闭「运行前询问」。设置后每次截屏都自动触发，连操作按钮都不需要按。")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("手动创建快捷指令")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func manualStep(number: Int, icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
        }
    }
}

private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}
