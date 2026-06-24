# 账单助手 — Project Context for AI Agents

## 项目概述

iOS 记账应用。核心功能：iPhone 操作按钮 → 截屏 → OCR 识别金额 → 弹出记账面板 → 选分类 → 保存 → 截图自动删除。

## 技术栈

| 项目 | 选型 |
|------|------|
| 平台 | iOS 16+ |
| 语言 | Swift 5.7 |
| UI | SwiftUI |
| 图表 | Swift Charts (iOS 16，无 SectorMark) |
| OCR | Vision (VNRecognizeTextRequest) |
| 持久化 | UserDefaults + JSON（Codable） |
| 分享 | UIActivityViewController |
| URL Scheme | `bills://process`，`bills://add?amount=X` |
| 相册 | Photos (PHPhotoLibrary) |
| 快捷指令 | App 运行时用 NSKeyedArchiver 生成 .shortcut 文件 |

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
│   └── ShortcutGenerator.swift ← NSKeyedArchiver 生成 .shortcut 文件
├── Views/
│   ├── OnboardingView.swift    ← 首次启动引导（含一键安装快捷指令）
│   ├── ExpensePopupView.swift  ← 记账弹窗（金额/备注/分类网格）
│   ├── ExpenseListView.swift   ← 支出列表（长按删除）
│   ├── MonthlyReportView.swift ← 月报（摘要卡片 + 分类条形图 + 每日趋势）
│   ├── SettingsView.swift      ← 设置（快速上手/数据导出/清空）
│   └── ShareSheet.swift        ← UIActivityViewController 封装
├── Helpers/
│   └── AmountParser.swift      ← OCR 文本 → Double（¥X.XX / X.XX元 / -¥X.XX）
└── Resources/
    ├── Info.plist              ← URL Scheme + 相册权限
    └── Assets.xcassets/
```

## 关键模式与约束

### 1. NSCoding 类必须有稳定 Obj-C 名
用 `NSKeyedArchiver.setClassName` 映射自定义类到 Shortcuts 私有类名时，自定义类用 `fileprivate` 且加 `@objc(Name)` 避免 Swift 编译报错：

```swift
@objc(WKWF) fileprivate class _WFWorkflow: NSObject, NSCoding { ... }
@objc(WKAC) fileprivate class _WFACtion: _WFWorkflow {}
@objc(WKIC) fileprivate class _WFIcon: _WFWorkflow {}
```

### 2. Swift Charts 避免使用 SectorMark
Xcode 14.2 / iOS 16 SDK 不支持 SectorMark。饼图/环形图改用水平条形图：

```swift
ForEach(categories, id: \.0) { category, amount in
    HStack {
        Image(systemName: category.icon)
        Text(category.rawValue).frame(width: 80, alignment: .leading)
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.accentColor)
                .frame(width: geo.size.width * amount / total)
        }
        Text("\(Int(amount/total*100))%")
        Text(amount.formattedAmount)
    }
}
```

### 3. 动画 API：Xcode 14 需要用 `.spring()`
```swift
// 错误：.animation(.spring, value: x) → 编译报错
// 正确：
.animation(.spring(), value: x)
```

### 4. 首次启动引导
用 `@AppStorage("onboarding_completed")` 控制。未完成引导时不显示主界面。

### 5. 相册权限
Info.plist 已添加：
- `NSPhotoLibraryUsageDescription` = "用于自动识别付款截图中的金额"
- `NSPhotoLibraryAddUsageDescription` = "用于临时存储并自动删除付款截图"

### 6. 快捷指令安装流程
App 内用 ShortcutGenerator 在运行时生成 .shortcut 文件（不用预签名），UIActivityViewController 分享到快捷指令 App。用户须在快捷指令中点「添加快捷指令」确认（iOS 安全限制，无法静默安装）。

### 7. 金额解析优先级
1. `¥XX.XX`
2. `XX.XX元`
3. `-¥XX.XX`（支出格式）
4. 纯 `XX.XX`（兜底）

### 8. 记账户默认使用 UserDefaults
`ExpenseStore` 使用 `UserDefaults` + JSON Codable 持久化。数据量小（个人记账），无需 CoreData。

## 常见修改场景

### 增加分类
在 `ExpenseCategory.swift` 的 enum 中添加 case，提供 `icon` 和 `tint`。

### 调整月报图表
修改 `MonthlyReportView.swift` 的 `categorySection`（分类）或 `dailyTrendSection`（趋势）。

### 修改快捷指令动作
编辑 `ShortcutGenerator.swift` 的 `generateShortcutData()` 方法，修改 `WFWorkflowActionIdentifier` 和参数。

## 构建验证

```bash
cd project/Bills
xcodebuild -project Bills.xcodeproj -target Bills \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14 Pro' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO build
```

## 首次运行地址

```
/Users/wuxingfeng/Documents/Codex/2026-06-24/ai-ai-ai-ai-ai/outputs/Bills/Bills.xcodeproj
```
