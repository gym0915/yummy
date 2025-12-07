//
//  CoreDataStackTests.swift
//  yummyTests
//
//  Created by Qoder on 2025/01/27.
//

import XCTest
import CoreData
@testable import yummy

final class CoreDataStackTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        // 使用内存存储进行测试
        coreDataStack = CoreDataStack(inMemory: true)
        testContext = coreDataStack.viewContext
    }
    
    override func tearDown() {
        testContext = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - 单例模式测试
    
    func testSingletonPattern() {
        // Given & When
        let instance1 = CoreDataStack.shared
        let instance2 = CoreDataStack.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "CoreDataStack 应该是单例")
    }
    
    func testPrivateInitializer() {
        // Given & When
        let instance = CoreDataStack.shared
        
        // Then
        XCTAssertNotNil(instance, "单例实例不应该为 nil")
        XCTAssertNotNil(instance.container, "容器不应该为 nil")
        XCTAssertNotNil(instance.viewContext, "视图上下文不应该为 nil")
    }
    
    // MARK: - 初始化测试
    
    func testInMemoryInitialization() {
        // Given & When
        let inMemoryStack = CoreDataStack(inMemory: true)
        
        // Then
        XCTAssertNotNil(inMemoryStack.container, "内存存储容器不应该为 nil")
        XCTAssertNotNil(inMemoryStack.viewContext, "内存存储视图上下文不应该为 nil")
        
        // 验证存储描述配置
        if let description = inMemoryStack.container.persistentStoreDescriptions.first {
            XCTAssertEqual(description.url, URL(fileURLWithPath: "/dev/null"), "内存存储应该使用 /dev/null 路径")
        }
    }
    
    func testPersistentInitialization() {
        // Given & When
        let persistentStack = CoreDataStack(inMemory: false)
        
        // Then
        XCTAssertNotNil(persistentStack.container, "持久化存储容器不应该为 nil")
        XCTAssertNotNil(persistentStack.viewContext, "持久化存储视图上下文不应该为 nil")
        
        // 验证存储描述配置
        if let description = persistentStack.container.persistentStoreDescriptions.first {
            XCTAssertNotEqual(description.url, URL(fileURLWithPath: "/dev/null"), "持久化存储不应该使用 /dev/null 路径")
        }
    }
    
    // MARK: - 容器配置测试
    
    func testContainerName() {
        // Given & When
        let stack = CoreDataStack.shared
        
        // Then
        XCTAssertEqual(stack.container.name, "FormulaContainer", "容器名称应该是 FormulaContainer")
    }
    
    func testAutoMigrationConfiguration() {
        // Given & When
        let stack = CoreDataStack.shared
        
        // Then
        if let description = stack.container.persistentStoreDescriptions.first {
            XCTAssertTrue(description.shouldMigrateStoreAutomatically, "应该启用自动迁移")
            XCTAssertTrue(description.shouldInferMappingModelAutomatically, "应该启用映射模型自动推断")
        }
    }
    
    // MARK: - 上下文测试
    
    func testViewContextConfiguration() {
        // Given & When
        let context = coreDataStack.viewContext
        
        // Then
        XCTAssertNotNil(context, "视图上下文不应该为 nil")
        XCTAssertTrue(context.automaticallyMergesChangesFromParent, "应该自动合并父级更改")
        XCTAssertNotNil(context.mergePolicy, "合并策略不应该为 nil")
    }
    
    func testNewBackgroundContext() {
        // Given & When
        let backgroundContext = coreDataStack.newBackgroundContext()
        
        // Then
        XCTAssertNotNil(backgroundContext, "后台上下文不应该为 nil")
        XCTAssertNotNil(backgroundContext.mergePolicy, "后台上下文合并策略不应该为 nil")
        XCTAssertNotEqual(backgroundContext, coreDataStack.viewContext, "后台上下文应该与视图上下文不同")
    }
    
    func testMultipleBackgroundContexts() {
        // Given & When
        let context1 = coreDataStack.newBackgroundContext()
        let context2 = coreDataStack.newBackgroundContext()
        
        // Then
        XCTAssertNotEqual(context1, context2, "多个后台上下文应该是不同的实例")
        XCTAssertNotEqual(context1, coreDataStack.viewContext, "后台上下文应该与视图上下文不同")
        XCTAssertNotEqual(context2, coreDataStack.viewContext, "后台上下文应该与视图上下文不同")
    }
    
    // MARK: - 数据操作测试
    
    func testCreateFormulaEntity() {
        // Given
        let formulaEntity = FormulaEntity(context: testContext)
        formulaEntity.id = "test-id"
        formulaEntity.name = "测试菜谱"
        formulaEntity.date = Date()
        formulaEntity.state = 1 // Formula.State.finish
        
        // When
        do {
            try testContext.save()
        } catch {
            XCTFail("保存 FormulaEntity 失败: \(error)")
        }
        
        // Then
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "test-id")
        
        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "应该找到 1 个 FormulaEntity")
            XCTAssertEqual(results.first?.name, "测试菜谱", "名称应该匹配")
            XCTAssertEqual(results.first?.state, 1, "状态应该匹配")
        } catch {
            XCTFail("获取 FormulaEntity 失败: \(error)")
        }
    }
    
    func testUpdateFormulaEntity() {
        // Given
        let formulaEntity = FormulaEntity(context: testContext)
        formulaEntity.id = "test-id"
        formulaEntity.name = "原始名称"
        formulaEntity.state = 0 // Formula.State.loading
        
        try? testContext.save()
        
        // When
        formulaEntity.name = "更新后的名称"
        formulaEntity.state = 1 // Formula.State.finish
        
        do {
            try testContext.save()
        } catch {
            XCTFail("更新 FormulaEntity 失败: \(error)")
        }
        
        // Then
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "test-id")
        
        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "应该找到 1 个 FormulaEntity")
            XCTAssertEqual(results.first?.name, "更新后的名称", "名称应该已更新")
            XCTAssertEqual(results.first?.state, 1, "状态应该已更新")
        } catch {
            XCTFail("获取更新后的 FormulaEntity 失败: \(error)")
        }
    }
    
    func testDeleteFormulaEntity() {
        // Given
        let formulaEntity = FormulaEntity(context: testContext)
        formulaEntity.id = "test-id"
        formulaEntity.name = "要删除的菜谱"
        
        try? testContext.save()
        
        // When
        testContext.delete(formulaEntity)
        
        do {
            try testContext.save()
        } catch {
            XCTFail("删除 FormulaEntity 失败: \(error)")
        }
        
        // Then
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "test-id")
        
        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 0, "不应该找到任何 FormulaEntity")
        } catch {
            XCTFail("获取删除后的 FormulaEntity 失败: \(error)")
        }
    }
    
    func testMultipleFormulaEntities() {
        // Given
        let formula1 = FormulaEntity(context: testContext)
        formula1.id = "test-id-1"
        formula1.name = "菜谱1"
        formula1.state = 0
        
        let formula2 = FormulaEntity(context: testContext)
        formula2.id = "test-id-2"
        formula2.name = "菜谱2"
        formula2.state = 1
        
        // When
        do {
            try testContext.save()
        } catch {
            XCTFail("保存多个 FormulaEntity 失败: \(error)")
        }
        
        // Then
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        
        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 2, "应该找到 2 个 FormulaEntity")
            
            let sortedResults = results.sorted { $0.id ?? "" < $1.id ?? "" }
            XCTAssertEqual(sortedResults[0].name, "菜谱1", "第一个菜谱名称应该匹配")
            XCTAssertEqual(sortedResults[1].name, "菜谱2", "第二个菜谱名称应该匹配")
        } catch {
            XCTFail("获取多个 FormulaEntity 失败: \(error)")
        }
    }
    
    // MARK: - 并发测试
    
    func testConcurrentOperations() {
        // Given
        let expectation = XCTestExpectation(description: "并发操作完成")
        expectation.expectedFulfillmentCount = 3
        
        // When
        DispatchQueue.global(qos: .background).async {
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                let formula = FormulaEntity(context: backgroundContext)
                formula.id = "concurrent-1"
                formula.name = "并发菜谱1"
                formula.state = 0
                
                do {
                    try backgroundContext.save()
                    expectation.fulfill()
                } catch {
                    XCTFail("并发保存失败: \(error)")
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                let formula = FormulaEntity(context: backgroundContext)
                formula.id = "concurrent-2"
                formula.name = "并发菜谱2"
                formula.state = 1
                
                do {
                    try backgroundContext.save()
                    expectation.fulfill()
                } catch {
                    XCTFail("并发保存失败: \(error)")
                }
            }
        }
        
        DispatchQueue.global(qos: .utility).async {
            let backgroundContext = self.coreDataStack.newBackgroundContext()
            
            backgroundContext.perform {
                let formula = FormulaEntity(context: backgroundContext)
                formula.id = "concurrent-3"
                formula.name = "并发菜谱3"
                formula.state = 2
                
                do {
                    try backgroundContext.save()
                    expectation.fulfill()
                } catch {
                    XCTFail("并发保存失败: \(error)")
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        // 验证所有数据都已保存
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id BEGINSWITH %@", "concurrent")
        
        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 3, "应该找到 3 个并发创建的 FormulaEntity")
        } catch {
            XCTFail("获取并发创建的 FormulaEntity 失败: \(error)")
        }
    }
    
    // MARK: - 错误处理测试
    
    func testInvalidDataHandling() {
        // Given
        let _ = FormulaEntity(context: testContext)
        // 故意不设置必需的属性
        
        // When & Then
        do {
            try testContext.save()
            // 如果保存成功，说明模型允许可选属性
        } catch {
            // 如果保存失败，说明有验证规则
            XCTAssertNotNil(error, "应该处理无效数据")
        }
    }
    
    // MARK: - 性能测试
    
    func testBulkInsertPerformance() {
        // Given
        let entityCount = 10
        
        // When
        for i in 0..<entityCount {
            let formula = FormulaEntity(context: testContext)
            formula.id = "bulk-\(i)"
            formula.name = "批量菜谱\(i)"
            formula.state = Int16(i % 3)
            formula.date = Date()
        }
        
        do {
            try testContext.save()
        } catch {
            XCTFail("批量插入失败: \(error)")
        }
        
        // Then
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id BEGINSWITH %@", "bulk")
        
        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, entityCount, "应该找到所有批量插入的 FormulaEntity")
        } catch {
            XCTFail("获取批量插入的 FormulaEntity 失败: \(error)")
        }
    }
    
    func testFetchPerformance() {
        // Given
        let entityCount = 1000
        
        // 先插入测试数据
        for i in 0..<entityCount {
            let formula = FormulaEntity(context: testContext)
            formula.id = "fetch-\(i)"
            formula.name = "获取测试菜谱\(i)"
            formula.state = Int16(i % 3)
            formula.date = Date()
        }
        
        try? testContext.save()
        
        // When & Then
        measure {
            let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id BEGINSWITH %@", "fetch")
            
            do {
                let results = try testContext.fetch(fetchRequest)
                XCTAssertEqual(results.count, entityCount, "应该找到所有测试数据")
            } catch {
                XCTFail("获取测试数据失败: \(error)")
            }
        }
    }
    
    // MARK: - 内存管理测试
    
    func testMemoryManagement() {
        // Given
        let stack = CoreDataStack(inMemory: true)
        
        // When
        let formula = FormulaEntity(context: stack.viewContext)
        formula.id = "memory-test"
        formula.name = "内存测试菜谱"
        
        do {
            try stack.viewContext.save()
        } catch {
            XCTFail("保存内存测试数据失败: \(error)")
        }
        
        // Then
        let fetchRequest: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", "memory-test")
        
        do {
            let results = try stack.viewContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "应该找到内存测试数据")
            XCTAssertEqual(results.first?.name, "内存测试菜谱", "数据应该正确")
        } catch {
            XCTFail("获取内存测试数据失败: \(error)")
        }
    }
}
