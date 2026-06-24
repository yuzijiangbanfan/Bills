import SwiftUI
import Charts

struct MonthlyReportView: View {
    @ObservedObject var store: ExpenseStore
    
    @State private var selectedMonth: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month picker
                monthPicker
                
                let monthExpenses = store.expenses(for: selectedMonth)
                
                if monthExpenses.isEmpty {
                    emptyReport
                } else {
                    // Summary cards
                    summaryCards
                    
                    // Category breakdown
                    if !store.byCategory(for: selectedMonth).isEmpty {
                        categorySection
                    }
                    
                    // Daily trend
                    if store.dailyTotals(for: selectedMonth).count > 1 {
                        dailyTrendSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("月报")
    }
    
    private var monthPicker: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            Text(monthString(selectedMonth))
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
            
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
        .padding(.horizontal, 4)
    }
    
    private var emptyReport: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text("该月暂无支出记录")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var summaryCards: some View {
        VStack(spacing: 12) {
            // Total card
            summaryCard(
                title: "总支出",
                value: store.total(for: selectedMonth).formattedAmount,
                icon: "creditcard.fill",
                color: .accentColor
            )
            
            HStack(spacing: 12) {
                summaryCard(
                    title: "笔数",
                    value: "\(store.expenses(for: selectedMonth).count)",
                    icon: "list.bullet",
                    color: .blue,
                    isSmall: true
                )
                
                summaryCard(
                    title: "日均",
                    value: store.averageDaily(for: selectedMonth).formattedAmount,
                    icon: "calendar",
                    color: .green,
                    isSmall: true
                )
            }
            
            // Max expense
            if let max = store.maxExpense(for: selectedMonth) {
                summaryCard(
                    title: "最大单笔",
                    value: "\(max.formattedAmount)（\(max.category.rawValue)）",
                    icon: "arrow.up.right.circle.fill",
                    color: .orange,
                    isSmall: true
                )
            }
            
            // Month-over-month
            if let change = store.monthOverMonthChange(for: selectedMonth) {
                let isUp = change > 0
                summaryCard(
                    title: "环比上月",
                    value: "\(isUp ? "+" : "")\(String(format: "%.1f", change))%",
                    icon: isUp ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                    color: isUp ? .red : .green,
                    isSmall: true
                )
            }
        }
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color, isSmall: Bool = false) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: isSmall ? 18 : 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: isSmall ? 16 : 24, weight: .bold))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    // MARK: - Category Chart (horizontal bar chart, iOS 16 compatible)
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类支出")
                .font(.system(size: 17, weight: .semibold))
            
            let categories = store.byCategory(for: selectedMonth)
            let total = store.total(for: selectedMonth)
            
            ForEach(categories, id: \.0) { category, amount in
                HStack(spacing: 12) {
                    Image(systemName: category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(width: 28)
                    
                    Text(category.rawValue)
                        .font(.system(size: 14))
                        .frame(width: 80, alignment: .leading)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 16)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor)
                                .frame(width: total > 0 ? geo.size.width * amount / total : 0, height: 16)
                        }
                    }
                    .frame(height: 16)
                    
                    Text("\(Int(amount / total * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                    
                    Text(amount.formattedAmount)
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 72, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    // MARK: - Daily Trend
    
    private var dailyTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每日趋势")
                .font(.system(size: 17, weight: .semibold))
            
            Chart(store.dailyTotals(for: selectedMonth), id: \.0) { day, amount in
                BarMark(
                    x: .value("日期", day, unit: .day),
                    y: .value("金额", amount)
                )
                .foregroundStyle(Color.accentColor.gradient)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        let day = calendar.component(.day, from: date)
                        AxisValueLabel {
                            Text("\(day)日")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    private func monthString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}

extension Double {
    var formattedAmount: String {
        String(format: "¥%.2f", self)
    }
}
