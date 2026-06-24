import Foundation
import Combine

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var selectedMonth: Date = Date()
    
    private let saveKey = "expenses"
    private let defaults = UserDefaults.standard
    
    init() {
        load()
    }
    
    // MARK: - CRUD
    
    func add(_ expense: Expense) {
        expenses.append(expense)
        expenses.sort { $0.date > $1.date }
        save()
    }
    
    func delete(_ id: UUID) {
        expenses.removeAll { $0.id == id }
        save()
    }
    
    func update(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            save()
        }
    }
    
    // MARK: - Query
    
    func expenses(for month: Date) -> [Expense] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let start = calendar.date(from: components),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return []
        }
        return expenses.filter { $0.date >= start && $0.date < end }
    }
    
    func total(for month: Date) -> Double {
        expenses(for: month).reduce(0) { $0 + $1.amount }
    }
    
    func byCategory(for month: Date) -> [(ExpenseCategory, Double)] {
        let items = expenses(for: month)
        var dict: [ExpenseCategory: Double] = [:]
        for item in items {
            dict[item.category, default: 0] += item.amount
        }
        return dict.sorted { $0.value > $1.value }
    }
    
    func dailyTotals(for month: Date) -> [(Date, Double)] {
        let items = expenses(for: month)
        let calendar = Calendar.current
        var dict: [Date: Double] = [:]
        for item in items {
            let day = calendar.startOfDay(for: item.date)
            dict[day, default: 0] += item.amount
        }
        return dict.sorted { $0.key < $1.key }
    }
    
    func averageDaily(for month: Date) -> Double {
        let items = expenses(for: month)
        guard !items.isEmpty else { return 0 }
        let calendar = Calendar.current
        let days = Set(items.map { calendar.startOfDay(for: $0.date) }).count
        return days > 0 ? total(for: month) / Double(days) : 0
    }
    
    func maxExpense(for month: Date) -> Expense? {
        expenses(for: month).max(by: { $0.amount < $1.amount })
    }
    
    func monthOverMonthChange(for month: Date) -> Double? {
        let calendar = Calendar.current
        guard let prev = calendar.date(byAdding: .month, value: -1, to: month) else { return nil }
        let current = total(for: month)
        let previous = total(for: prev)
        guard previous > 0 else { return current > 0 ? 100 : nil }
        return ((current - previous) / previous) * 100
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(expenses)
            defaults.set(data, forKey: saveKey)
        } catch {
            print("Failed to save expenses: \(error)")
        }
    }
    
    private func load() {
        guard let data = defaults.data(forKey: saveKey) else { return }
        do {
            expenses = try JSONDecoder().decode([Expense].self, from: data)
            expenses.sort { $0.date > $1.date }
        } catch {
            print("Failed to load expenses: \(error)")
        }
    }
}
