import SwiftUI
import Charts

struct AnalysisView: View {
    @EnvironmentObject var lm: LocalizationManager
    var transactions: [BillItem]
    var title: String
    
    @State private var aiAdvice: String = ""
    @State private var isAnalyzing: Bool = false
    @AppStorage("selected_ai_provider") private var selectedProvider = "DeepSeek"
    
    var totalExpense: Double { abs(transactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount }) }
    var totalIncome: Double { transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount } }
    
    var expensesByChannel: [(channel: String, amount: Double)] {
        let expenses = transactions.filter { $0.amount < 0 }
        let grouped = Dictionary(grouping: expenses) { $0.channel }
        return grouped.map { (key, value) in (key, abs(value.reduce(0) { $0 + $1.amount })) }.sorted { $0.amount > $1.amount }
    }
    
    var incomeByChannel: [(channel: String, amount: Double)] {
        let incomes = transactions.filter { $0.amount > 0 }
        let grouped = Dictionary(grouping: incomes) { $0.channel }
        return grouped.map { (key, value) in (key, value.reduce(0) { $0 + $1.amount }) }.sorted { $0.amount > $1.amount }
    }
    
    var expensesByCategory: String {
        let expenses = transactions.filter { $0.amount < 0 }
        let grouped = Dictionary(grouping: expenses) { $0.category }
        let summary = grouped.map { "\($0.key):\(abs($0.value.reduce(0){$0+$1.amount}))" }.joined(separator: ", ")
        return summary.isEmpty ? lm.t("无支出") : summary
    }
    
    // 定义自适应背景色：浅色模式白色，深色模式深灰
    let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 顶部数字汇总
                    HStack(spacing: 15) {
                        VStack {
                            Text(lm.t("总收入")).font(.caption).foregroundStyle(.gray)
                            Text("¥\(String(format: "%.2f", totalIncome))").font(.title2).bold().foregroundStyle(.green)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(cardBackground) // ✅ 修复背景
                        .cornerRadius(10)
                        
                        VStack {
                            Text(lm.t("总支出")).font(.caption).foregroundStyle(.gray)
                            Text("¥\(String(format: "%.2f", totalExpense))").font(.title2).bold().foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(cardBackground) // ✅ 修复背景
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // 2. AI 财务分析板块
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles").foregroundStyle(.purple)
                            Text("\(lm.t("AI 财务分析")) (\(selectedProvider))").font(.headline)
                            Spacer()
                            if isAnalyzing {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Button(lm.t("开始分析")) { startAIAnalysis() }
                                    .font(.caption).padding(6).background(Color.purple.opacity(0.1)).foregroundColor(.purple).cornerRadius(8)
                            }
                        }
                        
                        if !aiAdvice.isEmpty {
                            Text(aiAdvice)
                                .font(.system(size: 15))
                                .lineSpacing(6)
                                .padding()
                                .background(Color.gray.opacity(0.1)) // 使用半透明灰，深浅通吃
                                .cornerRadius(8)
                        } else {
                            Text(lm.t("点击按钮，生成收支结构评价与省钱建议。")).font(.caption).foregroundStyle(.gray)
                        }
                    }
                    .padding()
                    .background(cardBackground) // ✅ 修复背景
                    .cornerRadius(12).padding(.horizontal)
                    
                    // 3. 图表展示
                    if !expensesByChannel.isEmpty {
                        ChartBlock(title: lm.t("支出构成"), items: expensesByChannel, color: .red)
                    }
                    if !incomeByChannel.isEmpty {
                        ChartBlock(title: lm.t("收入构成"), items: incomeByChannel, color: .green)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // ✅ 确保整个页面背景是系统默认的（浅色是灰，深色是黑），这样上面的卡片（深灰）才能显现出来
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    func startAIAnalysis() {
        let dataSummary = "时间范围：\(title)\n总收入：\(totalIncome)\n总支出：\(totalExpense)\n支出分类明细：\(expensesByCategory)"
        isAnalyzing = true
        aiAdvice = ""
        Task {
            do {
                let result = try await AIService.shared.analyzeFinancialData(summary: dataSummary, provider: selectedProvider, language: lm.language)
                await MainActor.run {
                    self.aiAdvice = result
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.aiAdvice = "\(lm.t("分析失败"))：\(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
}

// 独立的图表组件
struct ChartBlock: View {
    let title: String
    let items: [(channel: String, amount: Double)]
    let color: Color
    
    // 再次定义背景色
    let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title).font(.headline).padding(.leading)
            Chart(items, id: \.channel) { item in
                SectorMark(angle: .value("金额", item.amount), innerRadius: .ratio(0.6), angularInset: 1.5)
                    .foregroundStyle(by: .value("渠道", item.channel))
                    .annotation(position: .overlay) {
                        if item.amount / items.reduce(0){$0+$1.amount} > 0.1 {
                            // ✅ 关键：深色模式下，扇形上的字强制白色，否则可能看不清
                            Text(item.channel).font(.caption2).foregroundColor(.white).bold()
                        }
                    }
            }
            .frame(height: 220)
            
            Divider()
            
            ForEach(items, id: \.channel) { item in
                HStack {
                    Circle().fill(color).frame(width: 8, height: 8)
                    Text(item.channel).font(.subheadline)
                    Spacer()
                    // ✅ .primary 会自动变色（浅色黑，深色白）
                    Text("¥\(String(format: "%.2f", item.amount))").bold().font(.system(.body, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(cardBackground) // ✅ 修复背景
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
