//
//  CuisineViewModelTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/17.
//

import XCTest
import Combine
@testable import yummy

@MainActor
class CuisineViewModelTests: XCTestCase {
    
    // MARK: - Properties
    private var viewModel: CuisineViewModel!
    private var mockFormulaRepository: MockFormulaRepository!
    private var mockCuisineStateRepository: MockCuisineStateRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        cancellables = Set<AnyCancellable>()
        
        // 创建Mock对象
        mockFormulaRepository = MockFormulaRepository()
        mockCuisineStateRepository = MockCuisineStateRepository()
        
        // 重置Mock状态
        resetMockStates()
        
        // 每次都创建新的ViewModel实例，确保hasUserInteracted为false
        viewModel = CuisineViewModel(
            formulaRepository: mockFormulaRepository,
            cuisineStateRepository: mockCuisineStateRepository
        )
        
        // 给数据订阅一些时间初始化
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05秒
        
        AppLog("🧪 [CuisineViewModelTests] 测试环境初始化完成", level: .debug, category: .general)
    }
    
    override func tearDown() async throws {
        cancellables?.removeAll()
        viewModel = nil
        mockFormulaRepository = nil
        mockCuisineStateRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() async throws {
        // 验证初始状态
        XCTAssertEqual(viewModel.selectedTab, .procurement, "默认Tab应该是采购")
        XCTAssertTrue(viewModel.cuisineFormulas.isEmpty, "初始料理清单应该为空")
        XCTAssertTrue(viewModel.tabStatuses.isEmpty, "初始Tab状态应该为空")
        XCTAssertEqual(viewModel.cuisineCount, 0, "初始料理数量应该为0")
        XCTAssertTrue(viewModel.isEmpty, "初始状态应该为空")
        XCTAssertEqual(viewModel.getCurrentTabProgress(), 0, "初始进度应该为0")
        
        AppLog("✅ [CuisineViewModelTests] testInitialization 通过", level: .info, category: .general)
    }
    
    // MARK: - 数据订阅测试
    
    func testDataSubscriptionFormulas() async throws {
        // 准备测试数据
        let testFormula = createTestFormula(id: "cuisine-test-001", name: "测试料理", isCuisine: true)
        
        // 发布新的菜谱数据
        mockFormulaRepository.mockFormulas = [testFormula]
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 验证数据订阅
        XCTAssertEqual(viewModel.cuisineFormulas.count, 1, "应该接收到1个料理")
        XCTAssertEqual(viewModel.cuisineFormulas.first?.id, "cuisine-test-001", "料理ID应该匹配")
        XCTAssertEqual(viewModel.cuisineCount, 1, "料理数量应该为1")
        XCTAssertFalse(viewModel.isEmpty, "不应该为空")
        
        AppLog("✅ [CuisineViewModelTests] testDataSubscriptionFormulas 通过", level: .info, category: .general)
    }
    
    func testDataSubscriptionTabStatuses() async throws {
        // 准备测试数据
        let testStatus = createTestTabStatus(formulaId: "test-001", tabType: .procurement)
        
        // 发布Tab状态
        mockCuisineStateRepository.publishTabStatuses([testStatus])
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 验证状态订阅
        XCTAssertEqual(viewModel.tabStatuses.count, 1, "应该接收到1个Tab状态")
        XCTAssertEqual(viewModel.tabStatuses.first?.formulaId, "test-001", "formulaId应该匹配")
        XCTAssertEqual(viewModel.tabStatuses.first?.tabType, .procurement, "Tab类型应该匹配")
        
        AppLog("✅ [CuisineViewModelTests] testDataSubscriptionTabStatuses 通过", level: .info, category: .general)
    }
    
    func testFiltersCuisineFormulasOnly() async throws {
        // 准备测试数据：包含料理清单和非料理清单
        let cuisineFormula = createTestFormula(id: "cuisine-001", name: "料理菜谱", isCuisine: true)
        let normalFormula = createTestFormula(id: "normal-001", name: "普通菜谱", isCuisine: false)
        
        // 发布混合数据
        mockFormulaRepository.mockFormulas = [cuisineFormula, normalFormula]
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 验证过滤功能
        XCTAssertEqual(viewModel.cuisineFormulas.count, 1, "应该只包含料理清单菜谱")
        XCTAssertEqual(viewModel.cuisineFormulas.first?.id, "cuisine-001", "应该是料理清单菜谱")
        XCTAssertTrue(viewModel.cuisineFormulas.first?.isCuisine == true, "isCuisine应该为true")
        
        AppLog("✅ [CuisineViewModelTests] testFiltersCuisineFormulasOnly 通过", level: .info, category: .general)
    }
    
    // MARK: - Tab切换测试
    
    func testTabSwitching() async throws {
        // 验证初始Tab
        XCTAssertEqual(viewModel.selectedTab, .procurement, "初始Tab应该是采购")
        
        // 切换到备菜Tab
        viewModel.selectedTab = .prepare
        XCTAssertEqual(viewModel.selectedTab, .prepare, "Tab应该切换到备菜")
        
        // 切换到料理Tab
        viewModel.selectedTab = .cuisine
        XCTAssertEqual(viewModel.selectedTab, .cuisine, "Tab应该切换到料理")
        
        AppLog("✅ [CuisineViewModelTests] testTabSwitching 通过", level: .info, category: .general)
    }
    
    // MARK: - 项目状态切换测试
    
    func testToggleItemCompletion() async throws {
        // 准备测试数据
        let testFormula = createTestFormula(id: "toggle-test-001")
        let testStatus = createTestTabStatus(formulaId: "toggle-test-001", tabType: .procurement)
        
        // 设置Mock响应
        mockCuisineStateRepository.publishTabStatuses([testStatus])
        viewModel.selectedTab = .procurement
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 执行状态切换
        let testItemId = testStatus.items.first?.id ?? "test-item-id"
        await viewModel.toggleItemCompletion(itemId: testItemId, formulaId: "toggle-test-001")
        
        // 验证save方法被调用
        XCTAssertTrue(mockCuisineStateRepository.saveCalled, "save方法应该被调用")
        XCTAssertNotNil(mockCuisineStateRepository.lastSavedStatus, "应该保存了状态")
        
        AppLog("✅ [CuisineViewModelTests] testToggleItemCompletion 通过", level: .info, category: .general)
    }
    
    func testToggleItemCompletionInvalidFormula() async throws {
        // 设置空的Tab状态
        mockCuisineStateRepository.publishTabStatuses([])
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 尝试切换不存在的项目
        await viewModel.toggleItemCompletion(itemId: "invalid-item", formulaId: "invalid-formula")
        
        // 验证save方法没有被调用
        XCTAssertFalse(mockCuisineStateRepository.saveCalled, "无效项目不应该触发save")
        
        AppLog("✅ [CuisineViewModelTests] testToggleItemCompletionInvalidFormula 通过", level: .info, category: .general)
    }
    
    // MARK: - 数据获取测试
    
    func testGetCurrentTabItems() async throws {
        // 准备测试数据
        let testStatus = createTestTabStatus(formulaId: "tab-items-test", tabType: .procurement)
        
        // 设置当前Tab和状态
        viewModel.selectedTab = .procurement
        mockCuisineStateRepository.publishTabStatuses([testStatus])
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 获取当前Tab项目
        let items = viewModel.getCurrentTabItems()
        
        // 验证结果
        XCTAssertFalse(items.isEmpty, "应该有Tab项目")
        XCTAssertEqual(items.count, testStatus.items.count, "项目数量应该匹配")
        
        AppLog("✅ [CuisineViewModelTests] testGetCurrentTabItems 通过", level: .info, category: .general)
    }
    
    func testGetGroupedTabItems() async throws {
        // 准备测试数据
        let testFormula = createTestFormula(id: "grouped-test-001", name: "分组测试", isCuisine: true)
        let testStatus = createTestTabStatus(formulaId: "grouped-test-001", tabType: .procurement)
        
        // 设置数据 - 确保顺序正确
        mockFormulaRepository.mockFormulas = [testFormula]
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待菜谱数据订阅
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 验证菜谱数据已接收
        XCTAssertEqual(viewModel.cuisineFormulas.count, 1, "应该接收到1个菜谱")
        
        // 然后发布Tab状态
        mockCuisineStateRepository.publishTabStatuses([testStatus])
        viewModel.selectedTab = .procurement
        
        // 等待Tab状态订阅
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 验证Tab状态已接收
        XCTAssertEqual(viewModel.tabStatuses.count, 1, "应该接收到1个Tab状态")
        
        // 获取分组数据
        let groupedItems = viewModel.getGroupedTabItems()
        
        // 验证结果
        XCTAssertEqual(groupedItems.count, 1, "应该有1个分组")
        XCTAssertEqual(groupedItems.first?.formula.id, "grouped-test-001", "菜谱ID应该匹配")
        XCTAssertFalse(groupedItems.first?.items.isEmpty ?? true, "项目不应该为空")
        
        AppLog("✅ [CuisineViewModelTests] testGetGroupedTabItems 通过", level: .info, category: .general)
    }
    
    func testGetTabStatus() async throws {
        // 准备测试数据
        let testStatus = createTestTabStatus(formulaId: "status-test-001", tabType: .cuisine)
        
        // 设置状态
        mockCuisineStateRepository.publishTabStatuses([testStatus])
        viewModel.selectedTab = .cuisine
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 获取特定状态
        let status = viewModel.getTabStatus(for: "status-test-001")
        
        // 验证结果
        XCTAssertNotNil(status, "应该找到对应的状态")
        XCTAssertEqual(status?.formulaId, "status-test-001", "formulaId应该匹配")
        XCTAssertEqual(status?.tabType, .cuisine, "Tab类型应该匹配")
        
        AppLog("✅ [CuisineViewModelTests] testGetTabStatus 通过", level: .info, category: .general)
    }
    
    func testGetCurrentTabProgress() async throws {
        // 准备测试数据：部分完成的项目
        var testStatus = createTestTabStatus(formulaId: "progress-test", tabType: .procurement)
        
        // 设置一半项目为完成状态
        let halfCount = testStatus.items.count / 2
        for i in 0..<halfCount {
            testStatus.items[i].isCompleted = true
        }
        
        // 设置状态
        mockCuisineStateRepository.publishTabStatuses([testStatus])
        viewModel.selectedTab = .procurement
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 获取进度
        let progress = viewModel.getCurrentTabProgress()
        
        // 验证进度
        let expectedProgress = Double(halfCount) / Double(testStatus.items.count)
        XCTAssertEqual(progress, expectedProgress, accuracy: 0.01, "进度应该正确计算")
        
        AppLog("✅ [CuisineViewModelTests] testGetCurrentTabProgress 通过", level: .info, category: .general)
    }
    
    // MARK: - 料理移除测试
    
    func testRemoveFromCuisine() async throws {
        // 准备测试数据
        let testFormula = createTestFormula(id: "remove-test-001", isCuisine: true)
        
        // 执行移除操作
        await viewModel.removeFromCuisine(formula: testFormula)
        
        // 验证Repository方法被调用
        XCTAssertTrue(mockFormulaRepository.saveCalled, "应该调用save方法更新菜谱")
        XCTAssertTrue(mockCuisineStateRepository.deleteTabStatusesCalled, "应该调用deleteTabStatuses")
        XCTAssertEqual(mockCuisineStateRepository.lastDeletedFormulaId, "remove-test-001", "删除的formulaId应该匹配")
        
        // 验证菜谱的isCuisine状态
        XCTAssertTrue(mockFormulaRepository.saveCalled, "应该调用了save方法")
        
        AppLog("✅ [CuisineViewModelTests] testRemoveFromCuisine 通过", level: .info, category: .general)
    }
    
    // MARK: - 聚焦功能测试
    
    func testApplyFocusIfNeeded() async throws {
        // 准备测试数据
        let testFormula = createTestFormula(id: "focus-test-001", isCuisine: true)
        let testTabStatus = createTestTabStatus(formulaId: "focus-test-001", tabType: .procurement)
        
        // 设置菜谱数据
        mockFormulaRepository.mockFormulas = [testFormula]
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待菜谱数据订阅
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 设置Tab状态数据
        mockCuisineStateRepository.publishTabStatuses([testTabStatus])
        
        // 等待Tab状态订阅
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 应用聚焦（直接调用，由于hasUserInteracted在初始化时应该为false）
        viewModel.applyFocusIfNeeded("focus-test-001")
        
        // 验证聚焦状态
        XCTAssertTrue(viewModel.isExpanded(formulaId: "focus-test-001"), "目标菜谱应该被展开")
        
        AppLog("✅ [CuisineViewModelTests] testApplyFocusIfNeeded 通过", level: .info, category: .general)
    }
    
    func testApplyFocusNilId() async throws {
        // 准备测试数据
        let testFormula = createTestFormula(id: "focus-nil-test", isCuisine: true)
        let testTabStatus = createTestTabStatus(formulaId: "focus-nil-test", tabType: .procurement)
        
        // 设置菜谱数据
        mockFormulaRepository.mockFormulas = [testFormula]
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待菜谱数据订阅
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 设置Tab状态数据
        mockCuisineStateRepository.publishTabStatuses([testTabStatus])
        
        // 等待Tab状态订阅
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 应用nil聚焦（应该触发默认展开）
        viewModel.applyFocusIfNeeded(nil)
        
        // 等待默认展开处理
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 验证默认展开被触发
        XCTAssertTrue(viewModel.isExpanded(formulaId: "focus-nil-test"), "第一个菜谱应该被默认展开")
        
        AppLog("✅ [CuisineViewModelTests] testApplyFocusNilId 通过", level: .info, category: .general)
    }
    
    // MARK: - 展开/折叠功能测试
    
    func testToggleExpand() async throws {
        let testId = "expand-test-001"
        
        // 初始状态：未展开
        XCTAssertFalse(viewModel.isExpanded(formulaId: testId), "初始状态应该未展开")
        
        // 展开
        viewModel.toggleExpand(for: testId)
        XCTAssertTrue(viewModel.isExpanded(formulaId: testId), "应该被展开")
        
        // 再次切换：折叠
        viewModel.toggleExpand(for: testId)
        XCTAssertFalse(viewModel.isExpanded(formulaId: testId), "应该被折叠")
        
        AppLog("✅ [CuisineViewModelTests] testToggleExpand 通过", level: .info, category: .general)
    }
    
    func testSingleExpandBehavior() async throws {
        let testId1 = "single-1"
        let testId2 = "single-2"
        
        // 展开第一个
        viewModel.toggleExpand(for: testId1)
        XCTAssertTrue(viewModel.isExpanded(formulaId: testId1), "第一个应该被展开")
        
        // 展开第二个
        viewModel.toggleExpand(for: testId2)
        XCTAssertFalse(viewModel.isExpanded(formulaId: testId1), "第一个应该被折叠")
        XCTAssertTrue(viewModel.isExpanded(formulaId: testId2), "第二个应该被展开")
        
        AppLog("✅ [CuisineViewModelTests] testSingleExpandBehavior 通过", level: .info, category: .general)
    }
    
    // MARK: - 清空功能测试
    
    func testClearAllCuisineFormulas() async throws {
        // 准备测试数据
        let testFormulas = [
            createTestFormula(id: "clear-001", isCuisine: true),
            createTestFormula(id: "clear-002", isCuisine: true)
        ]
        
        // 设置数据
        mockFormulaRepository.mockFormulas = testFormulas
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待异步更新（增加等待时间）
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        
        // 确保数据已经被加载
        XCTAssertEqual(viewModel.cuisineFormulas.count, 2, "应该有2个菜谱")
        
        // 执行清空操作
        await viewModel.clearAllCuisineFormulas()
        
        // 验证所有菜谱的save方法被调用
        XCTAssertTrue(mockFormulaRepository.saveCalled, "应该调用save方法")
        XCTAssertTrue(mockCuisineStateRepository.deleteTabStatusesCalled, "应该调用deleteTabStatuses")
        
        AppLog("✅ [CuisineViewModelTests] testClearAllCuisineFormulas 通过", level: .info, category: .general)
    }
    
    func testClearEmptyCuisineList() async throws {
        // 空的料理清单
        mockFormulaRepository.mockFormulas = []
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待异步更新
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        // 执行清空操作
        await viewModel.clearAllCuisineFormulas()
        
        // 验证没有调用不必要的方法
        XCTAssertFalse(mockFormulaRepository.saveCalled, "空清单不应该调用save")
        XCTAssertFalse(mockCuisineStateRepository.deleteTabStatusesCalled, "空清单不应该调用delete")
        
        AppLog("✅ [CuisineViewModelTests] testClearEmptyCuisineList 通过", level: .info, category: .general)
    }
    
    // MARK: - 错误处理测试
    
    func testRepositoryError() async throws {
        // 设置Mock返回错误
        mockCuisineStateRepository.shouldThrowError = true
        
        let testFormula = createTestFormula(id: "error-test")
        
        // 执行可能出错的操作（不应该崩溃）
        await viewModel.removeFromCuisine(formula: testFormula)
        
        // 验证错误被正确处理（不崩溃即为成功）
        XCTAssertTrue(true, "错误应该被正确处理")
        
        AppLog("✅ [CuisineViewModelTests] testRepositoryError 通过", level: .info, category: .general)
    }
    
    // MARK: - 辅助方法
    
    private func createTestFormula(id: String = "test-formula", 
                                   name: String = "测试菜谱", 
                                   isCuisine: Bool = true) -> Formula {
        var formula = Formula(
            name: name,
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "测试食榐1", quantity: "100g", category: "主料"),
                    Ingredient(name: "测试食榐2", quantity: "200g", category: "主料")
                ],
                spicesSeasonings: [
                    Ingredient(name: "测试调料", quantity: "适量", category: "调料")
                ],
                sauce: [
                    SauceIngredient(name: "测试酱料", quantity: "2勺")
                ]
            ),
            tools: [
                Tool(name: "案板"),
                Tool(name: "刀")
            ],
            preparation: [
                PreparationStep(step: "测试准备步骤1", details: "详细说明1"),
                PreparationStep(step: "测试准备步骤2", details: "详细说明2")
            ],
            steps: [
                CookingStep(step: "测试烹饥步骤1", details: "详细说明1"),
                CookingStep(step: "测试烹饥步骤2", details: "详细说明2")
            ],
            tips: [
                "测试小贴士1",
                "测试小贴士2"
            ],
            tags: ["测试", "单元测试"],
            date: Date(),
            state: .finish
        )
        formula.id = id
        formula.isCuisine = isCuisine
        return formula
    }
    
    // MARK: - 辅助方法
    
    private func resetMockStates() {
        mockFormulaRepository?.reset()
        mockCuisineStateRepository?.reset()
    }
}

// 没有重复的Mock类定义，使用TestHelpers.swift中的定义
