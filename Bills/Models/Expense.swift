import Foundation

struct Expense: Codable, Identifiable, Equatable {
    let id: UUID
    var amount: Double
    var note: String
    var category: ExpenseCategory
    var date: Date
    
    init(id: UUID = UUID(), amount: Double, note: String = "", category: ExpenseCategory, date: Date = Date()) {
        self.id = id
        self.amount = amount
        self.note = note
        self.category = category
        self.date = date
    }
    
    var formattedAmount: String {
        String(format: "¥%.2f", amount)
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
}
