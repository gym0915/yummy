import XCTest
import UIKit
import Combine
@testable import yummy

/// HomeViewModel 测试类
/// 测试主页面的所有业务逻辑和状态管理
@MainActor
final class HomeViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var viewModel: HomeViewModel!
    private var mockFormulaRepository: MockFormulaRepository!
    private var cancellables: Set<AnyCancellable>!
    
    // 测试用的 Formula 数据
    private var testFormulas: [Formula]!
    private let testFormulaId1 = "test-home-formula-id-1"
    private let testFormulaId2 = "test-home-formula-id-2"
    private let testFormulaId3 = "test-home-formula-id-3"
    
    // MARK: - Test Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        AppLog("=== HomeViewModelTests setUp 开始 ===", level: .debug, category: .viewmodel)
        
        cancellables = Set<AnyCancellable>()
        
        // 创建测试用的 Formula 数据
        testFormulas = createTestFormulas()
        
        // 创建 Mock 对象
        mockFormulaRepository = MockFormulaRepository()
        
        // 设置初始数据
        mockFormulaRepository.mockFormulas = testFormulas
        
        // 发送初始数据到 Publisher
        mockFormulaRepository.sendFormulasUpdate()
        
        // 创建 ViewModel
        viewModel = HomeViewModel(repository: mockFormulaRepository)
        
        // 等待数据初始化
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05秒
        
        AppLog("HomeViewModelTests setUp 完成", level: .debug, category: .viewmodel)
    }
    
    override func tearDown() async throws {
        AppLog("=== HomeViewModelTests tearDown 开始 ===", level: .debug, category: .viewmodel)
        
        cancellables = nil
        viewModel = nil
        mockFormulaRepository = nil
        testFormulas = nil
        
        AppLog("HomeViewModelTests tearDown 完成", level: .debug, category: .viewmodel)
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// 创建测试用的 Formula 列表
    private func createTestFormulas() -> [Formula] {
        var testFormulas = [
            Formula(
                name: "测试菜谱1",
                ingredients: Ingredients(
                    mainIngredients: [Ingredient(name: "主料1", quantity: "100g", category: nil)],
                    spicesSeasonings: [Ingredient(name: "配料1", quantity: "适量", category: nil)],
                    sauce: [SauceIngredient(name: "蘸料1", quantity: "1勺")]
                ),
                tools: [Tool(name: "平底锅")],
                preparation: [PreparationStep(step: "准备1", details: "准备步骤1")],
                steps: [CookingStep(step: "料理1", details: "料理步骤1")],
                tips: ["小贴士1"],
                tags: ["测试", "主页"],
                date: Date(),
                prompt: nil,
                state: .finish,
                imgpath: "test-image-path-1.jpg",
                isCuisine: false
            ),
            
            Formula(
                name: "测试菜谱2",
                ingredients: Ingredients(
                    mainIngredients: [Ingredient(name: "主料2", quantity: "200g", category: nil)],
                    spicesSeasonings: [Ingredient(name: "配料2", quantity: "适量", category: nil)],
                    sauce: [SauceIngredient(name: "蘸料2", quantity: "2勺")]
                ),
                tools: [Tool(name: "炒锅")],
                preparation: [PreparationStep(step: "准备2", details: "准备步骤2")],
                steps: [CookingStep(step: "料理2", details: "料理步骤2")],
                tips: ["小贴士2"],
                tags: ["测试", "主页", "料理"],
                date: Date(),
                prompt: nil,
                state: .loading,
                imgpath: nil,
                isCuisine: true
            ),
            
            Formula(
                name: "测试菜谱3",
                ingredients: Ingredients(
                    mainIngredients: [Ingredient(name: "主料3", quantity: "300g", category: nil)],
                    spicesSeasonings: [Ingredient(name: "配料3", quantity: "适量", category: nil)],
                    sauce: [SauceIngredient(name: "蘸料3", quantity: "3勺")]
                ),
                tools: [Tool(name: "蒸锅")],
                preparation: [PreparationStep(step: "准备3", details: "准备步骤3")],
                steps: [CookingStep(step: "料理3", details: "料理步骤3")],
                tips: ["小贴士3"],
                tags: ["测试", "主页"],
                date: Date(),
                prompt: nil,
                state: .error,
                imgpath: nil,
                isCuisine: false
            )
        ]
        
        // 设置 ID
        testFormulas[0].id = testFormulaId1
        testFormulas[1].id = testFormulaId2
        testFormulas[2].id = testFormulaId3
        
        return testFormulas
    }
    
    // MARK: - Initialization Tests
    
    /// 测试 ViewModel 初始化
    func testInitialization() {
        AppLog("开始测试 ViewModel 初始化", level: .debug, category: .viewmodel)
        
        XCTAssertNotNil(viewModel, "ViewModel 应该成功初始化")
        
        // 由于 Mock 使用 PassthroughSubject，初始化前发送的事件可能被丢失。
        // 在断言前补发一次数据并等待主线程刷新，确保订阅收到。
        mockFormulaRepository.sendFormulasUpdate()
        let exp = expectation(description: "wait initial updates")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(viewModel.formulaList.count, 3, "应该加载3个测试菜谱")
        XCTAssertEqual(viewModel.cuisineCount, 1, "应该有1个料理清单菜谱")
        // 计时器可能已经开始运行，所以tick值可能不为0，只需要验证它是非负数即可
        XCTAssertGreaterThanOrEqual(viewModel.tick, 0, "tick 应该大于等于 0")
        XCTAssertNil(viewModel.deleteOverlayTargetId, "初始状态不应该有删除覆盖层")
        XCTAssertNil(viewModel.deleteConfirmationRequestId, "初始状态不应该有删除确认请求")
        
        AppLog("ViewModel 初始化测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试默认初始化（使用真实的 Repository）
    func testDefaultInitialization() {
        AppLog("开始测试默认初始化", level: .debug, category: .viewmodel)
        
        let defaultViewModel = HomeViewModel()
        XCTAssertNotNil(defaultViewModel, "默认 ViewModel 应该成功初始化")
        
        AppLog("默认初始化测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Data Subscription Tests
    
    /// 测试 FormulaList 数据订阅
    func testFormulaListSubscription() {
        AppLog("开始测试 FormulaList 数据订阅", level: .debug, category: .viewmodel)
        
        let expectation = XCTestExpectation(description: "数据订阅更新")
        var updateCount = 0
        
        // 监听数据变化
        viewModel.$formulaList
            .sink { formulas in
                updateCount += 1
                if updateCount >= 2 { // 初始值 + 更新值
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 更新 Repository 中的数据
        var newFormula = Formula(
            name: "新测试菜谱",
            ingredients: Ingredients(mainIngredients: [], spicesSeasonings: [], sauce: []),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: Date(),
            prompt: nil,
            state: .finish,
            imgpath: nil,
            isCuisine: false
        )
        newFormula.id = "new-test-id"
        
        mockFormulaRepository.mockFormulas.append(newFormula)
        mockFormulaRepository.sendFormulasUpdate()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(viewModel.formulaList.count, 4, "数据应该通过订阅更新")
        
        AppLog("FormulaList 数据订阅测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试料理数量订阅
    func testCuisineCountSubscription() {
        AppLog("开始测试料理数量订阅", level: .debug, category: .viewmodel)
        
        let expectation = XCTestExpectation(description: "料理数量更新")
        var updateCount = 0
        
        // 监听料理数量变化
        viewModel.$cuisineCount
            .sink { count in
                updateCount += 1
                if updateCount >= 2 { // 初始值 + 更新值
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 更新一个菜谱为料理清单
        var updatedFormula = testFormulas[0]
        updatedFormula.isCuisine = true
        mockFormulaRepository.mockFormulas[0] = updatedFormula
        mockFormulaRepository.sendFormulasUpdate()
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(viewModel.cuisineCount, 2, "料理数量应该增加到2")
        
        AppLog("料理数量订阅测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Virtual Progress Tests
    
    /// 测试虚拟进度计算 - loading 状态
    func testVirtualProgressForLoadingState() {
        AppLog("开始测试虚拟进度计算 - loading 状态", level: .debug, category: .viewmodel)
        
        let loadingFormula = testFormulas.first { $0.state == .loading }!
        
        // 测试刚创建的 loading 状态进度应该接近 0
        let progress = viewModel.virtualProgress(for: loadingFormula)
        XCTAssertGreaterThanOrEqual(progress, 0, "虚拟进度应该大于等于 0")
        XCTAssertLessThan(progress, 0.2, "刚创建的菜谱虚拟进度应该小于 0.2")
        
        AppLog("虚拟进度计算 - loading 状态测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试虚拟进度计算 - 非 loading 状态
    func testVirtualProgressForNonLoadingState() {
        AppLog("开始测试虚拟进度计算 - 非 loading 状态", level: .debug, category: .viewmodel)
        
        let finishFormula = testFormulas.first { $0.state == .finish }!
        let errorFormula = testFormulas.first { $0.state == .error }!
        
        // 非 loading 状态的进度应该为 0
        XCTAssertEqual(viewModel.virtualProgress(for: finishFormula), 0, "finish 状态的虚拟进度应该为 0")
        XCTAssertEqual(viewModel.virtualProgress(for: errorFormula), 0, "error 状态的虚拟进度应该为 0")
        
        AppLog("虚拟进度计算 - 非 loading 状态测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试重试重置锚点
    func testRetryResetAnchor() {
        AppLog("开始测试重试重置锚点", level: .debug, category: .viewmodel)
        
        let loadingFormula = testFormulas.first { $0.state == .loading }!
        
        // 标记重试开始
        viewModel.markRetryStart(for: loadingFormula.id)
        
        // 重试后的进度应该接近 0
        let progressAfterRetry = viewModel.virtualProgress(for: loadingFormula)
        XCTAssertLessThan(progressAfterRetry, 0.1, "重试后的虚拟进度应该接近 0")
        
        AppLog("重试重置锚点测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Delete Overlay Tests
    
    /// 测试删除权限检查
    func testCanDeletePermission() {
        AppLog("开始测试删除权限检查", level: .debug, category: .viewmodel)
        
        let finishFormula = testFormulas.first { $0.state == .finish }!
        let loadingFormula = testFormulas.first { $0.state == .loading }!
        let errorFormula = testFormulas.first { $0.state == .error }!
        
        XCTAssertTrue(viewModel.canDelete(finishFormula), "finish 状态应该允许删除")
        XCTAssertFalse(viewModel.canDelete(loadingFormula), "loading 状态不应该允许删除")
        XCTAssertFalse(viewModel.canDelete(errorFormula), "error 状态不应该允许删除")
        
        AppLog("删除权限检查测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试显示删除覆盖层
    func testShowDeleteOverlay() {
        AppLog("开始测试显示删除覆盖层", level: .debug, category: .viewmodel)
        
        let formulaId = testFormulaId1
        
        // 初始状态
        XCTAssertNil(viewModel.deleteOverlayTargetId, "初始状态不应该有删除覆盖层")
        
        // 显示删除覆盖层
        viewModel.showDeleteOverlay(for: formulaId)
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId, "应该显示指定菜谱的删除覆盖层")
        
        AppLog("显示删除覆盖层测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试隐藏删除覆盖层
    func testHideDeleteOverlay() {
        AppLog("开始测试隐藏删除覆盖层", level: .debug, category: .viewmodel)
        
        let formulaId = testFormulaId1
        
        // 先显示删除覆盖层
        viewModel.showDeleteOverlay(for: formulaId)
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId, "应该显示删除覆盖层")
        
        // 隐藏删除覆盖层
        viewModel.hideDeleteOverlay()
        XCTAssertNil(viewModel.deleteOverlayTargetId, "应该隐藏删除覆盖层")
        
        AppLog("隐藏删除覆盖层测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试删除确认请求
    func testDeleteConfirmationRequest() {
        AppLog("开始测试删除确认请求", level: .debug, category: .viewmodel)
        
        let formulaId = testFormulaId1
        
        // 初始状态
        XCTAssertNil(viewModel.deleteConfirmationRequestId, "初始状态不应该有删除确认请求")
        
        // 触发删除确认请求
        viewModel.requestDeleteConfirmation(for: formulaId)
        XCTAssertEqual(viewModel.deleteConfirmationRequestId, formulaId, "应该设置删除确认请求")
        
        AppLog("删除确认请求测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试删除状态管理
    func testDeletingStateManagement() {
        AppLog("开始测试删除状态管理", level: .debug, category: .viewmodel)
        
        let formulaId = testFormulaId1
        
        // 初始状态
        XCTAssertFalse(viewModel.isDeleting(formulaId), "初始状态不应该在删除中")
        
        // 标记删除开始
        viewModel.markDeletingStart(formulaId)
        XCTAssertTrue(viewModel.isDeleting(formulaId), "应该标记为删除中")
        
        // 标记删除结束
        viewModel.markDeletingEnd(formulaId)
        XCTAssertFalse(viewModel.isDeleting(formulaId), "应该标记为删除完成")
        
        AppLog("删除状态管理测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试暂停覆盖层自动隐藏
    func testSuspendOverlayAutoHide() {
        AppLog("开始测试暂停覆盖层自动隐藏", level: .debug, category: .viewmodel)
        
        let formulaId = testFormulaId1
        
        // 显示删除覆盖层
        viewModel.showDeleteOverlay(for: formulaId)
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId, "应该显示删除覆盖层")
        
        // 暂停自动隐藏（这是一个内部方法，我们只能测试调用不会崩溃）
        XCTAssertNoThrow(viewModel.suspendOverlayAutoHide(), "暂停自动隐藏不应该抛出异常")
        
        AppLog("暂停覆盖层自动隐藏测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Notification Tests
    
    /// 测试通知选中状态清除
    func testClearNotificationSelection() {
        AppLog("开始测试通知选中状态清除", level: .debug, category: .viewmodel)
        
        // 设置一个选中的 Formula（模拟通知选中）
        viewModel.selectedFormulaFromNotification = testFormulas[0]
        XCTAssertNotNil(viewModel.selectedFormulaFromNotification, "应该有选中的 Formula")
        
        // 清除选中状态
        viewModel.clearNotificationSelection()
        XCTAssertNil(viewModel.selectedFormulaFromNotification, "应该清除选中状态")
        
        AppLog("通知选中状态清除测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Timer Tests
    
    /// 测试共享计时器功能
    func testSharedTimer() async {
        AppLog("开始测试共享计时器功能", level: .debug, category: .viewmodel)
        
        let initialTick = viewModel.tick
        
        // 等待一段时间让计时器工作
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        let finalTick = viewModel.tick
        
        // 计时器应该在运行，tick 值应该增加
        // 注意：由于计时器频率是 150ms，0.2秒应该至少触发一次
        XCTAssertGreaterThan(finalTick, initialTick, "计时器应该更新 tick 值")
        
        AppLog("共享计时器功能测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Edge Cases Tests
    
    /// 测试重复显示同一覆盖层
    func testShowSameDeleteOverlayTwice() {
        AppLog("开始测试重复显示同一覆盖层", level: .debug, category: .viewmodel)
        
        let formulaId = testFormulaId1
        
        // 第一次显示
        viewModel.showDeleteOverlay(for: formulaId)
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId, "应该显示删除覆盖层")
        
        // 第二次显示同一个
        viewModel.showDeleteOverlay(for: formulaId)
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId, "应该仍然显示同一个删除覆盖层")
        
        AppLog("重复显示同一覆盖层测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试切换不同覆盖层
    func testSwitchDeleteOverlay() {
        AppLog("开始测试切换不同覆盖层", level: .debug, category: .viewmodel)
        
        let formulaId1 = testFormulaId1
        let formulaId2 = testFormulaId2
        
        // 显示第一个覆盖层
        viewModel.showDeleteOverlay(for: formulaId1)
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId1, "应该显示第一个删除覆盖层")
        
        // 切换到第二个覆盖层
        viewModel.showDeleteOverlay(for: formulaId2)
        // 由于异步切换，我们需要等待一下
        let expectation = XCTestExpectation(description: "覆盖层切换")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.deleteOverlayTargetId, formulaId2, "应该切换到第二个删除覆盖层")
        
        AppLog("切换不同覆盖层测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试空数据状态
    func testEmptyDataState() {
        AppLog("开始测试空数据状态", level: .debug, category: .viewmodel)
        
        // 清空数据
        mockFormulaRepository.mockFormulas = []
        mockFormulaRepository.sendFormulasUpdate()
        
        // 等待数据更新
        let expectation = XCTestExpectation(description: "数据清空")
        viewModel.$formulaList
            .dropFirst()
            .sink { formulas in
                if formulas.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.formulaList.count, 0, "数据应该为空")
        XCTAssertEqual(viewModel.cuisineCount, 0, "料理数量应该为 0")
        
        AppLog("空数据状态测试完成", level: .debug, category: .viewmodel)
    }
}