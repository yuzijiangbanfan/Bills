# 账单助手 — Project Context for AI Agents

## 项目概述

iOS 记账应用。核心功能：iPhone 操作按钮 → 截屏 → OCR 识别金额 → 弹出记账面板 → 选分类 → 保存 → 截图自动删除。

## 技术栈

| 项目 | 选型 |
|------|------|
| 平台 | iOS 16+ |
| 语言 | Swift 5.7 |
| UI | SwiftUI |
| 图表 | 自定义水平条形图（iOS 16 Compatible） |
| OCR | Vision (VNRecognizeTextRequest) |
| 持久化 | UserDefaults + JSON（Codable） |
| 分享 | UIActivityViewController（ShareSheet） |
| URL Scheme | `bills://process`，`bills://add?amount=X` |
| 相册 | Photos (PHPhotoLibrary) |
| 快捷指令 | macOS `shortcuts sign --mode anyone` 预签名，GitHub hosted，shortcuts:// URL scheme 导入 |

## 项目结构

```
Bills/
├── BillsApp.swift              ← @main 入口，URL Scheme 处理，首次引导
├── Models/
│   ├── Expense.swift           ← Codable 数据模型
│   └── ExpenseCategory.swift   ← 10 种分类（带 SF Symbol 图标和色值）
├── Services/
│   ├── ExpenseStore.swift      ← CRUD + 按月查询 + 月报聚合
│   ├── OCRService.swift        ← Vision OCR（zh-Hans + en-US）
│   ├── ScreenshotHandler.swift ← 相册读取→OCR→删除 全流程
│   └── ShortcutGenerator.swift ← GitHub raw URL + shortcuts:// import URL
├── Views/
│   ├── OnboardingView.swift    ← 首次启动引导（shortcuts:// 从 GitHub 导入）
│   ├── ExpensePopupView.swift  ← 记账弹窗（金额/备注/分类网格）
│   ├── ExpenseListView.swift   ← 支出列表（长按删除）
│   ├── MonthlyReportView.swift ← 月报（摘要卡片 + 分类条形图 + 每日趋势）
│   ├── SettingsView.swift      ← 设置（快速上手/数据导出/清空/重装快捷指令）
│   └── ShareSheet.swift        ← UIActivityViewController 封装
├── Helpers/
│   └── AmountParser.swift      ← OCR 文本 → Double（¥X.XX / X.XX元 / -¥X.XX）
└── Resources/
    ├── Info.plist              ← URL Scheme + 相册权限
    └── Assets.xcassets/
```

## 关键模式与约束

### 1. 快捷指令安装方式（已签名）
不再用 NSKeyedArchiver 动态生成未签名 .shortcut。改用 macOS `shortcuts sign --mode anyone` 预签名，将 `.shortcut` 文件上传到 GitHub，App 通过 `shortcuts://import-shortcut?url=` URL scheme 从 GitHub raw URL 导入。

```
# 签名命令（macOS 上执行一次）
shortcuts sign --mode anyone -i process_bills.shortcut -o process_bills.signed.shortcut

# 然后将 .shortcut 文件复制到 Xcode 项目根目录并推送到 GitHub
cp process_bills.signed.shortcut Bills.shortcut
```

安装流程：OnboardingView / SettingsView 点击按钮 → `UIApplication.shared.open(ShortcutGenerator.importShortcutURL)` → 系统打开 `shortcuts://import-shortcut?url=...` → 快捷指令 App 弹出导入界面 → 用户点「添加快捷指令」。

⚠️ `shortcuts://import-shortcut` URL scheme 需要 iOS 网络连接才能下载文件。iOS 15+ 支持该 scheme。

快捷指令内容（2 个动作）：
1. 截屏（Take Screenshot）
2. 打开 URL `bills://process`

### 2. 首次启动引导
用 `@AppStorage("onboarding_completed")` 控制。未完成引导时不显示主界面。

引导页用 `shortcuts://` URL scheme 直接从 GitHub 导入预签名快捷指令。用户须在快捷指令 App 中点「添加快捷指令」确认（iOS 安全限制，无法静默安装）。

### 3. 相册权限
Info.plist 已添加：
- `NSPhotoLibraryUsageDescription` = "用于自动识别付款截图中的金额"
- `NSPhotoLibraryAddUsageDescription` = "用于临时存储并自动删除付款截图"

### 4. 快捷指令触发流程
1. 用户按操作按钮 → 系统截屏
2. 快捷指令打开 `bills://process` URL
3. App 收到 URL → 读取相册最新照片 → OCR 识别 → 弹出记账面板
4. 记完账后自动删除截图

### 5. 金额解析优先级
1. `¥XX.XX`
2. `XX.XX元`
3. `-¥XX.XX`（支出格式）
4. 纯 `XX.XX`（兜底）

### 6. 记账户默认使用 UserDefaults
`ExpenseStore` 使用 `UserDefaults` + JSON Codable 持久化。数据量小（个人记账），无需 CoreData。

### 7. Swift Charts 避免使用 SectorMark
Xcode 14.2 / iOS 16 SDK 不支持 SectorMark。饼图/环形图改用水平条形图。

### 8. Bundle ID
`com.yuzijiangbanfan.bills`（已在 Apple Developer Portal 注册）

### 9. GitHub
- Repo: https://github.com/yuzijiangbanfan/Bills

## 常见修改场景

### 增加分类
在 `ExpenseCategory.swift` 的 enum 中添加 case，提供 `icon` 和 `tint`。

### 调整月报图表
修改 `MonthlyReportView.swift` 的 `categorySection`（分类）或 `dailyTrendSection`（趋势）。

### 更新快捷指令
1. 在 macOS「快捷指令」App 中编辑 `process_bills` 快捷指令
2. 导出为 .shortcut 文件：`shortcuts sign --mode anyone -i process_bills.shortcut -o Bills.shortcut`
3. 将 `Bills.shortcut` 复制到 Xcode 项目根目录并推送到 GitHub
4. 无需修改 Swift 代码（`shortcutRawURL` 指向固定 GitHub raw URL）
5. 可选：如更换 repo 路径，更新 `ShortcutGenerator.swift` 中的 `shortcutRawURL`

## 构建验证

```bash
cd /Users/wuxingfeng/Documents/Codex/2026-06-24/ai-ai-ai-ai-ai/outputs/Bills
xcodebuild -project Bills.xcodeproj -target Bills \
  -sdk iphoneos -destination 'platform=iOS,name=iPhone 15 Pro' build CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY=""
```

## 项目路径
```
/Users/wuxingfeng/Documents/Codex/2026-06-24/ai-ai-ai-ai-ai/outputs/Bills/Bills.xcodeproj
```

## 工作纪律

### 关键架构变动需经用户同意
任何涉及核心功能变更的修改（如快捷指令架构、触发方式、数据流），必须先与用户讨论并获得明确同意，不可直接实施。
- 用户明确告知 iOS 18 快捷指令中没有「截屏」操作
- 这是一个客观事实约束，但**解决方案的选择**（修改快捷指令架构、改用自动化、换触发方式等）需由用户决定
- 错误案例：未经讨论直接修改了 ManualShortcutGuideView 中的手动创建步骤
