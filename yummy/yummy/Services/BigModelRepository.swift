import Foundation

// MARK: - 仓库协议
/// 负责与大模型交互，返回结构化 Formula
protocol BigModelRepository {
    /// 根据用户 prompt 生成菜谱
    func generateFormula(from prompt: String) async throws -> Formula
}

// MARK: - 默认实现
final class BigModelRepositoryImpl: BigModelRepository {
    private let apiKeyProvider: APIKeyProvider
    private let modelProvider: ModelProvider
    private let apiService: BigModelAPIService

    init(apiKeyProvider: APIKeyProvider,
         modelProvider: ModelProvider,
         apiService: BigModelAPIService = BigModelAPIService()) {
        self.apiKeyProvider = apiKeyProvider
        self.modelProvider = modelProvider
        self.apiService = apiService
    }

    func generateFormula(from prompt: String) async throws -> Formula {
        let apiKey = try apiKeyProvider.apiKey()
        let modelName = try modelProvider.modelName()
        
        let fullPrompt = prompt + PromptConstants.userPrompt
        AppLog("完整 prompt: \(fullPrompt)", level: .debug, category: .service)

        return try await apiService.callAPI(apiKey: apiKey, modelName: modelName, prompt: fullPrompt)
    }
}
