import Foundation
import SwiftData

@MainActor
final class BackupService {
    static let shared = BackupService()

    private init() {}

    func createBackupFile(context: ModelContext) throws -> URL {
        let assets = try context.fetch(FetchDescriptor<AssetItem>())
        let bills = try context.fetch(FetchDescriptor<BillItem>())
        let portfolios = try context.fetch(FetchDescriptor<AssetPortfolio>())

        let backup = BackupContainer(
            version: "2.0",
            exportedAt: Date(),
            assets: assets.map { AssetDTO(from: $0) },
            bills: bills.map { BillDTO(from: $0) },
            portfolios: portfolios.map { PortfolioDTO(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)

        let fileName = "iPurseLight_Backup_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func restoreBackup(
        from url: URL,
        context: ModelContext,
        clearExisting: Bool = false
    ) throws {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupContainer.self, from: data)

        if clearExisting {
            try context.delete(model: AssetPortfolio.self)
            try context.delete(model: AssetItem.self)
            try context.delete(model: BillItem.self)
        }

        let existingAssets = try context.fetch(FetchDescriptor<AssetItem>())
        let existingBills = try context.fetch(FetchDescriptor<BillItem>())
        let existingPortfolios = try context.fetch(FetchDescriptor<AssetPortfolio>())

        var assetsByID = Dictionary(uniqueKeysWithValues: existingAssets.map { ($0.id, $0) })
        var billIDs = Set(existingBills.map(\.id))
        var portfolioIDs = Set(existingPortfolios.map(\.id))

        for dto in backup.assets {
            if let id = dto.id, assetsByID[id] != nil {
                continue
            }

            let item = AssetItem(
                name: dto.name,
                type: dto.type,
                amount: dto.amount,
                producedIncome: dto.producedIncome,
                annualizedRate: dto.annualizedRate,
                note: dto.note
            )
            if let id = dto.id {
                item.id = id
                assetsByID[id] = item
            }
            item.updateDate = dto.updateDate
            context.insert(item)
        }

        for dto in backup.bills {
            if let id = dto.id, billIDs.contains(id) {
                continue
            }

            let item = BillItem(
                date: dto.date,
                type: dto.type,
                category: dto.category,
                channel: dto.channel,
                amount: dto.amount,
                note: dto.note
            )
            if let id = dto.id {
                item.id = id
                billIDs.insert(id)
            }
            context.insert(item)
        }

        for dto in backup.portfolios ?? [] where !portfolioIDs.contains(dto.id) {
            let assets = dto.assetIDs.compactMap { assetsByID[$0] }
            let portfolio = AssetPortfolio(name: dto.name, assets: assets)
            portfolio.id = dto.id
            portfolio.createDate = dto.createDate
            context.insert(portfolio)
            portfolioIDs.insert(dto.id)
        }

        try context.save()
    }
}
