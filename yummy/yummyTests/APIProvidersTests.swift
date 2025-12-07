import XCTest
import Foundation
@testable import yummy

/// APIProviders 测试类
/// 测试 APIKeyProvider 和 ModelProvider 的功能，包括 Keychain 存储和 Info.plist 回退机制
final class APIProvidersTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var apiKeyProvider: KeychainAPIKeyProvider!
    private var modelProvider: KeychainModelProvider!
    
    // 测试用的标识符和值
    private let testAPIKeyIdentifier = "com.yummy.yummy.bigModelAPIKey.test"
    private let testModelIdentifier = "com.yummy.yummy.modelName.test"
    private let testAPIKey = "test_api_key_value_12345"
    private let testModelName = "test_model_gpt_4"
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        AppLog("=== APIProvidersTests setUp 开始 ===", level: .debug, category: .network)
        
        // 清理测试前的 Keychain 数据
        cleanupTestData()
        
        // 创建测试实例
        apiKeyProvider = KeychainAPIKeyProvider()
        modelProvider = KeychainModelProvider()
        
        AppLog("APIProvidersTests setUp 完成", level: .debug, category: .network)
    }
    
    override func tearDown() {
        AppLog("=== APIProvidersTests tearDown 开始 ===", level: .debug, category: .network)
        
        // 清理测试数据
        cleanupTestData()
        
        apiKeyProvider = nil
        modelProvider = nil
        
        AppLog("APIProvidersTests tearDown 完成", level: .debug, category: .network)
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// 清理测试数据
    private func cleanupTestData() {
        // 清理 Keychain 中的测试数据
        try? KeychainService.delete(key: "com.yummy.yummy.bigModelAPIKey")
        try? KeychainService.delete(key: "com.yummy.yummy.modelName")
        try? KeychainService.delete(key: testAPIKeyIdentifier)
        try? KeychainService.delete(key: testModelIdentifier)
        
        AppLog("测试数据清理完成", level: .debug, category: .network)
    }
    
    // MARK: - APIKeyProvider Tests
    
    /// 测试 APIKeyProvider 基本功能
    func testAPIKeyProvider_基本功能() {
        AppLog("开始测试 APIKeyProvider 基本功能", level: .debug, category: .network)
        
        XCTAssertNotNil(apiKeyProvider, "APIKeyProvider 应该被正确初始化")
        
        // 测试 API Key 获取
        do {
            let apiKey = try apiKeyProvider.apiKey()
            XCTAssertFalse(apiKey.isEmpty, "API Key 不应该为空")
            AppLog("成功获取 API Key: \(apiKey)", level: .debug, category: .network)
        } catch {
            AppLog("获取 API Key 失败: \(error)", level: .error, category: .network)
            // 如果没有配置 API Key，这是预期的行为
            XCTAssertTrue(error is ProviderError, "应该抛出 ProviderError")
        }
    }
    
    /// 测试 APIKeyProvider Keychain 存储和读取
    func testAPIKeyProvider_Keychain存储和读取() throws {
        AppLog("开始测试 APIKeyProvider Keychain 存储和读取", level: .debug, category: .network)
        
        let keyIdentifier = "com.yummy.yummy.bigModelAPIKey"
        
        // 1. 先存储一个测试 API Key
        try KeychainService.save(key: keyIdentifier, value: testAPIKey)
        
        // 2. 通过 Provider 获取
        let retrievedKey = try apiKeyProvider.apiKey()
        
        // 3. 验证获取的值
        XCTAssertEqual(retrievedKey, testAPIKey, "从 Keychain 获取的 API Key 应该与存储的值相同")
        
        AppLog("APIKeyProvider Keychain 存储和读取测试完成", level: .debug, category: .network)
    }
    
    /// 测试 APIKeyProvider Info.plist 回退机制
    func testAPIKeyProvider_InfoPlist回退机制() {
        AppLog("开始测试 APIKeyProvider Info.plist 回退机制", level: .debug, category: .network)
        
        // 确保 Keychain 中没有数据，触发 Info.plist 回退
        try? KeychainService.delete(key: "com.yummy.yummy.bigModelAPIKey")
        
        do {
            let apiKey = try apiKeyProvider.apiKey()
            XCTAssertFalse(apiKey.isEmpty, "从 Info.plist 获取的 API Key 不应该为空")
            AppLog("成功从 Info.plist 获取 API Key", level: .debug, category: .network)
            
            // 验证是否自动保存到 Keychain
            let cachedKey = try KeychainService.retrieve(key: "com.yummy.yummy.bigModelAPIKey")
            XCTAssertEqual(cachedKey, apiKey, "API Key 应该被自动缓存到 Keychain")
            
        } catch ProviderError.missingValue {
            AppLog("Info.plist 中未配置 BIGMODEL_API_KEY_VALUE，这是预期的测试行为", level: .warning, category: .network)
            // 这是预期的行为，如果没有配置则会抛出此错误
        } catch {
            XCTFail("不应该抛出其他类型的错误: \(error)")
        }
    }
    
    /// 测试 APIKeyProvider 错误处理
    func testAPIKeyProvider_错误处理() {
        AppLog("开始测试 APIKeyProvider 错误处理", level: .debug, category: .network)
        
        // 清除 Keychain 数据
        try? KeychainService.delete(key: "com.yummy.yummy.bigModelAPIKey")
        
        // 如果 Info.plist 中也没有配置，应该抛出错误
        do {
            _ = try apiKeyProvider.apiKey()
            // 如果成功获取到，说明 Info.plist 中有配置，这也是正常的
            AppLog("从 Info.plist 成功获取 API Key", level: .debug, category: .network)
        } catch let error as ProviderError {
            // 验证错误类型和消息
            XCTAssertEqual(error.errorDescription?.contains("未在 Keychain 或 Info.plist 中找到"), true, "错误消息应该包含正确的描述")
            AppLog("正确处理了缺失 API Key 的错误情况", level: .debug, category: .network)
        } catch {
            XCTFail("应该抛出 ProviderError 类型的错误，实际抛出: \(error)")
        }
    }
    
    // MARK: - ModelProvider Tests
    
    /// 测试 ModelProvider 基本功能
    func testModelProvider_基本功能() {
        AppLog("开始测试 ModelProvider 基本功能", level: .debug, category: .network)
        
        XCTAssertNotNil(modelProvider, "ModelProvider 应该被正确初始化")
        
        // 测试 Model Name 获取
        do {
            let modelName = try modelProvider.modelName()
            XCTAssertFalse(modelName.isEmpty, "Model Name 不应该为空")
            AppLog("成功获取 Model Name: \(modelName)", level: .debug, category: .network)
        } catch {
            AppLog("获取 Model Name 失败: \(error)", level: .error, category: .network)
            // 如果没有配置 Model Name，这是预期的行为
            XCTAssertTrue(error is ProviderError, "应该抛出 ProviderError")
        }
    }
    
    /// 测试 ModelProvider Keychain 存储和读取
    func testModelProvider_Keychain存储和读取() throws {
        AppLog("开始测试 ModelProvider Keychain 存储和读取", level: .debug, category: .network)
        
        let keyIdentifier = "com.yummy.yummy.modelName"
        
        // 1. 先存储一个测试 Model Name
        try KeychainService.save(key: keyIdentifier, value: testModelName)
        
        // 2. 通过 Provider 获取
        let retrievedModel = try modelProvider.modelName()
        
        // 3. 验证获取的值
        XCTAssertEqual(retrievedModel, testModelName, "从 Keychain 获取的 Model Name 应该与存储的值相同")
        
        AppLog("ModelProvider Keychain 存储和读取测试完成", level: .debug, category: .network)
    }
    
    /// 测试 ModelProvider Info.plist 回退机制
    func testModelProvider_InfoPlist回退机制() {
        AppLog("开始测试 ModelProvider Info.plist 回退机制", level: .debug, category: .network)
        
        // 确保 Keychain 中没有数据，触发 Info.plist 回退
        try? KeychainService.delete(key: "com.yummy.yummy.modelName")
        
        do {
            let modelName = try modelProvider.modelName()
            XCTAssertFalse(modelName.isEmpty, "从 Info.plist 获取的 Model Name 不应该为空")
            AppLog("成功从 Info.plist 获取 Model Name", level: .debug, category: .network)
            
            // 验证是否自动保存到 Keychain
            let cachedModel = try KeychainService.retrieve(key: "com.yummy.yummy.modelName")
            XCTAssertEqual(cachedModel, modelName, "Model Name 应该被自动缓存到 Keychain")
            
        } catch ProviderError.missingValue {
            AppLog("Info.plist 中未配置 MODEL_NAME，这是预期的测试行为", level: .warning, category: .network)
            // 这是预期的行为，如果没有配置则会抛出此错误
        } catch {
            XCTFail("不应该抛出其他类型的错误: \(error)")
        }
    }
    
    /// 测试 ModelProvider 错误处理
    func testModelProvider_错误处理() {
        AppLog("开始测试 ModelProvider 错误处理", level: .debug, category: .network)
        
        // 清除 Keychain 数据
        try? KeychainService.delete(key: "com.yummy.yummy.modelName")
        
        // 如果 Info.plist 中也没有配置，应该抛出错误
        do {
            _ = try modelProvider.modelName()
            // 如果成功获取到，说明 Info.plist 中有配置，这也是正常的
            AppLog("从 Info.plist 成功获取 Model Name", level: .debug, category: .network)
        } catch let error as ProviderError {
            // 验证错误类型和消息
            XCTAssertEqual(error.errorDescription?.contains("未在 Keychain 或 Info.plist 中找到"), true, "错误消息应该包含正确的描述")
            AppLog("正确处理了缺失 Model Name 的错误情况", level: .debug, category: .network)
        } catch {
            XCTFail("应该抛出 ProviderError 类型的错误，实际抛出: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    /// 测试 Provider 集成场景
    func testProviders_集成场景() throws {
        AppLog("开始测试 Providers 集成场景", level: .debug, category: .network)
        
        // 1. 存储测试数据
        try KeychainService.save(key: "com.yummy.yummy.bigModelAPIKey", value: testAPIKey)
        try KeychainService.save(key: "com.yummy.yummy.modelName", value: testModelName)
        
        // 2. 通过 Providers 获取数据
        let apiKey = try apiKeyProvider.apiKey()
        let modelName = try modelProvider.modelName()
        
        // 3. 验证数据一致性
        XCTAssertEqual(apiKey, testAPIKey, "API Key 应该匹配")
        XCTAssertEqual(modelName, testModelName, "Model Name 应该匹配")
        
        // 4. 验证可以用于 API 调用（模拟）
        XCTAssertFalse(apiKey.isEmpty && modelName.isEmpty, "API Key 和 Model Name 都不应该为空")
        
        AppLog("Providers 集成场景测试完成", level: .debug, category: .network)
    }
    
    /// 测试 ProviderError 本地化描述
    func testProviderError_本地化描述() {
        AppLog("开始测试 ProviderError 本地化描述", level: .debug, category: .network)
        
        let testDescription = "测试错误描述"
        let error = ProviderError.missingValue(description: testDescription)
        
        XCTAssertEqual(error.errorDescription, testDescription, "错误描述应该匹配")
        AppLog("ProviderError 本地化描述测试完成", level: .debug, category: .network)
    }
}