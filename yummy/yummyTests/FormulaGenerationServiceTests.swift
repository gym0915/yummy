//
//  FormulaGenerationServiceTests.swift
//  yummyTests
//
//  Created by AI Assistant on 2025/09/19.
//

import XCTest
import Combine
@testable import yummy

// MARK: - Mock Classes

/// 模拟BigModelRepository
class MockBigModelRepository: BigModelRepository {
    
    private func createMockFormula() -> Formula {
        return Formula(
            name: "测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [Ingredient(name: "鸡蛋", quantity: "2个", category: "蛋类"), Ingredient(name: "盐", quantity: "适量", category: "调味品")],
                spicesSeasonings: [],
                sauce: []
            ),
            tools: [],
            preparation: [],
            steps: [CookingStep(step: "打蛋", details: "将鸡蛋打入碗中"), CookingStep(step: "加盐", details: "加入适量的盐")],
            tips: [],
            tags: ["测试"],
            date: Date(),
            prompt: nil,
            state: .loading,
            imgpath: nil,
            isCuisine: false
        )
    }
    var shouldReturnSuccess = true
    var mockResponse: String?
    var mockError: Error?
    var generationCallCount = 0
    var lastPrompt: String?
    var lastFormula: Formula?
    
    func generateFormula(from prompt: String) async throws -> Formula {
        generationCallCount += 1
        lastPrompt = prompt
        
        if !shouldReturnSuccess {
            throw mockError ?? NSError(domain: "AIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "生成失败"])
        }
        
        if let response = mockResponse, let data = response.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let name = json["name"] as? String ?? "测试菜谱"
                    let ingredientsArray = json["ingredients"] as? [String] ?? []
                    let stepsArray = json["steps"] as? [String] ?? []
                    
                    let ingredients = Ingredients(
                        mainIngredients: ingredientsArray.map { Ingredient(name: $0, quantity: "", category: nil) },
                        spicesSeasonings: [],
                        sauce: []
                    )
                    let steps = stepsArray.map { CookingStep(step: $0, details: "") }
                    
                    var formula = Formula(
                        name: name,
                        ingredients: ingredients,
                        tools: [],
                        preparation: [],
                        steps: steps,
                        tips: [],
                        tags: [],
                        date: Date(),
                        prompt: prompt,
                        state: .loading,
                        imgpath: nil,
                        isCuisine: false
                    )
                    lastFormula = formula
                    return formula
                } else {
                    throw NSError(domain: "ParseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "无效的JSON"])
                }
            } catch {
                throw mockError ?? error
            }
        }
        
        lastFormula = createMockFormula()
        return lastFormula!
    }
}

/// 模拟NotificationService
class MockNotificationService: NotificationServiceProtocol {
    var sentNotifications: [(formulaName: String, formulaId: String)] = []
    var notificationCallCount = 0
    var lastTitle: String?
    
    func sendFormulaCompletionNotification(formulaName: String, formulaId: String) async {
        notificationCallCount += 1
        lastTitle = "菜谱生成完成"
        // 模拟通知发送完成
        sentNotifications.append((formulaName: formulaName, formulaId: formulaId))
    }
}

/// 模拟AppStateManager
class MockAppStateManager: AppStateManaging {
    var mockIsAppInBackground = false
    
    func isAppInBackground() async -> Bool { mockIsAppInBackground }
}

// MARK: - Test Cases

/// FormulaGenerationService 测试类
class FormulaGenerationServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var service: FormulaGenerationService!
    var mockBigModelRepository: MockBigModelRepository!
    var mockFormulaRepository: MockFormulaRepository!
    var mockNotificationService: MockNotificationService!
    var mockAppStateManager: MockAppStateManager!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        mockBigModelRepository = MockBigModelRepository()
        mockFormulaRepository = MockFormulaRepository()
        mockNotificationService = MockNotificationService()
        mockAppStateManager = MockAppStateManager()
        cancellables = []
        
        service = FormulaGenerationService(
            bigModelRepository: mockBigModelRepository,
            formulaRepository: mockFormulaRepository,
            notificationService: mockNotificationService,
            appStateManager: mockAppStateManager
        )
        
        AppLog("FormulaGenerationServiceTests 设置完成", level: .debug, category: .formula)
    }
    
    override func tearDown() {
        service = nil
        mockBigModelRepository = nil
        mockFormulaRepository = nil
        mockNotificationService = nil
        mockAppStateManager = nil
        cancellables = nil
        
        AppLog("FormulaGenerationServiceTests 清理完成", level: .debug, category: .formula)
        super.tearDown()
    }
    
    // MARK: - 基础功能测试
    
    /// 测试成功生成菜谱
    func testGenerateAndSaveSuccess() async {
        AppLog("测试成功生成菜谱", level: .debug, category: .formula)
        
        // Given
        let expectation = XCTestExpectation(description: "等待菜谱生成完成")
        let prompt = "制作一道简单的炒鸡蛋"
        
        mockBigModelRepository.shouldReturnSuccess = true
        mockBigModelRepository.mockResponse = "{\"name\":\"炒鸡蛋\",\"ingredients\":[\"鸡蛋\",\"盐\",\"油\"],\"steps\":[\"打散鸡蛋\",\"加盐调味\",\"热锅下油\",\"倒入蛋液炒制\"]}"
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 监听FormulaRepository的变化
        var receivedFormulas: [[Formula]] = []
        mockFormulaRepository.formulasPublisher
            .sink { formulas in
                receivedFormulas.append(formulas)
                if formulas.count == 1 && formulas.first?.state == .upload {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await service.generateAndSave(prompt: prompt)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 1, "应该调用一次大模型生成")
        XCTAssertEqual(mockBigModelRepository.lastPrompt, prompt, "应该使用正确的提示词")
        XCTAssertEqual(receivedFormulas.count, 2, "应该收到两次公式更新（创建和完成）")
        
        if let completedFormula = receivedFormulas.last?.first {
            XCTAssertEqual(completedFormula.name, "炒鸡蛋", "菜谱名称应该正确")
            XCTAssertEqual(completedFormula.state, .upload, "状态应该是上传等待封面")
            XCTAssertEqual(completedFormula.ingredients.mainIngredients.count, 3, "应该有3个食材")
            XCTAssertEqual(completedFormula.steps.count, 4, "应该有4个步骤")
        }
        
        AppLog("成功生成菜谱测试通过", level: .debug, category: .formula)
    }
    
    /// 测试生成菜谱失败
    func testGenerateAndSaveFailure() async {
        AppLog("测试生成菜谱失败", level: .debug, category: .formula)
        
        // Given
        let expectation = XCTestExpectation(description: "等待菜谱生成失败")
        let prompt = "制作一道不可能的菜"
        
        mockBigModelRepository.shouldReturnSuccess = false
        mockBigModelRepository.mockError = NSError(domain: "AIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "AI生成失败"])
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 监听FormulaRepository的变化
        var receivedFormulas: [[Formula]] = []
        mockFormulaRepository.formulasPublisher
            .sink { formulas in
                receivedFormulas.append(formulas)
                if let firstFormula = formulas.first, firstFormula.state == .error {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await service.generateAndSave(prompt: prompt)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 1, "应该调用一次大模型生成")
        XCTAssertEqual(receivedFormulas.count, 2, "应该收到两次公式更新（创建和失败）")
        
        if let failedFormula = receivedFormulas.last?.first {
            XCTAssertEqual(failedFormula.state, .error, "状态应该是失败")
        }
        
        AppLog("生成菜谱失败测试通过", level: .debug, category: .formula)
    }
    
    /// 测试重试功能
    func testRetrySuccess() async {
        AppLog("测试重试功能", level: .debug, category: .formula)
        
        // Given
        let expectation = XCTestExpectation(description: "等待重试完成")
        let originalFormula = Formula(
            name: "失败的菜谱",
            ingredients: Ingredients(),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: Date(),
            prompt: "重新制作炒鸡蛋",
            state: .error,
            imgpath: nil,
            isCuisine: false
        )
        
        mockBigModelRepository.shouldReturnSuccess = true
        mockBigModelRepository.mockResponse = "{\"name\":\"重试炒鸡蛋\",\"ingredients\":[\"鸡蛋\",\"盐\"],\"steps\":[\"打散\",\"炒制\"]}"
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 先添加失败的公式到repository
        mockFormulaRepository.mockFormulas = [originalFormula]
        
        // 监听FormulaRepository的变化
        var receivedFormulas: [[Formula]] = []
        mockFormulaRepository.formulasPublisher
            .sink { formulas in
                receivedFormulas.append(formulas)
                if let formula = formulas.first, formula.state == .upload {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await service.retry(formula: originalFormula)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 1, "应该调用一次大模型生成")
        XCTAssertEqual(mockBigModelRepository.lastPrompt, "重新制作炒鸡蛋", "应该使用原始提示词重试")
        
        if let completedFormula = receivedFormulas.last?.first {
            XCTAssertEqual(completedFormula.state, .upload, "状态应该是上传等待封面")
            XCTAssertEqual(completedFormula.name, "重试炒鸡蛋", "菜谱名称应该更新")
        }
        
        AppLog("重试功能测试通过", level: .debug, category: .formula)
    }
    
    // MARK: - 边界条件测试
    
    /// 测试空提示词处理
    func testEmptyPrompt() {
        AppLog("测试空提示词处理", level: .debug, category: .formula)
        
        // Given
        let emptyPrompt = ""
        
        // When
        let exp = expectation(description: "调用异步 actor 方法")
        Task {
            await service.generateAndSave(prompt: emptyPrompt)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        // Then - 应该正常处理，不抛出异常
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 0, "空提示词不应该调用大模型")
        
        AppLog("空提示词处理测试通过", level: .debug, category: .formula)
    }
    
    /// 测试后台生成模式
    func testBackgroundGeneration() async {
        AppLog("测试后台生成模式", level: .debug, category: .formula)
        
        // Given
        let expectation = XCTestExpectation(description: "等待后台生成完成")
        let prompt = "后台制作菜谱"
        
        mockAppStateManager.mockIsAppInBackground = true
        mockBigModelRepository.shouldReturnSuccess = true
        mockBigModelRepository.mockResponse = "{\"name\":\"后台菜谱\",\"ingredients\":[\"食材\"],\"steps\":[\"步骤\"]}"
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 监听FormulaRepository的变化
        var receivedFormulas: [[Formula]] = []
        mockFormulaRepository.formulasPublisher
            .sink { formulas in
                receivedFormulas.append(formulas)
                if let formula = formulas.first, formula.state == .upload {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await service.generateAndSave(prompt: prompt)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 1, "应该调用大模型生成")
        XCTAssertEqual(mockNotificationService.notificationCallCount, 1, "后台生成应该发送通知")
        XCTAssertEqual(mockNotificationService.lastTitle, "菜谱生成完成", "通知标题应该正确")
        
        AppLog("后台生成模式测试通过", level: .debug, category: .formula)
    }
    
    /// 测试无效JSON响应处理
    func testInvalidJSONResponse() async {
        AppLog("测试无效JSON响应处理", level: .debug, category: .formula)
        
        // Given
        let expectation = XCTestExpectation(description: "等待处理无效JSON")
        let prompt = "制作菜谱"
        
        mockBigModelRepository.shouldReturnSuccess = true
        mockBigModelRepository.mockResponse = "无效的JSON响应"
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 监听FormulaRepository的变化
        var receivedFormulas: [[Formula]] = []
        mockFormulaRepository.formulasPublisher
            .sink { formulas in
                receivedFormulas.append(formulas)
                if let formula = formulas.first, formula.state == .error {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await service.generateAndSave(prompt: prompt)
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 1, "应该调用大模型生成")
        
        if let failedFormula = receivedFormulas.last?.first {
            XCTAssertEqual(failedFormula.state, .error, "状态应该是失败")
        }
        
        AppLog("无效JSON响应处理测试通过", level: .debug, category: .formula)
    }
    
    // MARK: - 并发测试
    
    /// 测试并发生成多个菜谱
    func testConcurrentGeneration() async {
        AppLog("测试并发生成多个菜谱", level: .debug, category: .formula)
        
        // Given
        let expectation = XCTestExpectation(description: "等待所有菜谱生成完成")
        expectation.expectedFulfillmentCount = 3
        
        let prompts = ["菜谱1", "菜谱2", "菜谱3"]
        var completedCount = 0
        
        mockBigModelRepository.shouldReturnSuccess = true
        mockBigModelRepository.mockResponse = "{\"name\":\"测试菜谱\",\"ingredients\":[\"食材\"],\"steps\":[\"步骤\"]}"
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 监听FormulaRepository的变化
        mockFormulaRepository.formulasPublisher
            .sink { formulas in
        let completedFormulas = formulas.filter { $0.state == .upload }
                if completedFormulas.count > completedCount {
                    let newCompleted = completedFormulas.count - completedCount
                    completedCount = completedFormulas.count
                    for _ in 0..<newCompleted {
                        expectation.fulfill()
                    }
                }
            }
            .store(in: &cancellables)
        
        // When
        for prompt in prompts {
            await service.generateAndSave(prompt: prompt)
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 10.0)
        
        XCTAssertEqual(mockBigModelRepository.generationCallCount, 3, "应该调用3次大模型生成")
        
        AppLog("并发生成多个菜谱测试通过", level: .debug, category: .formula)
    }
    
    // MARK: - 性能测试
    
    /// 测试生成性能
    func testGenerationPerformance() {
        AppLog("测试生成性能", level: .debug, category: .formula)
        
        // Given
        mockBigModelRepository.shouldReturnSuccess = true
        mockBigModelRepository.mockResponse = "{\"name\":\"性能测试菜谱\",\"ingredients\":[\"食材1\",\"食材2\"],\"steps\":[\"步骤1\",\"步骤2\"]}"
        mockFormulaRepository.shouldReturnSuccess = true
        
        // When & Then
        measure {
            let perfExpectation = XCTestExpectation(description: "性能测试")
            
            mockFormulaRepository.formulasPublisher
                .first()
                .sink { _ in
                    perfExpectation.fulfill()
                }
                .store(in: &cancellables)
            
            let exp = expectation(description: "性能用例中调用 actor 方法")
            Task {
                await service.generateAndSave(prompt: "性能测试")
                exp.fulfill()
            }
            wait(for: [exp], timeout: 1.0)
            
            wait(for: [perfExpectation], timeout: 2.0)
        }
        
        AppLog("生成性能测试通过", level: .debug, category: .formula)
    }
}
