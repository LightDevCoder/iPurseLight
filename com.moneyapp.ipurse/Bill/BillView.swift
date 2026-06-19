import SwiftUI
import SwiftData
import Charts
import UniformTypeIdentifiers

struct BillView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var lm: LocalizationManager
    
    @EnvironmentObject var quickActionManager: QuickActionManager
    
    @Query(sort: \BillItem.date, order: .reverse) var transactions: [BillItem]
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var showAddTransaction = false
    @State private var showFileImporter = false
    @State private var showAnalysis = false
    @State private var showYearAnalysis = false
    @State private var showSettings = false
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<UUID>()
    @State private var editingItem: BillItem?
    
    @State private var initialVoiceText: String = ""
    
    var availableYears: [Int] {
        let years = Set(transactions.map { $0.year })
        return years.isEmpty ? [selectedYear] : Array(years).sorted(by: >)
    }
    
    var monthlyTransactions: [BillItem] {
        transactions.filter { $0.year == selectedYear && $0.month == selectedMonth }
    }
    
    var yearlyTransactions: [BillItem] {
        transactions.filter { $0.year == selectedYear }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    HStack {
                        Button(action: { showYearAnalysis = true }) {
                            Label(lm.t("年度汇总"), systemImage: "chart.bar.xaxis")
                                .font(.caption).padding(6).background(Color.orange.opacity(0.1)).foregroundColor(.orange).cornerRadius(8)
                        }
                        Spacer()
                        Text(lm.t("年份"))
                        Picker(lm.t("年份"), selection: $selectedYear) {
                            ForEach(availableYears, id: \.self) { year in
                                Text(lm.formatYear(year)).tag(year)
                            }
                        }.pickerStyle(.menu)
                    }.padding(.horizontal).padding(.top, 5)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(1...12, id: \.self) { month in
                                Button(action: { selectedMonth = month }) {
                                    Text(lm.formatMonth(month))
                                        .font(.subheadline)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 16)
                                        .background(selectedMonth == month ? Color.blue : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedMonth == month ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }.padding(.horizontal)
                    }.padding(.bottom, 10)
                }.background(Color(UIColor.systemGroupedBackground))
                
                List(selection: $selection) {
                    if monthlyTransactions.isEmpty {
                        ContentUnavailableView(
                            "\(lm.formatYear(selectedYear)) \(lm.formatMonth(selectedMonth)) - \(lm.t("无数据"))",
                            systemImage: "calendar"
                        )
                    } else {
                        ForEach(monthlyTransactions) { item in
                            Button(action: { if editMode == .inactive { editingItem = item } }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.date, format: .dateTime.day().month()).font(.caption).foregroundColor(.gray)
                                        Text(item.category).font(.headline)
                                    }.frame(width: 80, alignment: .leading)
                                    if !item.note.isEmpty { Text(item.note).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(formatMoney(item.amount)).foregroundStyle(item.type == "收入" || item.amount > 0 ? .green : .primary).bold()
                                        Text(item.channel).font(.system(size: 10)).padding(3)
                                            .background(channelColor(item.channel).opacity(0.1))
                                            .foregroundColor(channelColor(item.channel)).cornerRadius(4)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .tag(item.id)
                        }
                    }
                }.listStyle(.plain)
            }
            .environment(\.editMode, $editMode)
            .navigationTitle(lm.t("账单流水"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if editMode == .active {
                        Button(lm.t("全选")) { selection = (selection.count == monthlyTransactions.count) ? [] : Set(monthlyTransactions.map { $0.id }) }
                    } else {
                        Button(lm.t("本月统计"), systemImage: "chart.pie") { showAnalysis = true }
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if editMode == .active {
                        Button(lm.t("删除")) { deleteSelectedItems() }
                        Button(lm.t("完成")) { editMode = .inactive; selection.removeAll() }
                    } else {
                        Button(lm.t("选择")) { editMode = .active }
                        Button(action: { showSettings = true }) {
                            Image(systemName: "sparkles").symbolRenderingMode(.hierarchical).foregroundStyle(.purple)
                        }
                        Menu {
                            Button(action: { showAddTransaction = true }) { Label(lm.t("记一笔"), systemImage: "square.and.pencil") }
                            Button(action: { showFileImporter = true }) { Label(lm.t("导入表格"), systemImage: "square.and.arrow.down") }
                            Divider()
                            NavigationLink {
                                DataBackupView()
                            } label: {
                                Label(lm.t("Data Backup"), systemImage: "externaldrive")
                            }
                        } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                    }
                }
            }
            // --- Sheet 与 Modifiers 开始 ---
            
            .sheet(isPresented: $showAnalysis) {
                AnalysisView(
                    transactions: monthlyTransactions,
                    title: lm.formatMonthlyReportTitle(year: selectedYear, month: selectedMonth)
                )
            }
            .sheet(isPresented: $showYearAnalysis) {
                AnalysisView(
                    transactions: yearlyTransactions,
                    title: lm.formatYearlyReportTitle(year: selectedYear)
                )
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType.commaSeparatedText]) { res in
                if let url = try? res.get() { importCSV(from: url) }
            }
            .sheet(isPresented: $showAddTransaction) {
                TransactionFormView(itemToEdit: nil, initialText: initialVoiceText) { newItem in
                    context.insert(newItem)
                    refreshSelection(date: newItem.date)
                    initialVoiceText = "" // 清理
                }
            }
            .sheet(item: $editingItem) { item in
                TransactionFormView(itemToEdit: item) { _ in refreshSelection(date: item.date) }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            // 处理“冷启动”：App 刚打开时，如果状态已经是 true，onChange 无法监听到，必须这里手动查一次
            .task {
                // 给一点点延迟，确保视图层级完全准备好
                try? await Task.sleep(for: .seconds(0.5))
                
                if quickActionManager.shouldShowAddTransaction {
                    if let text = quickActionManager.consumePendingText() {
                        self.initialVoiceText = text
                    }
                    self.showAddTransaction = true
                    // 重置状态
                    quickActionManager.shouldShowAddTransaction = false
                }
            }
            .onChange(of: quickActionManager.shouldShowAddTransaction) { _, newValue in
                if newValue {
                    if let text = quickActionManager.consumePendingText() {
                        self.initialVoiceText = text
                    }
                    self.showAddTransaction = true
                    quickActionManager.shouldShowAddTransaction = false
                }
            }
            // --- Modifiers 结束 ---
        }
    }
    
    // MARK: - Helpers
    
    func refreshSelection(date: Date) {
        let y = Calendar.current.component(.year, from: date)
        let m = Calendar.current.component(.month, from: date)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.selectedYear = y; self.selectedMonth = m }
    }
    
    func deleteSelectedItems() {
        let itemsToDelete = transactions.filter { selection.contains($0.id) }
        for item in itemsToDelete { context.delete(item) }
        selection.removeAll()
        editMode = .inactive
    }
    
    func formatMoney(_ amount: Double) -> String {
        let f = NumberFormatter(); f.minimumFractionDigits = 0; f.maximumFractionDigits = 2
        return (amount > 0 ? "+" : "") + (f.string(from: NSNumber(value: amount)) ?? "\(amount)")
    }
    
    func channelColor(_ channel: String) -> Color {
        if channel.contains("微信") { return .green }
        if channel.contains("支付宝") { return .blue }
        return .red
    }
    
    func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let filename = url.lastPathComponent
        var overrideYear: Int?; var overrideMonth: Int?
        
        let pattern = "PersonalBill-([A-Za-z]+)\\.(\\d{4})"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: filename, range: NSRange(filename.startIndex..., in: filename)) {
            
            if let monthRange = Range(match.range(at: 1), in: filename),
               let yearRange = Range(match.range(at: 2), in: filename) {
                
                let monthStr = String(filename[monthRange])
                let yearStr = String(filename[yearRange])
                
                overrideYear = Int(yearStr)
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "MMM"
                
                if let date = formatter.date(from: monthStr) {
                    overrideMonth = Calendar.current.component(.month, from: date)
                }
            }
        }
        if let data = try? String(contentsOf: url, encoding: .utf8) {
            let records = parseCSV(data: data, fixedYear: overrideYear, fixedMonth: overrideMonth)
            for r in records { context.insert(r) }
            if let y = overrideYear, let m = overrideMonth {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.selectedYear = y; self.selectedMonth = m }
            }
        }
    }
    
    func parseCSV(data: String, fixedYear: Int?, fixedMonth: Int?) -> [BillItem] {
        var res: [BillItem] = []
        var rows = data.components(separatedBy: .newlines)
        if !rows.isEmpty { rows.removeFirst() }
        let dateFormats = ["yyyy年MM月dd日 HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy/MM/dd HH:mm", "yyyy-MM-dd", "yyyyMMdd"]
        let formatter = DateFormatter()
        let calendar = Calendar.current
        for row in rows {
            let cols = row.components(separatedBy: ",")
            if cols.count >= 6 {
                let dateStr = cols[0].trimmingCharacters(in: .whitespacesAndNewlines)
                var date: Date?
                for format in dateFormats { formatter.dateFormat = format; if let d = formatter.date(from: dateStr) { date = d; break } }
                if var validDate = date {
                    if let y = fixedYear, let m = fixedMonth {
                        var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: validDate)
                        comps.year = y; comps.month = m
                        if let newDate = calendar.date(from: comps) { validDate = newDate }
                    }
                    let rawAmt = cols[4].replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
                    let amount = Double(rawAmt) ?? 0.0
                    res.append(BillItem(date: validDate, type: cols[1], category: cols[2], channel: cols[3], amount: amount, note: cols[5].replacingOccurrences(of: "\"", with: "")))
                }
            }
        }
        return res
    }
}
