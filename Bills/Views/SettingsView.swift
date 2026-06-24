import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: ExpenseStore
    
    @State private var showClearConfirm = false
    @State private var showExportShare = false
    @State private var exportURL: URL?
    @State private var isInstallingShortcut = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Quick Setup Guide
                Section("快速上手") {
                    VStack(alignment: .leading, spacing: 12) {
                        setupStep(number: 1, title: "安装快捷指令", detail: "点击下方按钮，安装「记账助手」快捷指令")
                        setupStep(number: 2, title: "绑定操作按钮", detail: "设置 → 操作按钮 → 选择「快捷指令」→ 选择「记账助手」")
                        setupStep(number: 3, title: "开始使用", detail: "付款后按一下操作按钮，App 自动识别并弹出记账")
                    }
                    .listRowBackground(Color(.systemGray6))
                    
                    // One-tap install button
                    Button(action: installShortcut) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16))
                            Text("一键安装快捷指令")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .disabled(isInstallingShortcut)
                }
                
                // MARK: - Data
                Section("数据") {
                    HStack {
                        Text("总记录数")
                        Spacer()
                        Text("\(store.expenses.count) 笔")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("数据导出")
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accentColor)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        exportData()
                    }
                }
                
                // MARK: - Danger Zone
                Section("危险操作") {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("清空所有数据")
                        }
                    }
                }
                
                // MARK: - About
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("数据存储")
                        Spacer()
                        Text("本地")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .alert("清空所有数据", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    withAnimation {
                        store.expenses.removeAll()
                    }
                }
            } message: {
                Text("此操作不可撤销，所有记录将被永久删除。")
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func setupStep(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
    
    private func installShortcut() {
        isInstallingShortcut = true
        if let url = ShortcutGenerator.importShortcutURL {
            UIApplication.shared.open(url) { success in
                isInstallingShortcut = false
            }
        } else {
            isInstallingShortcut = false
        }
    }
    
    private func exportData() {
        // Simple CSV export
        var csv = "金额,分类,备注,日期\n"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for expense in store.expenses {
            let note = expense.note.replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\(expense.amount),\(expense.category.rawValue),\"\(note)\",\(formatter.string(from: expense.date))\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("账单导出_\(Date().timeIntervalSince1970).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        
        exportURL = url
        showExportShare = true
    }
}
