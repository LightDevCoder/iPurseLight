import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.dismiss) var dismiss
    // 1. 引入翻译官
    @EnvironmentObject var lm: LocalizationManager
    
    var itemToEdit: BillItem?
    var onSave: (BillItem) -> Void
    
    @State private var date = Date()
    // 默认使用中文 key
    @State private var type = "支出"
    @State private var category = ""
    @State private var channel = "微信"
    @State private var amount = 0.0
    @State private var note = ""
    
    @State private var aiInput = ""
    @State private var isAnalyzing = false
    @AppStorage("selected_ai_provider") private var selectedProvider = "DeepSeek"
    
    let channels = ["微信", "支付宝", "银行卡", "现金", "其他"]
    let types = ["支出", "收入"]
    
    var body: some View {
        NavigationStack {
            Form {
                if itemToEdit == nil {
                    Section {
                        HStack {
                            TextField(lm.t("例如：刚才打车花了30元"), text: $aiInput)
                            Button(action: analyzeText) {
                                if isAnalyzing {
                                    ProgressView()
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .foregroundStyle(.purple)
                                        .font(.title3)
                                }
                            }
                            .disabled(aiInput.isEmpty || isAnalyzing)
                        }
                    } footer: {
                        // 根据不同提供商显示不同的翻译
                        let providerText = selectedProvider == "DeepSeek" ? lm.t("使用 DeepSeek 自动识别") :
                                           selectedProvider == "OpenAI" ? lm.t("使用 OpenAI 自动识别") :
                                           lm.t("使用 Gemini 自动识别")
                        Text(providerText).font(.caption)
                    }
                }
                
                Section(header: Text(lm.t("基本信息"))) {
                    DatePicker(lm.t("日期"), selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker(lm.t("类型"), selection: $type) {
                        ForEach(types, id: \.self) { typeKey in
                            // 显示时翻译
                            Text(lm.t(typeKey)).tag(typeKey)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    HStack {
                        Text(lm.t("金额"))
                        TextField("0.00", value: $amount, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title3)
                            .bold()
                            .foregroundColor(type == "支出" ? .primary : .green)
                    }
                }
                
                Section(header: Text(lm.t("分类与渠道"))) {
                    HStack {
                        Text(lm.t("分类"))
                        TextField(lm.t("例如：餐饮、交通"), text: $category).multilineTextAlignment(.trailing)
                    }
                    Picker(lm.t("渠道"), selection: $channel) {
                        ForEach(channels, id: \.self) { Text($0) }
                    }
                }
                
                Section(header: Text(lm.t("备注"))) {
                    TextField(lm.t("选填"), text: $note)
                }
            }
            .navigationTitle(itemToEdit == nil ? lm.t("记一笔") : lm.t("编辑记录"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t("取消")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t("保存")) { save() }
                    .disabled(category.isEmpty || amount == 0)
                }
            }
            .onAppear {
                if let item = itemToEdit {
                    date = item.date
                    type = item.type
                    amount = abs(item.amount)
                    category = item.category
                    channel = item.channel
                    note = item.note
                }
            }
        }
    }
    
    func analyzeText() {
        guard !aiInput.isEmpty else { return }
        isAnalyzing = true
        Task {
            do {
                let result = try await AIService.shared.parseText(aiInput, provider: selectedProvider)
                await MainActor.run {
                    self.amount = result.amount
                    self.category = result.category
                    self.type = result.type
                    self.note = result.note
                    if channels.contains(result.channel) { self.channel = result.channel }
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.note = "\(lm.t("识别失败"))：\(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    func save() {
        let finalAmount = (type == "支出") ? -abs(amount) : abs(amount)
        if let item = itemToEdit {
            item.date = date
            item.type = type
            item.amount = finalAmount
            item.category = category
            item.channel = channel
            item.note = note
            onSave(item)
        } else {
            let newItem = BillItem(date: date, type: type, category: category, channel: channel, amount: finalAmount, note: note)
            onSave(newItem)
        }
        dismiss()
    }
}
