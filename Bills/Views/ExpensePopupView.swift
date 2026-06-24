import SwiftUI

struct ExpensePopupView: View {
    @ObservedObject var store: ExpenseStore
    
    let initialAmount: Double?
    var onDismiss: (() -> Void)?
    
    @State private var amount: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var isManualEntry: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 80, maximum: 90), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Title
            if isManualEntry {
                Text("记一笔")
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.bottom, 16)
            }
            
            // Amount display / input
            HStack(alignment: .center, spacing: 4) {
                Text("¥")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                if isManualEntry {
                    TextField("0.00", text: $amount)
                        .font(.system(size: 40, weight: .bold))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .frame(height: 48)
                } else {
                    Text(displayAmount)
                        .font(.system(size: 40, weight: .bold))
                }
            }
            .padding(.top, isManualEntry ? 0 : 20)
            .padding(.bottom, 24)
            
            // Note input
            HStack(spacing: 8) {
                Image(systemName: "pencil.line")
                    .foregroundColor(.secondary)
                TextField("备注（选填）", text: $note)
                    .font(.system(size: 16))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Category grid
            Text("选择分类")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(ExpenseCategory.allCases) { category in
                    categoryButton(category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            
            // Save button
            Button(action: saveExpense) {
                Text("保存")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .onAppear {
            if let amt = initialAmount {
                amount = String(format: "%.2f", amt)
            }
        }
        .alert("保存失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var displayAmount: String {
        if let amt = initialAmount {
            return String(format: "%.2f", amt)
        }
        return "—"
    }
    
    @ViewBuilder
    private func categoryButton(_ category: ExpenseCategory) -> some View {
        Button {
            selectedCategory = category
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedCategory == category ? Color.accentColor : Color(.systemGray6))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                }
                
                Text(category.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(selectedCategory == category ? .accentColor : .secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入有效的金额"
            showError = true
            return
        }
        
        let expense = Expense(
            amount: amountValue,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory
        )
        
        withAnimation {
            store.add(expense)
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}

// Corner radius helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
