//
//  FormulaEntityPromptTests.swift
//  yummyTests
//
//  Created by steve on 2025/1/27.
//

import XCTest
import CoreData
@testable import yummy

class FormulaEntityPromptTests: XCTestCase {
    
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 创建内存中的 Core Data 堆栈用于测试
        container = NSPersistentContainer(name: "FormulaContainer")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data 测试堆栈创建失败: \(error)")
            }
        }
        
        context = container.viewContext
    }
    
    override func tearDownWithError() throws {
        container = nil
        context = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 测试数据创建辅助方法
    
    private func createTestFormulaEntity() -> FormulaEntity {
        let entity = FormulaEntity(context: context)
        entity.id = "test-formula-id"
        entity.name = "测试菜谱"
        entity.date = Date()
        entity.state = FormulaState.loading.rawValue
        entity.prompt = "测试提示"
        entity.imgpath = "test-image.jpg"
        entity.isCuisine = true
        
        // 创建测试数据
        let ingredients = Ingredients(
            mainIngredients: [
                Ingredient(name: "主料1", quantity: "100g", category: "肉类"),
                Ingredient(name: "主料2", quantity: "200g", category: "蔬菜")
            ],
            spicesSeasonings: [
                Ingredient(name: "调料1", quantity: "适量", category: nil)
            ],
            sauce: [
                SauceIngredient(name: "蘸料1", quantity: "1勺")
            ]
        )
        
        let tools = [
            Tool(name: "平底锅"),
            Tool(name: "铲子")
        ]
        
        let preparation = [
            PreparationStep(step: "准备1", details: "准备步骤详情1"),
            PreparationStep(step: "准备2", details: "准备步骤详情2")
        ]
        
        let steps = [
            CookingStep(step: "料理1", details: "料理步骤详情1"),
            CookingStep(step: "料理2", details: "料理步骤详情2")
        ]
        
        let tips = ["小贴士1", "小贴士2"]
        let tags = ["标签1", "标签2"]
        
        // 编码数据
        let encoder = JSONEncoder()
        entity.ingredients = try? encoder.encode(ingredients)
        entity.tools = try? encoder.encode(tools)
        entity.preparation = try? encoder.encode(preparation)
        entity.steps = try? encoder.encode(steps)
        entity.tips = try? encoder.encode(tips)
        entity.tags = try? encoder.encode(tags)
        
        return entity
    }
    
    private func createTestFormula() -> Formula {
        return Formula(
            name: "测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "主料1", quantity: "100g", category: "肉类"),
                    Ingredient(name: "主料2", quantity: "200g", category: "蔬菜")
                ],
                spicesSeasonings: [
                    Ingredient(name: "调料1", quantity: "适量", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "蘸料1", quantity: "1勺")
                ]
            ),
            tools: [
                Tool(name: "平底锅"),
                Tool(name: "铲子")
            ],
            preparation: [
                PreparationStep(step: "准备1", details: "准备步骤详情1"),
                PreparationStep(step: "准备2", details: "准备步骤详情2")
            ],
            steps: [
                CookingStep(step: "料理1", details: "料理步骤详情1"),
                CookingStep(step: "料理2", details: "料理步骤详情2")
            ],
            tips: ["小贴士1", "小贴士2"],
            tags: ["标签1", "标签2"],
            date: Date(),
            prompt: "测试提示",
            state: .loading,
            imgpath: "test-image.jpg",
            isCuisine: true
        )
    }
    
    // MARK: - prompt 属性基本功能测试
    
    func testPromptProperty_CanBeSetAndRetrieved() throws {
        // Given
        let entity = FormulaEntity(context: context)
        let testPrompt = "这是一个测试提示"
        
        // When
        entity.prompt = testPrompt
        
        // Then
        XCTAssertEqual(entity.prompt, testPrompt, "prompt 属性应该能够正确设置和获取")
    }
    
    func testPromptProperty_CanBeSetToNil() throws {
        // Given
        let entity = FormulaEntity(context: context)
        entity.prompt = "初始提示"
        
        // When
        entity.prompt = nil
        
        // Then
        XCTAssertNil(entity.prompt, "prompt 属性应该能够设置为 nil")
    }
    
    func testPromptProperty_CanBeSetToEmptyString() throws {
        // Given
        let entity = FormulaEntity(context: context)
        
        // When
        entity.prompt = ""
        
        // Then
        XCTAssertEqual(entity.prompt, "", "prompt 属性应该能够设置为空字符串")
    }
    
    func testPromptProperty_CanBeSetToLongString() throws {
        // Given
        let entity = FormulaEntity(context: context)
        let longPrompt = String(repeating: "这是一个很长的提示内容，", count: 100)
        
        // When
        entity.prompt = longPrompt
        
        // Then
        XCTAssertEqual(entity.prompt, longPrompt, "prompt 属性应该能够设置长字符串")
    }
    
    func testPromptProperty_CanBeSetToSpecialCharacters() throws {
        // Given
        let entity = FormulaEntity(context: context)
        let specialPrompt = "特殊字符测试：!@#$%^&*()_+-=[]{}|;':\",./<>?`~"
        
        // When
        entity.prompt = specialPrompt
        
        // Then
        XCTAssertEqual(entity.prompt, specialPrompt, "prompt 属性应该能够设置特殊字符")
    }
    
    func testPromptProperty_CanBeSetToUnicodeCharacters() throws {
        // Given
        let entity = FormulaEntity(context: context)
        let unicodePrompt = "Unicode测试：中文、日本語、한국어、العربية、Русский、עברית、ไทย、हिन्दी"
        
        // When
        entity.prompt = unicodePrompt
        
        // Then
        XCTAssertEqual(entity.prompt, unicodePrompt, "prompt 属性应该能够设置Unicode字符")
    }
    
    // MARK: - prompt 属性在 toModel 中的映射测试
    
    func testToModel_PromptMapping_Success() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.prompt = "测试提示内容"
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNotNil(result, "转换结果不应为 nil")
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.prompt, "测试提示内容", "prompt 应该正确映射到 Formula 模型")
    }
    
    func testToModel_PromptMapping_NilValue() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.prompt = nil
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNotNil(result, "转换结果不应为 nil")
        let formula = try XCTUnwrap(result)
        XCTAssertNil(formula.prompt, "nil prompt 应该正确映射到 Formula 模型")
    }
    
    func testToModel_PromptMapping_EmptyString() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.prompt = ""
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNotNil(result, "转换结果不应为 nil")
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.prompt, "", "空字符串 prompt 应该正确映射到 Formula 模型")
    }
    
    // MARK: - prompt 属性在 fromModel 中的映射测试
    
    func testFromModel_PromptMapping_Success() throws {
        // Given
        var formula = createTestFormula()
        formula.prompt = "从模型创建的提示"
        
        // When
        FormulaEntity.from(model: formula, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1, "应该创建一个 FormulaEntity")
        
        let entity = try XCTUnwrap(entities.first)
        XCTAssertEqual(entity.prompt, "从模型创建的提示", "prompt 应该正确从 Formula 模型映射到实体")
    }
    
    func testFromModel_PromptMapping_NilValue() throws {
        // Given
        var formula = createTestFormula()
        formula.prompt = nil
        
        // When
        FormulaEntity.from(model: formula, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1, "应该创建一个 FormulaEntity")
        
        let entity = try XCTUnwrap(entities.first)
        XCTAssertNil(entity.prompt, "nil prompt 应该正确从 Formula 模型映射到实体")
    }
    
    func testFromModel_PromptMapping_EmptyString() throws {
        // Given
        var formula = createTestFormula()
        formula.prompt = ""
        
        // When
        FormulaEntity.from(model: formula, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1, "应该创建一个 FormulaEntity")
        
        let entity = try XCTUnwrap(entities.first)
        XCTAssertEqual(entity.prompt, "", "空字符串 prompt 应该正确从 Formula 模型映射到实体")
    }
    
    // MARK: - prompt 属性的往返转换测试
    
    func testPromptProperty_RoundTripConversion() throws {
        // Given
        let originalPrompt = "往返转换测试提示"
        let entity = createTestFormulaEntity()
        entity.prompt = originalPrompt
        
        // When - 转换为模型再转换回实体
        let formula = entity.toModel()
        XCTAssertNotNil(formula)
        
        // 清空当前实体
        context.delete(entity)
        try context.save()
        
        // 从模型创建新实体
        FormulaEntity.from(model: formula!, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1, "应该创建一个新的 FormulaEntity")
        
        let newEntity = try XCTUnwrap(entities.first)
        XCTAssertEqual(newEntity.prompt, originalPrompt, "prompt 应该在往返转换中保持不变")
    }
    
    func testPromptProperty_RoundTripConversion_NilValue() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.prompt = nil
        
        // When - 转换为模型再转换回实体
        let formula = entity.toModel()
        XCTAssertNotNil(formula)
        
        // 清空当前实体
        context.delete(entity)
        try context.save()
        
        // 从模型创建新实体
        FormulaEntity.from(model: formula!, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1, "应该创建一个新的 FormulaEntity")
        
        let newEntity = try XCTUnwrap(entities.first)
        XCTAssertNil(newEntity.prompt, "nil prompt 应该在往返转换中保持不变")
    }
    
    // MARK: - prompt 属性的边界情况测试
    
    func testPromptProperty_WithVeryLongString() throws {
        // Given
        let veryLongPrompt = String(repeating: "这是一个非常长的提示内容，用于测试系统对长字符串的处理能力。", count: 1000)
        let entity = createTestFormulaEntity()
        
        // When
        entity.prompt = veryLongPrompt
        
        // Then
        XCTAssertEqual(entity.prompt, veryLongPrompt, "系统应该能够处理非常长的 prompt 字符串")
        
        // 测试往返转换
        let formula = entity.toModel()
        XCTAssertNotNil(formula)
        XCTAssertEqual(formula?.prompt, veryLongPrompt, "长字符串应该在往返转换中保持不变")
    }
    
    func testPromptProperty_WithNewlinesAndTabs() throws {
        // Given
        let promptWithWhitespace = "第一行提示\n第二行提示\t制表符\n\n空行测试"
        let entity = createTestFormulaEntity()
        
        // When
        entity.prompt = promptWithWhitespace
        
        // Then
        XCTAssertEqual(entity.prompt, promptWithWhitespace, "系统应该能够处理包含换行符和制表符的 prompt")
        
        // 测试往返转换
        let formula = entity.toModel()
        XCTAssertNotNil(formula)
        XCTAssertEqual(formula?.prompt, promptWithWhitespace, "包含空白字符的字符串应该在往返转换中保持不变")
    }
    
    func testPromptProperty_WithJSONLikeContent() throws {
        // Given
        let jsonLikePrompt = """
        {
            "instruction": "这是一个类似JSON的提示",
            "steps": ["步骤1", "步骤2"],
            "note": "注意：这不是真正的JSON"
        }
        """
        let entity = createTestFormulaEntity()
        
        // When
        entity.prompt = jsonLikePrompt
        
        // Then
        XCTAssertEqual(entity.prompt, jsonLikePrompt, "系统应该能够处理类似JSON格式的 prompt")
        
        // 测试往返转换
        let formula = entity.toModel()
        XCTAssertNotNil(formula)
        XCTAssertEqual(formula?.prompt, jsonLikePrompt, "类似JSON的字符串应该在往返转换中保持不变")
    }
    
    // MARK: - prompt 属性的性能测试
    
    func testPromptProperty_Performance() throws {
        // Given
        let entity = createTestFormulaEntity()
        let testPrompt = "性能测试提示内容"
        
        // When & Then
        measure {
            for _ in 0..<10000 {
                entity.prompt = testPrompt
                _ = entity.prompt
            }
        }
    }
    
    func testPromptProperty_ToModelPerformance() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.prompt = "性能测试提示内容"
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = entity.toModel()
            }
        }
    }
    
    func testPromptProperty_FromModelPerformance() throws {
        // Given
        var formula = createTestFormula()
        formula.prompt = "性能测试提示内容"
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                FormulaEntity.from(model: formula, in: context)
            }
        }
    }
    
    // MARK: - prompt 属性的并发测试
    
    func testPromptProperty_ConcurrentAccess() throws {
        // Given
        let entity = createTestFormulaEntity()
        let expectation = XCTestExpectation(description: "并发访问完成")
        expectation.expectedFulfillmentCount = 10
        
        // When - 使用 DispatchGroup 来管理并发任务
        let group = DispatchGroup()
        
        for i in 0..<10 {
            group.enter()
            DispatchQueue.global().async {
                entity.prompt = "并发测试提示 \(i)"
                _ = entity.prompt
                group.leave()
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertNotNil(entity.prompt, "并发访问后 prompt 应该仍然有效")
    }
    
    // MARK: - prompt 属性的内存管理测试
    
    func testPromptProperty_MemoryManagement() throws {
        // Given
        var entity: FormulaEntity? = createTestFormulaEntity()
        entity?.prompt = "内存管理测试提示"
        
        // When
        let prompt = entity?.prompt
        entity = nil // 释放实体
        
        // Then
        XCTAssertNotNil(prompt, "prompt 值应该在实体释放后仍然可访问")
        XCTAssertEqual(prompt, "内存管理测试提示", "prompt 值应该正确")
    }
}
