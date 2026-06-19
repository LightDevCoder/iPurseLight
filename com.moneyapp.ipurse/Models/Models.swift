import SwiftUI
import SwiftData

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

@Model
final class AssetItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String
    var amount: Double
    var producedIncome: Double
    var annualizedRate: Double
    var note: String
    var updateDate: Date
    
    @Relationship(inverse: \AssetPortfolio.assets) var portfolios: [AssetPortfolio]?
    
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
    
    @Transient var dynamicInterest: Double {
        if annualizedRate <= 0 { return 0 }
        let daysPassed = Date().timeIntervalSince(updateDate) / (60 * 60 * 24)
        if daysPassed <= 0 { return 0 }
        return amount * (annualizedRate / 100.0) * (daysPassed / 365.0)
    }
    
    @Transient var totalGain: Double {
        return producedIncome + dynamicInterest
    }

    @Transient var currentValue: Double {
        return amount + totalGain
    }

    @Transient var dailyIncome: Double {
        if annualizedRate <= 0 { return 0 }
        return amount * (annualizedRate / 100.0) / 365.0
    }

    @Transient var color: Color {
        let palette: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .indigo]
        let stableHash = name.unicodeScalars.reduce(0) { partialResult, scalar in
            (partialResult &* 31 &+ Int(scalar.value)) % palette.count
        }
        return palette[stableHash]
    }
    
    func localizedType(lm: LocalizationManager) -> String { return lm.t(type) }
}

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
