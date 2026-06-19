import Foundation
import Security

final class APIKeyStore {
    enum Key: String, CaseIterable {
        case deepSeek = "deepseek_key"
        case openAI = "openai_key"
        case gemini = "gemini_key"
    }

    static let shared = APIKeyStore()

    private let service = Bundle.main.bundleIdentifier ?? "com.moneyapp.ipurse"

    private init() {}

    func value(for key: Key) -> String {
        if let storedValue = readFromKeychain(key) {
            return storedValue
        }

        guard let legacyValue = UserDefaults.standard.string(forKey: key.rawValue), !legacyValue.isEmpty else {
            return ""
        }

        set(legacyValue, for: key)
        return legacyValue
    }

    @discardableResult
    func set(_ value: String, for key: Key) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = baseQuery(for: key)

        guard !trimmedValue.isEmpty else {
            SecItemDelete(query as CFDictionary)
            UserDefaults.standard.removeObject(forKey: key.rawValue)
            return true
        }

        let data = Data(trimmedValue.utf8)
        let updateAttributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
        let status: OSStatus

        if updateStatus == errSecItemNotFound {
            var attributes = query
            attributes[kSecValueData as String] = data
            attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(attributes as CFDictionary, nil)
        } else {
            status = updateStatus
        }

        guard status == errSecSuccess else {
            return false
        }

        UserDefaults.standard.removeObject(forKey: key.rawValue)
        return true
    }

    private func readFromKeychain(_ key: Key) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        guard
            SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
            let data = result as? Data
        else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func baseQuery(for key: Key) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
    }
}
