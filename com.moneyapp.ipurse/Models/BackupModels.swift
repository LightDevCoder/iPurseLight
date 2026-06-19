import Foundation

struct BackupContainer: Codable {
    let version: String
    let exportedAt: Date
    let assets: [AssetDTO]
    let bills: [BillDTO]
    let portfolios: [PortfolioDTO]?
}

struct AssetDTO: Codable {
    let id: UUID?
    let name: String
    let type: String
    let amount: Double
    let producedIncome: Double
    let annualizedRate: Double
    let note: String
    let updateDate: Date

    init(from item: AssetItem) {
        id = item.id
        name = item.name
        type = item.type
        amount = item.amount
        producedIncome = item.producedIncome
        annualizedRate = item.annualizedRate
        note = item.note
        updateDate = item.updateDate
    }
}

struct BillDTO: Codable {
    let id: UUID?
    let date: Date
    let type: String
    let category: String
    let channel: String
    let amount: Double
    let note: String

    init(from item: BillItem) {
        id = item.id
        date = item.date
        type = item.type
        category = item.category
        channel = item.channel
        amount = item.amount
        note = item.note
    }
}

struct PortfolioDTO: Codable {
    let id: UUID
    let name: String
    let createDate: Date
    let assetIDs: [UUID]

    init(from portfolio: AssetPortfolio) {
        id = portfolio.id
        name = portfolio.name
        createDate = portfolio.createDate
        assetIDs = portfolio.assets?.map(\.id) ?? []
    }
}
