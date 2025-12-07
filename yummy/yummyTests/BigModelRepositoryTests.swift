//
//  BigModelRepositoryTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/11.
//

import XCTest
import Foundation
@testable import yummy

final class BigModelRepositoryTests: XCTestCase {
    
    var repository: BigModelRepositoryImpl!
    var mockAPIKeyProvider: MockAPIKeyProvider!
    var mockModelProvider: MockModelProvider!
    var mockAPIService: MockBigModelAPIService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        mockAPIKeyProvider = MockAPIKeyProvider()
        mockModelProvider = MockModelProvider()
        mockAPIService = MockBigModelAPIService()
        
        repository = BigModelRepositoryImpl(
            apiKeyProvider: mockAPIKeyProvider,
            modelProvider: mockModelProvider,
            apiService: mockAPIService
        )
        
        AppLog("🧹 [测试环境] BigModelRepositoryTests 准备就绪", level: .debug, category: .service)
    }
    
    override func tearDownWithError() throws {
        repository = nil
        mockAPIKeyProvider = nil
        mockModelProvider = nil
        mockAPIService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 基础功能测试
    
    func testRepositoryInitialization() throws {
        // 测试Repository正确初始化
        XCTAssertNotNil(repository, "Repository应该正确初始化")
        AppLog("✅ Repository初始化测试通过", level: .debug, category: .service)
    }
    
    func testGenerateFormulaSuccess() async throws {
        // 设置Mock返回值
        mockAPIKeyProvider.mockAPIKey = "test-api-key-12345"
        mockModelProvider.mockModelName = "glm-4-flash"
        mockAPIService.mockFormula = createTestFormula()
        
        let expectation = XCTestExpectation(description: "成功生成菜谱")
        
        let testPrompt = "制作一道简单的西红柿炒蛋"
        
        do {
            let formula = try await repository.generateFormula(from: testPrompt)
            
            // 验证结果
            XCTAssertNotNil(formula, "应该返回有效的Formula")
            XCTAssertEqual(formula.name, "测试菜谱", "菜谱名称应该匹配")
            XCTAssertTrue(formula.ingredients.mainIngredients.count > 0, "应该包含主要食材")
            XCTAssertTrue(formula.steps.count > 0, "应该包含制作步骤")
            
            // 验证Mock被正确调用
            XCTAssertTrue(mockAPIKeyProvider.apiKeyCalled, "应该调用了apiKey方法")
            XCTAssertTrue(mockModelProvider.modelNameCalled, "应该调用了modelName方法")
            XCTAssertTrue(mockAPIService.callAPICalled, "应该调用了callAPI方法")
            
            // 验证传递的参数
            XCTAssertEqual(mockAPIService.lastAPIKey, "test-api-key-12345", "API Key应该正确传递")
            XCTAssertEqual(mockAPIService.lastModelName, "glm-4-flash", "模型名称应该正确传递")
            XCTAssertTrue(mockAPIService.lastPrompt?.contains(testPrompt) ?? false, "原始prompt应该包含在完整prompt中")
            XCTAssertTrue(mockAPIService.lastPrompt?.contains(PromptConstants.userPrompt) ?? false, "应该拼接了userPrompt")
            
            expectation.fulfill()
        } catch {
            XCTFail("生成菜谱失败: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        AppLog("✅ 成功生成菜谱测试通过", level: .debug, category: .service)
    }
    
    func testGenerateFormulaAPIKeyProviderError() async throws {
        // 设置APIKeyProvider抛出错误
        mockAPIKeyProvider.shouldThrowError = true
        mockAPIKeyProvider.mockError = ProviderError.missingValue(description: "API Key not found")
        
        let expectation = XCTestExpectation(description: "API Key错误处理")
        
        do {
            _ = try await repository.generateFormula(from: "测试prompt")
            XCTFail("应该抛出错误")
        } catch let error as ProviderError {
            switch error {
            case .missingValue(let description):
                XCTAssertEqual(description, "API Key not found", "错误信息应该匹配")
            }
            XCTAssertFalse(mockAPIService.callAPICalled, "出错时不应该调用API服务")
        } catch {
            XCTFail("应该抛出ProviderError类型的错误")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        AppLog("✅ API Key错误处理测试通过", level: .debug, category: .service)
    }
    
    func testGenerateFormulaModelProviderError() async throws {
        // 设置正常的API Key，但ModelProvider抛出错误
        mockAPIKeyProvider.mockAPIKey = "test-api-key"
        mockModelProvider.shouldThrowError = true
        mockModelProvider.mockError = ProviderError.missingValue(description: "Model name not found")
        
        let expectation = XCTestExpectation(description: "Model Provider错误处理")
        
        do {
            _ = try await repository.generateFormula(from: "测试prompt")
            XCTFail("应该抛出错误")
        } catch let error as ProviderError {
            switch error {
            case .missingValue(let description):
                XCTAssertEqual(description, "Model name not found", "错误信息应该匹配")
            }
            XCTAssertTrue(mockAPIKeyProvider.apiKeyCalled, "应该先调用了apiKey方法")
            XCTAssertTrue(mockModelProvider.modelNameCalled, "应该调用了modelName方法")
            XCTAssertFalse(mockAPIService.callAPICalled, "出错时不应该调用API服务")
        } catch {
            XCTFail("应该抛出ProviderError类型的错误")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        AppLog("✅ Model Provider错误处理测试通过", level: .debug, category: .service)
    }
    
    func testGenerateFormulaAPIServiceError() async throws {
        // 设置正常的Provider，但API服务抛出错误
        mockAPIKeyProvider.mockAPIKey = "test-api-key"
        mockModelProvider.mockModelName = "test-model"
        mockAPIService.shouldThrowError = true
        mockAPIService.mockError = BigModelAPIError.requestFailed("网络错误")
        
        let expectation = XCTestExpectation(description: "API Service错误处理")
        
        do {
            _ = try await repository.generateFormula(from: "测试prompt")
            XCTFail("应该抛出错误")
        } catch let error as BigModelAPIError {
            switch error {
            case .requestFailed(let message):
                XCTAssertEqual(message, "网络错误", "错误信息应该匹配")
            default:
                XCTFail("应该是requestFailed错误")
            }
            
            // 验证调用流程
            XCTAssertTrue(mockAPIKeyProvider.apiKeyCalled, "应该调用了apiKey方法")
            XCTAssertTrue(mockModelProvider.modelNameCalled, "应该调用了modelName方法")
            XCTAssertTrue(mockAPIService.callAPICalled, "应该调用了callAPI方法")
        } catch {
            XCTFail("应该抛出BigModelAPIError类型的错误")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        AppLog("✅ API Service错误处理测试通过", level: .debug, category: .service)
    }
    
    // MARK: - Prompt拼接测试
    
    func testPromptConcatenation() async throws {
        mockAPIKeyProvider.mockAPIKey = "test-key"
        mockModelProvider.mockModelName = "test-model"
        mockAPIService.mockFormula = createTestFormula()
        
        let expectation = XCTestExpectation(description: "Prompt拼接测试")
        
        let userInput = "我想学做红烧肉"
        
        do {
            _ = try await repository.generateFormula(from: userInput)
            
            // 验证prompt拼接是否正确
            XCTAssertNotNil(mockAPIService.lastPrompt, "应该记录了最后的prompt")
            
            let expectedPrompt = userInput + PromptConstants.userPrompt
            XCTAssertEqual(mockAPIService.lastPrompt, expectedPrompt, "完整prompt应该是用户输入 + 系统prompt")
            
            // 验证包含了关键内容
            XCTAssertTrue(mockAPIService.lastPrompt?.contains("我想学做红烧肉") ?? false, "应该包含用户原始输入")
            XCTAssertTrue(mockAPIService.lastPrompt?.contains("整理出所需主要食材") ?? false, "应该包含系统指令")
            XCTAssertTrue(mockAPIService.lastPrompt?.contains("json 格式输出") ?? false, "应该包含格式要求")
        } catch {
            XCTFail("不应该出现错误")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        AppLog("✅ Prompt拼接测试通过", level: .debug, category: .service)
    }
    
    func testEmptyPromptHandling() async throws {
        mockAPIKeyProvider.mockAPIKey = "test-key"
        mockModelProvider.mockModelName = "test-model"
        mockAPIService.mockFormula = createTestFormula()
        
        let expectation = XCTestExpectation(description: "空prompt处理测试")
        
        do {
            _ = try await repository.generateFormula(from: "")
            
            // 验证即使用户输入为空，也能正确拼接系统prompt
            XCTAssertEqual(mockAPIService.lastPrompt, PromptConstants.userPrompt, "空输入时应该只包含系统prompt")
        } catch {
            XCTFail("空prompt处理不应该出错")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        AppLog("✅ 空prompt处理测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 依赖注入测试
    
    func testDependencyInjection() throws {
        // 测试可以正确注入不同的依赖
        let customAPIKeyProvider = MockAPIKeyProvider()
        let customModelProvider = MockModelProvider()
        let customAPIService = MockBigModelAPIService()
        
        let customRepository = BigModelRepositoryImpl(
            apiKeyProvider: customAPIKeyProvider,
            modelProvider: customModelProvider,
            apiService: customAPIService
        )
        
        XCTAssertNotNil(customRepository, "自定义依赖的Repository应该正确初始化")
        AppLog("✅ 依赖注入测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 辅助方法
    
    private func createTestFormula() -> Formula {
        var formula = Formula(
            name: "测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "鸡蛋", quantity: "3个", category: "蛋类"),
                    Ingredient(name: "西红柿", quantity: "2个", category: "蔬菜类")
                ],
                spicesSeasonings: [
                    Ingredient(name: "盐", quantity: "适量", category: nil),
                    Ingredient(name: "糖", quantity: "1勺", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "生抽", quantity: "1勺")
                ]
            ),
            tools: [
                Tool(name: "炒锅"),
                Tool(name: "铲子")
            ],
            preparation: [
                PreparationStep(step: "准备食材", details: "将鸡蛋打散，西红柿切块")
            ],
            steps: [
                CookingStep(step: "炒鸡蛋", details: "热锅下油，倒入蛋液炒熟盛起"),
                CookingStep(step: "炒西红柿", details: "下西红柿炒出汁水"),
                CookingStep(step: "合并", details: "倒入鸡蛋翻炒均匀即可")
            ],
            tips: ["火候要掌握好", "鸡蛋要嫩滑"],
            tags: ["家常菜", "简单", "营养"],
            date: Date(),
            prompt: "测试用的菜谱生成",
            state: .finish,
            imgpath: nil,
            isCuisine: true
        )
        
        formula.id = "test-formula-\(UUID().uuidString)"
        return formula
    }
}

// MARK: - Mock Classes

class MockAPIKeyProvider: APIKeyProvider {
    var mockAPIKey: String = "default-test-key"
    var shouldThrowError: Bool = false
    var mockError: Error?
    var apiKeyCalled: Bool = false
    
    func apiKey() throws -> String {
        apiKeyCalled = true
        if shouldThrowError {
            throw mockError ?? ProviderError.missingValue(description: "Test error")
        }
        return mockAPIKey
    }
}

class MockModelProvider: ModelProvider {
    var mockModelName: String = "default-test-model"
    var shouldThrowError: Bool = false
    var mockError: Error?
    var modelNameCalled: Bool = false
    
    func modelName() throws -> String {
        modelNameCalled = true
        if shouldThrowError {
            throw mockError ?? ProviderError.missingValue(description: "Test error")
        }
        return mockModelName
    }
}

class MockBigModelAPIService: BigModelAPIService {
    var mockFormula: Formula?
    var shouldThrowError: Bool = false
    var mockError: Error?
    var callAPICalled: Bool = false
    
    // 记录最后一次调用的参数
    var lastAPIKey: String?
    var lastModelName: String?
    var lastPrompt: String?
    
    override func callAPI(apiKey: String, modelName: String, prompt: String) async throws -> Formula {
        callAPICalled = true
        lastAPIKey = apiKey
        lastModelName = modelName
        lastPrompt = prompt
        
        if shouldThrowError {
            throw mockError ?? BigModelAPIError.requestFailed("Mock error")
        }
        
        guard let formula = mockFormula else {
            throw BigModelAPIError.noData
        }
        
        return formula
    }
}