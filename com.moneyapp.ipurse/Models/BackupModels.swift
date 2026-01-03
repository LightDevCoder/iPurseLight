import Foundation

// 📦 备份容器 (保持不变)
struct BackupContainer: Codable {
    let version: String
    let exportedAt: Date
    let assets: [AssetDTO]
    let bills: [BillDTO]
}

// 💰 资产 DTO (保持之前的 AssetDTO 不变)
struct AssetDTO: Codable {
    let name: String
    let type: String
    let amount: Double
    let producedIncome: Double
    let annualizedRate: Double
    let note: String
    let updateDate: Date
    
    init(from item: AssetItem) {
        self.name = item.name
        self.type = item.type
        self.amount = item.amount
        self.producedIncome = item.producedIncome
        self.annualizedRate = item.annualizedRate
        self.note = item.note
        self.updateDate = item.updateDate
    }
}

// 🧾 账单 DTO (已根据你的 BillItem 代码完全修正)
struct BillDTO: Codable {
    let date: Date
    let type: String    // ✨ 修正：原来是 Int，现在改为 String
    let category: String
    let channel: String // ✨ 新增：必须包含 channel
    let amount: Double
    let note: String
    
    init(from item: BillItem) {
        self.date = item.date
        self.type = item.type
        self.category = item.category
        self.channel = item.channel
        self.amount = item.amount
        self.note = item.note
    }
}
