import SwiftUI

struct ExpenseListView: View {
    @ObservedObject var store: ExpenseStore
    @Binding var showPopup: Bool
    @Binding var popupAmount: Double?
    @Binding var isManualEntry: Bool
    
    @State private var showDeleteAlert = false
    @State private var deleteTarget: Expense?
    
    var body: some View {
        ZStack {
            if store.expenses.isEmpty {
                emptyState
            } else {
                listContent
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        isManualEntry = true
                        popupAmount = nil
                        showPopup = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .alert("删除记录", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let expense = deleteTarget {
                    withAnimation {
                        store.delete(expense.id)
                    }
                }
            }
        } message: {
            if let expense = deleteTarget {
                Text("确定删除这笔 \(expense.formattedAmount) 的支出吗？")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("还没有记账记录")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Text("点击右下角 + 号开始记账")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
    
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Monthly summary header
                let monthExpenses = store.expenses(for: Date())
                if !monthExpenses.isEmpty {
                    VStack(spacing: 4) {
                        Text("本月支出")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text(store.total(for: Date()).formattedAmount)
                            .font(.system(size: 28, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                
                // Expense items
                ForEach(store.expenses) { expense in
                    ExpenseRow(expense: expense)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            deleteTarget = expense
                            showDeleteAlert = true
                        }
                    
                    if expense.id != store.expenses.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                Image(systemName: expense.category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.category.rawValue)
                    .font(.system(size: 15, weight: .medium))
                
                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(expense.formattedAmount)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(expense.displayDate)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
    }
}
