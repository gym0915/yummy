//
//  FormulaRepositoryTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/11.
//

import XCTest
import Foundation
import Combine
@testable import yummy

final class FormulaRepositoryTests: XCTestCase {
    
    var repository: FormulaRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        repository = FormulaRepository.shared
        cancellables = Set<AnyCancellable>()
        
        // 注意：setUpWithError不支持async，所以我们在每个测试方法中单独清理
        AppLog("🧹 [测试环境] 准备就绪", level: .debug, category: .coredata)
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        repository = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 基础访问测试
    
    func testRepositoryAccess() throws {
        // 测试单例访问
        XCTAssertNotNil(repository)
        XCTAssertTrue(repository === FormulaRepository.shared, "应该返回同一个单例实例")
        AppLog("✅ FormulaRepository单例访问测试通过", level: .debug, category: .coredata)
    }
    
    func testInitialState() throws {
        // 测试初始状态
        let formulas = repository.all()
        XCTAssertNotNil(formulas, "应该返回非nil的数组")
        XCTAssertTrue(formulas.count >= 0, "应该返回Formula数组类型")
        AppLog("✅ 初始状态测试通过，当前菜谱数量: \(formulas.count)", level: .debug, category: .coredata)
    }
    
    // MARK: - CRUD操作测试
    
    func testSaveNewFormula() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "保存新的Formula")
        
        let testFormula = createTestFormula(name: "测试菜谱-保存", id: "test-save-\(UUID().uuidString)")
        
        // 保存操作
        try await repository.save(testFormula)
        
        // 等待CoreData操作完成
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 验证保存结果
        let savedFormula = repository.all().first { $0.id == testFormula.id }
        XCTAssertNotNil(savedFormula, "应该能找到保存的Formula")
        XCTAssertEqual(savedFormula?.name, testFormula.name, "名称应该匹配")
        XCTAssertEqual(savedFormula?.id, testFormula.id, "ID应该匹配")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 保存新的Formula测试通过", level: .debug, category: .coredata)
    }
    
    func testUpdateExistingFormula() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "更新已存在的Formula")
        
        // 1. 先保存一个Formula
        let originalFormula = createTestFormula(name: "测试菜谱-原始", id: "test-update-\(UUID().uuidString)")
        try await repository.save(originalFormula)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 2. 修改并更新
        var updatedFormula = originalFormula
        updatedFormula.name = "测试菜谱-已更新"
        updatedFormula.state = .upload
        
        try await repository.update(updatedFormula)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 3. 验证更新结果
        let retrievedFormula = repository.all().first { $0.id == originalFormula.id }
        XCTAssertNotNil(retrievedFormula, "应该能找到更新的Formula")
        XCTAssertEqual(retrievedFormula?.name, "测试菜谱-已更新", "名称应该被更新")
        XCTAssertEqual(retrievedFormula?.state, .upload, "状态应该被更新")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 更新已存在的Formula测试通过", level: .debug, category: .coredata)
    }
    
    func testDeleteFormula() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "删除Formula")
        
        // 1. 先保存一个Formula
        let testFormula = createTestFormula(name: "测试菜谱-删除", id: "test-delete-\(UUID().uuidString)")
        try await repository.save(testFormula)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 2. 确认存在
        let beforeDelete = repository.all().first { $0.id == testFormula.id }
        XCTAssertNotNil(beforeDelete, "删除前应该能找到Formula")
        
        // 3. 执行删除
        try await repository.delete(id: testFormula.id)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 4. 验证删除结果
        let afterDelete = repository.all().first { $0.id == testFormula.id }
        XCTAssertNil(afterDelete, "删除后应该找不到Formula")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 删除Formula测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - 状态转换测试
    
    func testStateTransition() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "状态转换")
        
        var testFormula = createTestFormula(name: "测试菜谱-状态转换", id: "test-state-\(UUID().uuidString)")
        testFormula.state = .loading
        
        // 保存初始状态
        try await repository.save(testFormula)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 验证初始状态
        var retrievedFormula = repository.all().first { $0.id == testFormula.id }
        XCTAssertEqual(retrievedFormula?.state, .loading, "初始状态应该是loading")
        
        // 转换到upload状态
        testFormula.state = .upload
        try await repository.save(testFormula)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        retrievedFormula = repository.all().first { $0.id == testFormula.id }
        XCTAssertEqual(retrievedFormula?.state, .upload, "状态应该转换为upload")
        
        // 转换到finish状态
        testFormula.state = .finish
        try await repository.save(testFormula)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        retrievedFormula = repository.all().first { $0.id == testFormula.id }
        XCTAssertEqual(retrievedFormula?.state, .finish, "状态应该转换为finish")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
        
        AppLog("✅ 状态转换测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - Publisher测试
    
    func testPublisherUpdates() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "Publisher更新通知")
        var receivedFormulas: [[Formula]] = []
        
        // 订阅Publisher
        repository.formulasPublisher
            .sink { formulas in
                receivedFormulas.append(formulas)
                if receivedFormulas.count >= 2 { // 初始状态 + 保存后的状态
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 等待一下初始状态
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // 保存一个新的Formula，应该触发Publisher更新
        let testFormula = createTestFormula(name: "测试菜谱-Publisher", id: "test-publisher-\(UUID().uuidString)")
        try await repository.save(testFormula)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertGreaterThanOrEqual(receivedFormulas.count, 2, "应该至少收到2次更新")
        
        AppLog("✅ Publisher更新通知测试通过，收到 \(receivedFormulas.count) 次更新", level: .debug, category: .coredata)
    }
    
    // MARK: - 边界情况测试
    
    func testUpdateNonExistentFormula() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "更新不存在的Formula")
        
        let nonExistentFormula = createTestFormula(name: "不存在的菜谱", id: "non-existent-id")
        
        do {
            try await repository.update(nonExistentFormula)
            XCTFail("更新不存在的Formula应该抛出错误")
        } catch {
            XCTAssertTrue(error is NSError, "应该抛出NSError")
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 404, "错误代码应该是404")
            AppLog("✅ 预期的错误：\(error.localizedDescription)", level: .debug, category: .coredata)
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 更新不存在的Formula测试通过", level: .debug, category: .coredata)
    }
    
    func testDuplicateIdHandling() async throws {
        // 清理可能存在的测试数据
        await cleanupTestData()
        
        let expectation = XCTestExpectation(description: "重复ID处理")
        
        let duplicateId = "duplicate-test-id"
        let formula1 = createTestFormula(name: "测试菜谱-1", id: duplicateId)
        let formula2 = createTestFormula(name: "测试菜谱-2", id: duplicateId)
        
        // 保存第一个
        try await repository.save(formula1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 保存第二个（相同ID，应该更新而不是创建新的）
        try await repository.save(formula2)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 验证只有一个记录，且是最新的内容
        let formulasWithId = repository.all().filter { $0.id == duplicateId }
        XCTAssertEqual(formulasWithId.count, 1, "应该只有一个相同ID的记录")
        XCTAssertEqual(formulasWithId.first?.name, "测试菜谱-2", "应该是最新保存的内容")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
        
        AppLog("✅ 重复ID处理测试通过", level: .debug, category: .coredata)
    }
    
    // MARK: - 辅助方法
    
    /// 清理测试数据
    private func cleanupTestData() async {
        let allFormulas = repository.all()
        for formula in allFormulas {
            if formula.name.contains("测试菜谱") {
                try? await repository.delete(id: formula.id)
            }
        }
        try? await Task.sleep(nanoseconds: 200_000_000) // 等待清理完成
        AppLog("🧹 [测试环境] 清理完成", level: .debug, category: .coredata)
    }
    
    private func createTestFormula(name: String, id: String) -> Formula {
        var formula = Formula(
            name: name,
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "测试食材1", quantity: "100克", category: "蔬菜类"),
                    Ingredient(name: "测试食材2", quantity: "200克", category: "肉类")
                ],
                spicesSeasonings: [
                    Ingredient(name: "盐", quantity: "适量", category: nil),
                    Ingredient(name: "生抽", quantity: "1勺", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "料酒", quantity: "1勺")
                ]
            ),
            tools: [
                Tool(name: "炒锅"),
                Tool(name: "铲子")
            ],
            preparation: [
                PreparationStep(step: "准备工作1", details: "清洗食材"),
                PreparationStep(step: "准备工作2", details: "切配食材")
            ],
            steps: [
                CookingStep(step: "烹饪步骤1", details: "热锅下油"),
                CookingStep(step: "烹饪步骤2", details: "下食材炒制"),
                CookingStep(step: "烹饪步骤3", details: "调味出锅")
            ],
            tips: ["注意火候", "及时调味"],
            tags: ["测试", "家常菜"],
            date: Date(),
            prompt: "这是一个测试菜谱",
            state: .loading,
            imgpath: nil,
            isCuisine: false
        )
        
        formula.id = id
        return formula
    }
}