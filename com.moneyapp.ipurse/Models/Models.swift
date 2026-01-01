import SwiftUI
import SwiftData

// MARK: - 账单模型 (保持不变)
@Model
final class BillItem {
    @Attribute(.unique) var id: UUID
    var date: Date
    var type: String
    var category: String
    var channel: String
    var amount: Double
    var note: String
    
    init(date: Date, type: String, category: String, channel: String, amount: Double, note: String) {
        self.id = UUID()
        self.date = date
        self.type = type
        self.category = category
        self.channel = channel
        self.amount = amount
        self.note = note
    }
    
    @Transient var year: Int { Calendar.current.component(.year, from: date) }
    @Transient var month: Int { Calendar.current.component(.month, from: date) }
    
    func localizedType(lm: LocalizationManager) -> String { return lm.t(type) }
}

// MARK: - 资产模型 (升级版)
@Model
final class AssetItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var amount: Double       // 本金 (参与年化计算)
    var producedIncome: Double // 新增：已产出收益 (不参与年化计算，只是加在总额里)
    var annualizedRate: Double // 年化收益率 (%)
    var note: String
    var updateDate: Date     // 本金更新时间
    
    @Relationship(inverse: \AssetPortfolio.assets) var portfolios: [AssetPortfolio]?
    
    // 初始化增加了 producedIncome
    init(name: String, type: String, amount: Double, producedIncome: Double = 0.0, annualizedRate: Double = 0.0, note: String = "") {
        self.id = UUID()
        self.name = name
        self.type = type
        self.amount = amount
        self.producedIncome = producedIncome
        self.annualizedRate = annualizedRate
        self.note = note
        self.updateDate = Date()
    }
    
    // --- 核心计算逻辑 ---
    
    // 1. 动态利息 (仅基于本金计算)
    @Transient var dynamicInterest: Double {
        if annualizedRate <= 0 { return 0 }
        let daysPassed = Date().timeIntervalSince(updateDate) / (60 * 60 * 24)
        if daysPassed <= 0 { return 0 }
        return amount * (annualizedRate / 100.0) * (daysPassed / 365.0)
    }
    
    // 2. 总收益 = 已产出收益 (历史) + 动态利息 (新增)
    @Transient var totalGain: Double {
        return producedIncome + dynamicInterest
    }
    
    // 3. 当前总价值 = 本金 + 总收益
    @Transient var currentValue: Double {
        return amount + totalGain
    }
    
    // 每日预计收益 (仅基于本金)
    @Transient var dailyIncome: Double {
        if annualizedRate <= 0 { return 0 }
        return amount * (annualizedRate / 100.0) / 365.0
    }
    
    @Transient var color: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        return colors[abs(name.hashValue) % colors.count]
    }
    
    func localizedType(lm: LocalizationManager) -> String { return lm.t(type) }
}

// MARK: - 资产汇总模型 (保持不变)
@Model
final class AssetPortfolio {
    @Attribute(.unique) var id: UUID
    var name: String
    var createDate: Date
    @Relationship var assets: [AssetItem]?
    
    init(name: String, assets: [AssetItem] = []) {
        self.id = UUID()
        self.name = name
        self.assets = assets
        self.createDate = Date()
    }
}
