import SwiftUI
import SwiftData

@MainActor
class BackupService {
    static let shared = BackupService()
    
    private init() {}
    
    // 📤 导出 (保持不变)
    func createBackupFile(context: ModelContext) throws -> URL {
        let assetDescriptor = FetchDescriptor<AssetItem>()
        let billDescriptor = FetchDescriptor<BillItem>()
        
        let assets = try context.fetch(assetDescriptor)
        let bills = try context.fetch(billDescriptor)
        
        let backup = BackupContainer(
            version: "1.0",
            exportedAt: Date(),
            assets: assets.map { AssetDTO(from: $0) },
            bills: bills.map { BillDTO(from: $0) }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backup)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "iPurseLight_Backup_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // 📥 恢复 (核心修正部分)
    func restoreBackup(from url: URL, context: ModelContext, clearExisting: Bool = false) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupContainer.self, from: data)
        
        if clearExisting {
            try context.delete(model: AssetItem.self)
            try context.delete(model: BillItem.self)
        }
        
        // 恢复资产
        for dto in backup.assets {
            let newItem = AssetItem(
                name: dto.name,
                type: dto.type,
                amount: dto.amount,
                producedIncome: dto.producedIncome,
                annualizedRate: dto.annualizedRate,
                note: dto.note
            )
            newItem.updateDate = dto.updateDate
            context.insert(newItem)
        }
        
        // 恢复账单 (⚠️ 这里已根据你的 init 修正参数顺序)
        for dto in backup.bills {
            let newItem = BillItem(
                date: dto.date,
                type: dto.type,       // String
                category: dto.category,
                channel: dto.channel, // String
                amount: dto.amount,
                note: dto.note
            )
            context.insert(newItem)
        }
        
        try context.save()
    }
}
