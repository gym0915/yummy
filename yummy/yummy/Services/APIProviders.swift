import Foundation

// MARK: - Dependency Protocols

/// 提供大模型 API Key 的抽象协议，可替换为 Keychain、远程配置等不同实现
protocol APIKeyProvider {
    func apiKey() throws -> String
}

/// 提供大模型名称(Model) 的抽象协议
protocol ModelProvider {
    func modelName() throws -> String
}

// MARK: - Keychain + .xcconfig 默认实现

/// 共享的错误类型
enum ProviderError: Error, LocalizedError {
    case missingValue(description: String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let description):
            return description
        }
    }
}

/// 默认实现：先查 Keychain，不存在则从 Info.plist/.xcconfig 获取，并回写 Keychain
final class KeychainAPIKeyProvider: APIKeyProvider {
    private let keyIdentifier = "com.yummy.yummy.bigModelAPIKey"
    private let infoKey = "BIGMODEL_API_KEY_VALUE"

    func apiKey() throws -> String {
        if let value = try KeychainService.retrieve(key: keyIdentifier) {
            return value
        }
        guard let value = Bundle.main.infoDictionary?[infoKey] as? String else {
            throw ProviderError.missingValue(description: "未在 Keychain 或 Info.plist 中找到 \(infoKey)")
        }
        try KeychainService.save(key: keyIdentifier, value: value)
        return value
    }
}

final class KeychainModelProvider: ModelProvider {
    private let keyIdentifier = "com.yummy.yummy.modelName"
    private let infoKey = "MODEL_NAME"

    func modelName() throws -> String {
        if let value = try KeychainService.retrieve(key: keyIdentifier) {
            return value
        }
        guard let value = Bundle.main.infoDictionary?[infoKey] as? String else {
            throw ProviderError.missingValue(description: "未在 Keychain 或 Info.plist 中找到 \(infoKey)")
        }
        try KeychainService.save(key: keyIdentifier, value: value)
        return value
    }
} 