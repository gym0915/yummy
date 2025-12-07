//
//  CuisineStateRepositoryTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/11.
//

import XCTest
import Foundation
import Combine
@testable import yummy

final class CuisineStateRepositoryTests: XCTestCase {
    
    var repository: CuisineStateRepository!
    var cancellables: Set<AnyCancellable>!
    var testUserDefaults: UserDefaults!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 使用测试专用的 UserDefaults
        testUserDefaults = UserDefaults(suiteName: "CuisineStateRepositoryTests")!
        
        repository = CuisineStateRepository.shared
        cancellables = Set<AnyCancellable>()
        
        AppLog("🧹 [测试环境] CuisineStateRepositoryTests 准备就绪", level: .debug, category: .coredata)
    }
    
    override func tearDownWithError() throws {
        // 清理测试数据
        cleanupTestUserDefaults()
        
        cancellables = nil
        repository = nil
        testUserDefaults = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 基础访问测试
    
    func testRepositoryAccess() throws {
        // 测试单例访问
        XCTAssertNotNil(repository)
        XCTAssertTrue(repository === CuisineStateRepository.shared, "应该返回同一个单例实例")
        AppLog("✅ CuisineStateRepository单例访问测试通过", level: .debug, category: .coredata)
    }
    
    func testInitialState() throws {
        // 测试初始状态
        var receivedStatuses: [CuisineTabStatus] = []
        
        repository.cuisineTabStatusesPublisher
            .sink { statuses in
                receivedStatuses = statuses
            }
            .store(in: &cancellables)
        
        XCTAssertNotNil(receivedStatuses, "应该返回非nil的数组")
        XCTAssertTrue(receivedStatuses.count >= 0, "应该返回CuisineTabStatus数组类型")
        AppLog("✅ 初始状态测试通过，当前状态数量: \(receivedStatuses.count)", level: .debug, category: .coredata)
    }
    
    // MARK: - UserDefaults 存储测试
    
    func testSaveTabStatus() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "保存Tab状态")
        
        let testFormula = createTestFormula(name: "测试菜谱-保存状态", id: "test-save-status-\(UUID().uuidString)")
        let testStatus = CuisineTabStatus.createProcurementTab(from: testFormula)
        
        // 保存操作
        try await repository.save(testStatus)
        
        // 等待保存操作完成
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        
        // 验证保存结果
        let retrievedStatus = repository.getTabStatus(formulaId: testFormula.id, tab: .procurement)
        XCTAssertNotNil(retrievedStatus, "应该能找到保存的状态")
        XCTAssertEqual(retrievedStatus?.formulaId, testFormula.id, "Formula ID应该匹配")
        XCTAssertEqual(retrievedStatus?.tabType, .procurement, "Tab类型应该匹配")
        XCTAssertEqual(retrievedStatus?.formulaName, testFormula.name, "菜谱名称应该匹配")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 保存Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    func testUpdateExistingTabStatus() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "更新已存在的Tab状态")
        
        // 1. 先保存一个状态
        let testFormula = createTestFormula(name: "测试菜谱-更新状态", id: "test-update-status-\(UUID().uuidString)")
        var originalStatus = CuisineTabStatus.createProcurementTab(from: testFormula)
        try await repository.save(originalStatus)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 2. 修改状态中的项目完成情况
        if !originalStatus.items.isEmpty {
            originalStatus.toggleItemCompletion(itemId: originalStatus.items[0].id)
        }
        
        // 3. 更新状态
        try await repository.save(originalStatus)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 4. 验证更新结果
        let retrievedStatus = repository.getTabStatus(formulaId: testFormula.id, tab: .procurement)
        XCTAssertNotNil(retrievedStatus, "应该能找到更新的状态")
        if !originalStatus.items.isEmpty {
            XCTAssertTrue(retrievedStatus?.items[0].isCompleted ?? false, "第一个项目应该被标记为完成")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 更新已存在的Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    func testDeleteTabStatuses() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "删除Tab状态")
        
        // 1. 先保存一些状态
        let testFormula = createTestFormula(name: "测试菜谱-删除状态", id: "test-delete-status-\(UUID().uuidString)")
        try await repository.createTabStatuses(from: testFormula)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // 2. 确认存在
        let beforeDelete = repository.getTabStatus(formulaId: testFormula.id, tab: .procurement)
        XCTAssertNotNil(beforeDelete, "删除前应该能找到状态")
        
        // 3. 执行删除
        try await repository.deleteTabStatuses(formulaId: testFormula.id)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 4. 验证删除结果
        let afterDelete = repository.getTabStatus(formulaId: testFormula.id, tab: .procurement)
        XCTAssertNil(afterDelete, "删除后应该找不到状态")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 删除Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - Tab状态创建测试
    
    func testCreateProcurementTabStatus() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "创建采购Tab状态")
        
        let testFormula = createTestFormula(name: "测试菜谱-采购Tab", id: "test-procurement-\(UUID().uuidString)")
        
        try await repository.createTabStatus(from: testFormula, tabType: .procurement)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let status = repository.getTabStatus(formulaId: testFormula.id, tab: .procurement)
        XCTAssertNotNil(status, "应该能创建采购Tab状态")
        XCTAssertEqual(status?.tabType, .procurement, "Tab类型应该是采购")
        XCTAssertTrue(status?.items.count ?? 0 > 0, "应该包含采购项目")
        
        // 验证采购项目内容
        if let items = status?.items {
            let ingredientItems = items.filter { $0.type == .ingredient }
            XCTAssertTrue(ingredientItems.count > 0, "应该包含食材项目")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 创建采购Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    func testCreatePreparationTabStatus() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "创建备菜Tab状态")
        
        let testFormula = createTestFormula(name: "测试菜谱-备菜Tab", id: "test-preparation-\(UUID().uuidString)")
        
        try await repository.createTabStatus(from: testFormula, tabType: .prepare)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let status = repository.getTabStatus(formulaId: testFormula.id, tab: .prepare)
        XCTAssertNotNil(status, "应该能创建备菜Tab状态")
        XCTAssertEqual(status?.tabType, .prepare, "Tab类型应该是备菜")
        XCTAssertTrue(status?.items.count ?? 0 > 0, "应该包含备菜项目")
        
        // 验证备菜项目内容
        if let items = status?.items {
            let preparationItems = items.filter { $0.type == .preparationStep }
            XCTAssertTrue(preparationItems.count > 0, "应该包含准备步骤项目")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 创建备菜Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    func testCreateCuisineTabStatus() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "创建料理Tab状态")
        
        let testFormula = createTestFormula(name: "测试菜谱-料理Tab", id: "test-cuisine-\(UUID().uuidString)")
        
        try await repository.createTabStatus(from: testFormula, tabType: .cuisine)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let status = repository.getTabStatus(formulaId: testFormula.id, tab: .cuisine)
        XCTAssertNotNil(status, "应该能创建料理Tab状态")
        XCTAssertEqual(status?.tabType, .cuisine, "Tab类型应该是料理")
        XCTAssertTrue(status?.items.count ?? 0 > 0, "应该包含料理项目")
        
        // 验证料理项目内容
        if let items = status?.items {
            let cuisineItems = items.filter { $0.type == .preparationStep }
            XCTAssertTrue(cuisineItems.count > 0, "应该包含料理步骤项目")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 创建料理Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - Publisher机制测试
    
    func testPublisherUpdates() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "Publisher更新通知")
        var receivedStatuses: [[CuisineTabStatus]] = []
        
        // 订阅Publisher
        repository.cuisineTabStatusesPublisher
            .sink { statuses in
                receivedStatuses.append(statuses)
                if receivedStatuses.count >= 2 { // 初始状态 + 保存后的状态
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 等待一下初始状态
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // 保存一个新的状态，应该触发Publisher更新
        let testFormula = createTestFormula(name: "测试菜谱-Publisher", id: "test-publisher-\(UUID().uuidString)")
        let testStatus = CuisineTabStatus.createProcurementTab(from: testFormula)
        try await repository.save(testStatus)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertGreaterThanOrEqual(receivedStatuses.count, 2, "应该至少收到2次更新")
        
        AppLog("✅ Publisher更新通知测试通过，收到 \(receivedStatuses.count) 次更新", level: .debug, category: .coredata)
    }
    
    // MARK: - 状态计算测试
    
    func testTabStatusProgressCalculation() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "Tab状态进度计算")
        
        let testFormula = createTestFormula(name: "测试菜谱-进度计算", id: "test-progress-\(UUID().uuidString)")
        var testStatus = CuisineTabStatus.createProcurementTab(from: testFormula)
        
        // 初始进度应该是0%
        XCTAssertEqual(testStatus.progress, 0.0, "初始进度应该是0%")
        XCTAssertEqual(testStatus.completedCount, 0, "初始完成数量应该是0")
        
        // 完成一个项目
        if !testStatus.items.isEmpty {
            testStatus.toggleItemCompletion(itemId: testStatus.items[0].id)
            
            let expectedProgress = 1.0 / Double(testStatus.items.count)
            XCTAssertEqual(testStatus.progress, expectedProgress, accuracy: 0.01, "进度应该正确计算")
            XCTAssertEqual(testStatus.completedCount, 1, "完成数量应该是1")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ Tab状态进度计算测试通过", level: .debug, category: .coredata)
    }
    
    func testTabStatusSortedItems() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "Tab状态项目排序")
        
        let testFormula = createTestFormula(name: "测试菜谱-项目排序", id: "test-sorting-\(UUID().uuidString)")
        var testStatus = CuisineTabStatus.createProcurementTab(from: testFormula)
        
        // 完成一些项目（不是连续的）
        if testStatus.items.count >= 3 {
            testStatus.toggleItemCompletion(itemId: testStatus.items[0].id)
            try await Task.sleep(nanoseconds: 10_000_000) // 确保时间戳不同
            testStatus.toggleItemCompletion(itemId: testStatus.items[2].id)
            
            let sortedItems = testStatus.sortedItems
            
            // 验证排序逻辑：未完成的在前，已完成的在后
            let completedItems = sortedItems.filter { $0.isCompleted }
            let uncompletedItems = sortedItems.filter { !$0.isCompleted }
            
            XCTAssertEqual(completedItems.count, 2, "应该有2个已完成项目")
            XCTAssertEqual(uncompletedItems.count, testStatus.items.count - 2, "剩余应该是未完成项目")
            
            // 验证已完成项目在数组末尾
            let lastTwo = Array(sortedItems.suffix(2))
            XCTAssertTrue(lastTwo.allSatisfy { $0.isCompleted }, "最后两个项目应该都是已完成的")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ Tab状态项目排序测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - 多Tab状态管理测试
    
    func testCreateMultipleTabStatuses() async throws {
        await cleanupRepositoryData()
        
        let expectation = XCTestExpectation(description: "创建多个Tab状态")
        
        let testFormula = createTestFormula(name: "测试菜谱-多Tab", id: "test-multi-tabs-\(UUID().uuidString)")
        
        // 创建所有类型的Tab状态
        try await repository.createTabStatuses(from: testFormula)
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // 验证每个Tab都被创建
        let procurementStatus = repository.getTabStatus(formulaId: testFormula.id, tab: .procurement)
        let preparationStatus = repository.getTabStatus(formulaId: testFormula.id, tab: .prepare)
        
        XCTAssertNotNil(procurementStatus, "应该创建采购Tab状态")
        XCTAssertNotNil(preparationStatus, "应该创建备菜Tab状态")
        
        XCTAssertEqual(procurementStatus?.tabType, .procurement, "采购Tab类型应该正确")
        XCTAssertEqual(preparationStatus?.tabType, .prepare, "备菜Tab类型应该正确")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 创建多个Tab状态测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - 辅助方法
    
    /// 清理Repository中的测试数据
    private func cleanupRepositoryData() async {
        // 获取当前所有状态
        var currentStatuses: [CuisineTabStatus] = []
        
        repository.cuisineTabStatusesPublisher
            .sink { statuses in
                currentStatuses = statuses
            }
            .store(in: &cancellables)
        
        // 删除所有测试相关的状态
        for status in currentStatuses {
            if status.formulaName.contains("测试菜谱") {
                try? await repository.deleteTabStatuses(formulaId: status.formulaId)
            }
        }
        
        try? await Task.sleep(nanoseconds: 200_000_000) // 等待清理完成
        AppLog("🧹 [测试环境] Repository数据清理完成", level: .debug, category: .coredata)
    }
    
    /// 清理测试用的UserDefaults
    private func cleanupTestUserDefaults() {
        let key = "cuisine_tab_statuses"
        testUserDefaults.removeObject(forKey: key)
        AppLog("🧹 [测试环境] UserDefaults清理完成", level: .debug, category: .coredata)
    }
    
    private func createTestFormula(name: String, id: String) -> Formula {
        var formula = Formula(
            name: name,
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "测试主料1", quantity: "200克", category: "蔬菜类"),
                    Ingredient(name: "测试主料2", quantity: "300克", category: "肉类")
                ],
                spicesSeasonings: [
                    Ingredient(name: "盐", quantity: "适量", category: nil),
                    Ingredient(name: "生抽", quantity: "2勺", category: nil),
                    Ingredient(name: "料酒", quantity: "1勺", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "蒜蓉酱", quantity: "1勺"),
                    SauceIngredient(name: "香油", quantity: "几滴")
                ]
            ),
            tools: [
                Tool(name: "炒锅"),
                Tool(name: "铲子"),
                Tool(name: "切菜板")
            ],
            preparation: [
                PreparationStep(step: "清洗食材", details: "将所有蔬菜清洗干净"),
                PreparationStep(step: "切配食材", details: "将食材切成合适大小"),
                PreparationStep(step: "准备调料", details: "调好所需的调味料")
            ],
            steps: [
                CookingStep(step: "热锅下油", details: "大火热锅，倒入适量油"),
                CookingStep(step: "爆炒食材", details: "下入食材快速翻炒"),
                CookingStep(step: "调味出锅", details: "加入调料炒匀即可出锅")
            ],
            tips: ["注意火候控制", "及时调味", "保持食材新鲜"],
            tags: ["测试", "家常菜", "快手菜"],
            date: Date(),
            prompt: "这是一个测试用的菜谱，用于验证CuisineStateRepository功能",
            state: .finish,
            imgpath: nil,
            isCuisine: true
        )
        
        formula.id = id
        return formula
    }
}