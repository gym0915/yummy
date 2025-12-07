import Foundation

/// 统一管理单例依赖的简易 DI 容器
final class DI {
    static let shared = DI()

    // MARK: - Repositories
    let bigModelRepository: BigModelRepository

    private init() {
        // 默认使用 KeychainProvider
        let apiProvider = KeychainAPIKeyProvider()
        let modelProvider = KeychainModelProvider()

        self.bigModelRepository = BigModelRepositoryImpl(
            apiKeyProvider: apiProvider,
            modelProvider: modelProvider
        )
    }
} 