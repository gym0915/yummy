import Foundation
import Security

struct KeychainService {

    enum KeychainError: Error {
        case duplicateItem
        case unknown
        case noItem
        case invalidData
    }

    /// 将数据保存到 Keychain
    /// - Parameters:
    ///   - key: 用于标识数据的唯一键
    ///   - value: 要保存的数据（通常是 API Key 的字符串形式）
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // 首先尝试更新，如果不存在则添加
        var status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if status == errSecItemNotFound {
            status = SecItemAdd(query as CFDictionary, nil)
        }

        guard status == errSecSuccess else {
            if status == errSecDuplicateItem {
                throw KeychainError.duplicateItem
            } else {
                throw KeychainError.unknown
            }
        }
    }

    /// 从 Keychain 读取数据
    /// - Parameter key: 用于标识数据的唯一键
    /// - Returns: 读取到的数据字符串
    static func retrieve(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil // 未找到
            }
            throw KeychainError.unknown
        }

        guard let data = item as? Data else {
            throw KeychainError.invalidData
        }

        return String(data: data, encoding: .utf8)
    }

    /// 从 Keychain 删除数据
    /// - Parameter key: 用于标识数据的唯一键
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown
        }
    }
} 