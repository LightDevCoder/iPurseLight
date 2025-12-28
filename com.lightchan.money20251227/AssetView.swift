import SwiftUI
import SwiftData
import Charts

struct AssetView: View {
    @Environment(\.modelContext) var context
    @EnvironmentObject var lm: LocalizationManager
    @Query var allAssets: [AssetItem]
    @Query var portfolios: [AssetPortfolio]
    
    @State private var showAssetForm = false
    @State private var showCreatePortfolio = false
    @State private var showAIAdvice = false
    @State private var selectedPortfolio: AssetPortfolio? = nil
    @State private var editingAsset: AssetItem?
    
    var currentAssets: [AssetItem] {
        if let portfolio = selectedPortfolio {
            return portfolio.assets ?? []
        } else {
            return allAssets
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 顶部卡片
                    TabView(selection: $selectedPortfolio) {
                        AssetSummaryCard(title: lm.t("总资产 (小金库)"), assets: allAssets)
                            .tag(Optional<AssetPortfolio>.none)
                            .padding(.horizontal)
                        
                        ForEach(portfolios) { portfolio in
                            AssetSummaryCard(title: portfolio.name, assets: portfolio.assets ?? [])
                                .tag(Optional(portfolio))
                                .padding(.horizontal)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 380)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // 2. AI 建议
                    Button(action: { showAIAdvice = true }) {
                        HStack {
                            Image(systemName: "sparkles").foregroundStyle(.purple)
                            Text(lm.t("生成 AI 理财建议")).font(.subheadline).bold()
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // 3. 资产列表
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(lm.t("资产明细")).font(.headline)
                            Spacer()
                            if let portfolio = selectedPortfolio {
                                Button(lm.t("删除该汇总"), role: .destructive) {
                                    context.delete(portfolio)
                                    selectedPortfolio = nil
                                }.font(.caption).foregroundStyle(.red)
                            }
                        }
                        .padding(.horizontal)
                        
                        if currentAssets.isEmpty {
                            Text(lm.t("暂无资产")).font(.caption).foregroundStyle(.gray).padding(.leading)
                        } else {
                            ForEach(currentAssets) { asset in
                                Button(action: { editingAsset = asset }) {
                                    AssetRow(asset: asset)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(lm.t("我的资产"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { editingAsset = nil; showAssetForm = true }) {
                            Label(lm.t("新建资产 (如:招商银行)"), systemImage: "plus.square")
                        }
                        Button(action: { showCreatePortfolio = true }) {
                            // ✨ 修改了这里：
                            Label(lm.t("新建汇总 (如: 汇总渠道)"), systemImage: "folder.badge.plus")
                        }
                    } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                }
            }
            .sheet(isPresented: $showAssetForm) { AssetFormSheet(assetToEdit: nil) }
            .sheet(item: $editingAsset) { asset in AssetFormSheet(assetToEdit: asset) }
            .sheet(isPresented: $showCreatePortfolio) { CreatePortfolioSheet(allAssets: allAssets) }
            .sheet(isPresented: $showAIAdvice) { AssetAIAnalysisView(assets: currentAssets) }
        }
    }
}
// MARK: - 子视图组件

struct AssetSummaryCard: View {
    @EnvironmentObject var lm: LocalizationManager
    let title: String
    let assets: [AssetItem]
    var total: Double { assets.reduce(0) { $0 + $1.currentValue } }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title).font(.subheadline).foregroundStyle(.gray)
                Text("¥\(String(format: "%.2f", total))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }
            .padding(.top, 20)
            
            if !assets.isEmpty {
                Chart(assets, id: \.id) { asset in
                    SectorMark(
                        angle: .value("金额", asset.currentValue),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .cornerRadius(5)
                    .foregroundStyle(asset.color)
                }
                .frame(height: 180)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                    ForEach(assets) { asset in
                        HStack(spacing: 4) {
                            Circle().fill(asset.color).frame(width: 8, height: 8)
                            Text(asset.name).font(.caption2).lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView(lm.t("无数据"), systemImage: "chart.pie")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// 仅修改 AssetRow 结构体，AssetView 的其他部分保持不变

struct AssetRow: View {
    @EnvironmentObject var lm: LocalizationManager
    let asset: AssetItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name).font(.body).bold()
                HStack(spacing: 6) {
                    Text(asset.localizedType(lm: lm))
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    if asset.annualizedRate > 0 {
                        Text("\(lm.t("年化")) \(String(format: "%.2f", asset.annualizedRate))%")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        // ✨✨✨ 修复部分：每日收益显示 ✨✨✨
                        Text("+¥\(String(format: "%.2f", asset.dailyIncome))/\(lm.t("天"))")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(1)              // 1. 强制不换行
                            .minimumScaleFactor(0.8)   // 2. 空间不够时允许缩小到 80%
                            .layoutPriority(1)         // 3. 提高布局优先级，防止被压缩过头
                    }
                }
                .foregroundStyle(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("¥\(String(format: "%.2f", asset.currentValue))")
                    .font(.headline)
                
                if asset.totalGain > 0 {
                    Text("(\(lm.t("含收益")) ¥\(String(format: "%.2f", asset.totalGain)))")
                        .font(.caption2).foregroundStyle(.red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct AssetFormSheet: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lm: LocalizationManager
    
    var assetToEdit: AssetItem?
    
    @State private var name = ""
    @State private var type = "银行存款"
    // 可选类型，默认 nil，解决 "0.00" 输入问题
    @State private var amount: Double?
    @State private var producedIncome: Double? // 新增：已产出收益
    @State private var annualizedRate: Double?
    
    let commonTypes = ["银行存款", "现金", "公积金", "理财产品", "外币", "其他"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(lm.t("基础信息"))) {
                    TextField(lm.t("名称 (如: 招商银行)"), text: $name)
                    
                    HStack {
                        Text(lm.t("本金"))
                        // 修正：去掉 .precision，解决输入小数位问题
                        TextField("0", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker(lm.t("类型"), selection: $type) {
                        ForEach(commonTypes, id: \.self) { typeKey in
                            Text(lm.t(typeKey)).tag(typeKey)
                        }
                    }
                }
                
                Section(header: Text(lm.t("收益设置 (可选)"))) {
                    // 新增：已产出收益
                    HStack {
                        Text("已产出收益") // 可放入翻译字典 "Produced Income"
                        TextField("0", value: $producedIncome, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text(lm.t("年化收益率 (%)"))
                        TextField("0", value: $annualizedRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Text(lm.t("设置后，资产金额将根据时间自动每日增加。"))
                        .font(.caption).foregroundStyle(.gray)
                }
            }
            .navigationTitle(assetToEdit == nil ? lm.t("新建资产") : lm.t("编辑资产"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let asset = assetToEdit {
                        Button(lm.t("删除"), role: .destructive) {
                            context.delete(asset)
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t("保存")) {
                        save()
                    }
                    .disabled(name.isEmpty || amount == nil)
                }
            }
            .onAppear {
                if let asset = assetToEdit {
                    name = asset.name
                    amount = asset.amount
                    type = asset.type
                    // 如果值为0，保持 nil 以显示 placeholder，或者显示 0，看喜好
                    annualizedRate = asset.annualizedRate == 0 ? nil : asset.annualizedRate
                    producedIncome = asset.producedIncome == 0 ? nil : asset.producedIncome
                }
            }
        }
    }
    
    func save() {
        let finalAmount = amount ?? 0.0
        let finalRate = annualizedRate ?? 0.0
        let finalProduced = producedIncome ?? 0.0
        
        if let asset = assetToEdit {
            asset.name = name
            asset.amount = finalAmount
            asset.type = type
            asset.annualizedRate = finalRate
            asset.producedIncome = finalProduced
            asset.updateDate = Date()
        } else {
            let newAsset = AssetItem(name: name, type: type, amount: finalAmount, producedIncome: finalProduced, annualizedRate: finalRate)
            context.insert(newAsset)
        }
        dismiss()
    }
}

// CreatePortfolioSheet 和 AssetAIAnalysisView 保持不变...
// (为保持代码完整性，请确保保留这两个结构体，或者如果需要我再次附上请告知)
struct CreatePortfolioSheet: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lm: LocalizationManager
    var allAssets: [AssetItem]
    @State private var name = ""
    @State private var selectedAssetIDs: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section { TextField(lm.t("汇总名称"), text: $name) }
                Section(header: Text(lm.t("勾选包含的资产"))) {
                    ForEach(allAssets) { asset in
                        HStack {
                            Text(asset.name)
                            Spacer()
                            if selectedAssetIDs.contains(asset.id) { Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue) }
                            else { Image(systemName: "circle").foregroundStyle(.gray) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedAssetIDs.contains(asset.id) { selectedAssetIDs.remove(asset.id) }
                            else { selectedAssetIDs.insert(asset.id) }
                        }
                    }
                }
            }
            .navigationTitle(lm.t("新建汇总"))
            .toolbar {
                Button(lm.t("创建")) {
                    let selectedAssets = allAssets.filter { selectedAssetIDs.contains($0.id) }
                    let portfolio = AssetPortfolio(name: name, assets: selectedAssets)
                    context.insert(portfolio)
                    dismiss()
                }.disabled(name.isEmpty || selectedAssetIDs.isEmpty)
            }
        }
    }
}

struct AssetAIAnalysisView: View {
    @EnvironmentObject var lm: LocalizationManager
    var assets: [AssetItem]
    @State private var analysisText: String = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        HStack { Spacer(); ProgressView(lm.t("AI 正在分析...")); Spacer() }.padding(.top, 50)
                    } else {
                        // 显示结果
                        HStack {
                            Image(systemName: "sparkles").foregroundStyle(.purple).font(.title)
                            Text(lm.t("AI 理财建议")).font(.title2).bold()
                        }
                        .padding(.bottom, 10)
                        Text(analysisText)
                            .lineSpacing(6)
                            .padding()
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(12)
                    }
                }.padding()
            }
            .navigationTitle(lm.t("AI 理财建议"))
            .onAppear { startAnalysis() }
        }
    }
    
    func startAnalysis() {
        let summary = assets.map {
            "\($0.name): ¥\(String(format: "%.2f", $0.currentValue)) (\($0.localizedType(lm: lm)), \(lm.t("年化")) \(String(format: "%.2f", $0.annualizedRate))%)"
        }.joined(separator: "\n")
        
        Task {
            do {
                let result = try await AIService.shared.analyzeFinancialData(
                    summary: summary,
                    provider: UserDefaults.standard.string(forKey: "selected_ai_provider") ?? "DeepSeek",
                    language: lm.language
                )
                await MainActor.run { self.analysisText = result; self.isLoading = false }
            } catch {
                await MainActor.run { self.analysisText = lm.t("分析失败"); self.isLoading = false }
            }
        }
    }
}
