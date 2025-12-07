//
//  FormulaEntityMapperTests.swift
//  yummyTests
//
//  Created by steve on 2025/1/27.
//

import XCTest
import CoreData
@testable import yummy

class FormulaEntityMapperTests: XCTestCase {
    
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
    
    // MARK: - toModel() 方法测试
    
    func testToModel_Success() throws {
        // Given
        let entity = createTestFormulaEntity()
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNotNil(result, "转换结果不应为 nil")
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.id, "test-formula-id")
        XCTAssertEqual(formula.name, "测试菜谱")
        XCTAssertEqual(formula.prompt, "测试提示")
        XCTAssertEqual(formula.state, .loading)
        XCTAssertEqual(formula.imgpath, "test-image.jpg")
        XCTAssertEqual(formula.isCuisine, true)
        
        // 验证 ingredients
        XCTAssertEqual(formula.ingredients.mainIngredients.count, 2)
        XCTAssertEqual(formula.ingredients.mainIngredients[0].name, "主料1")
        XCTAssertEqual(formula.ingredients.mainIngredients[0].quantity, "100g")
        XCTAssertEqual(formula.ingredients.mainIngredients[0].category, "肉类")
        
        XCTAssertEqual(formula.ingredients.spicesSeasonings.count, 1)
        XCTAssertEqual(formula.ingredients.spicesSeasonings[0].name, "调料1")
        
        XCTAssertEqual(formula.ingredients.sauce.count, 1)
        XCTAssertEqual(formula.ingredients.sauce[0].name, "蘸料1")
        
        // 验证 tools
        XCTAssertEqual(formula.tools.count, 2)
        XCTAssertEqual(formula.tools[0].name, "平底锅")
        XCTAssertEqual(formula.tools[1].name, "铲子")
        
        // 验证 preparation
        XCTAssertEqual(formula.preparation.count, 2)
        XCTAssertEqual(formula.preparation[0].step, "准备1")
        XCTAssertEqual(formula.preparation[0].details, "准备步骤详情1")
        
        // 验证 steps
        XCTAssertEqual(formula.steps.count, 2)
        XCTAssertEqual(formula.steps[0].step, "料理1")
        XCTAssertEqual(formula.steps[0].details, "料理步骤详情1")
        
        // 验证 tips
        XCTAssertEqual(formula.tips.count, 2)
        XCTAssertEqual(formula.tips[0], "小贴士1")
        XCTAssertEqual(formula.tips[1], "小贴士2")
        
        // 验证 tags
        XCTAssertEqual(formula.tags.count, 2)
        XCTAssertEqual(formula.tags[0], "标签1")
        XCTAssertEqual(formula.tags[1], "标签2")
    }
    
    func testToModel_MissingRequiredFields() throws {
        // Given
        let entity = FormulaEntity(context: context)
        // 不设置任何必需字段
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNil(result, "缺少必需字段时应返回 nil")
    }
    
    func testToModel_MissingId() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.id = nil
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNil(result, "缺少 id 时应返回 nil")
    }
    
    func testToModel_MissingName() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.name = nil
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNil(result, "缺少 name 时应返回 nil")
    }
    
    func testToModel_MissingIngredients() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.ingredients = nil
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNil(result, "缺少 ingredients 时应返回 nil")
    }
    
    func testToModel_InvalidIngredientsData() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.ingredients = Data("invalid json".utf8)
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNil(result, "无效的 ingredients 数据时应返回 nil")
    }
    
    func testToModel_InvalidState() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.state = 999 // 无效的状态值
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNotNil(result, "无效状态时应使用默认值")
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.state, .loading, "无效状态应默认为 loading")
    }
    
    func testToModel_OptionalFields() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.prompt = nil
        entity.imgpath = nil
        entity.isCuisine = false
        
        // When
        let result = entity.toModel()
        
        // Then
        XCTAssertNotNil(result, "可选字段为 nil 时仍应成功转换")
        let formula = try XCTUnwrap(result)
        XCTAssertNil(formula.prompt)
        XCTAssertNil(formula.imgpath)
        XCTAssertEqual(formula.isCuisine, false)
    }
    
    // MARK: - from(model:in:) 静态方法测试
    
    func testFromModel_Success() throws {
        // Given
        var formula = createTestFormula()
        formula.id = "test-formula-id"
        
        // When
        FormulaEntity.from(model: formula, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1, "应该创建一个 FormulaEntity")
        
        let entity = try XCTUnwrap(entities.first)
        XCTAssertEqual(entity.id, "test-formula-id")
        XCTAssertEqual(entity.name, "测试菜谱")
        XCTAssertEqual(entity.prompt, "测试提示")
        XCTAssertEqual(entity.state, FormulaState.loading.rawValue)
        XCTAssertEqual(entity.imgpath, "test-image.jpg")
        XCTAssertEqual(entity.isCuisine, true)
        
        // 验证编码的数据
        XCTAssertNotNil(entity.ingredients)
        XCTAssertNotNil(entity.tools)
        XCTAssertNotNil(entity.preparation)
        XCTAssertNotNil(entity.steps)
        XCTAssertNotNil(entity.tips)
        XCTAssertNotNil(entity.tags)
    }
    
    func testFromModel_EmptyArrays() throws {
        // Given
        let formula = Formula(
            name: "空数组测试",
            ingredients: Ingredients(),
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
        
        // When
        FormulaEntity.from(model: formula, in: context)
        
        // Then
        let entities = try context.fetch(FormulaEntity.fetchRequest())
        XCTAssertEqual(entities.count, 1)
        
        let entity = try XCTUnwrap(entities.first)
        XCTAssertEqual(entity.name, "空数组测试")
        XCTAssertEqual(entity.state, FormulaState.finish.rawValue)
        XCTAssertEqual(entity.isCuisine, false)
        
        // 验证空数组被正确编码
        XCTAssertNotNil(entity.ingredients)
        XCTAssertNotNil(entity.tools)
        XCTAssertNotNil(entity.preparation)
        XCTAssertNotNil(entity.steps)
        XCTAssertNotNil(entity.tips)
        XCTAssertNotNil(entity.tags)
    }
    
    // MARK: - 子元素数组更新方法测试
    
    func testUpdateMainIngredients() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newMainIngredients = [
            Ingredient(name: "新主料1", quantity: "300g", category: "海鲜"),
            Ingredient(name: "新主料2", quantity: "400g", category: "豆制品")
        ]
        
        // When
        entity.updateMainIngredients(newMainIngredients)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.ingredients.mainIngredients.count, 2)
        XCTAssertEqual(formula.ingredients.mainIngredients[0].name, "新主料1")
        XCTAssertEqual(formula.ingredients.mainIngredients[0].quantity, "300g")
        XCTAssertEqual(formula.ingredients.mainIngredients[0].category, "海鲜")
        
        // 验证其他部分未改变
        XCTAssertEqual(formula.ingredients.spicesSeasonings.count, 1)
        XCTAssertEqual(formula.ingredients.sauce.count, 1)
    }
    
    func testUpdateSpicesSeasonings() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newSpices = [
            Ingredient(name: "新调料1", quantity: "2勺", category: nil),
            Ingredient(name: "新调料2", quantity: "1茶匙", category: nil)
        ]
        
        // When
        entity.updateSpicesSeasonings(newSpices)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.ingredients.spicesSeasonings.count, 2)
        XCTAssertEqual(formula.ingredients.spicesSeasonings[0].name, "新调料1")
        XCTAssertEqual(formula.ingredients.spicesSeasonings[0].quantity, "2勺")
        
        // 验证其他部分未改变
        XCTAssertEqual(formula.ingredients.mainIngredients.count, 2)
        XCTAssertEqual(formula.ingredients.sauce.count, 1)
    }
    
    func testUpdateSauce() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newSauce = [
            SauceIngredient(name: "新蘸料1", quantity: "3勺"),
            SauceIngredient(name: "新蘸料2", quantity: "2勺")
        ]
        
        // When
        entity.updateSauce(newSauce)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.ingredients.sauce.count, 2)
        XCTAssertEqual(formula.ingredients.sauce[0].name, "新蘸料1")
        XCTAssertEqual(formula.ingredients.sauce[0].quantity, "3勺")
        
        // 验证其他部分未改变
        XCTAssertEqual(formula.ingredients.mainIngredients.count, 2)
        XCTAssertEqual(formula.ingredients.spicesSeasonings.count, 1)
    }
    
    func testUpdateTools() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newTools = [
            Tool(name: "新工具1"),
            Tool(name: "新工具2"),
            Tool(name: "新工具3")
        ]
        
        // When
        entity.updateTools(newTools)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.tools.count, 3)
        XCTAssertEqual(formula.tools[0].name, "新工具1")
        XCTAssertEqual(formula.tools[1].name, "新工具2")
        XCTAssertEqual(formula.tools[2].name, "新工具3")
    }
    
    func testUpdatePreparation() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newPreparation = [
            PreparationStep(step: "新准备1", details: "新准备详情1"),
            PreparationStep(step: "新准备2", details: "新准备详情2"),
            PreparationStep(step: "新准备3", details: "新准备详情3")
        ]
        
        // When
        entity.updatePreparation(newPreparation)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.preparation.count, 3)
        XCTAssertEqual(formula.preparation[0].step, "新准备1")
        XCTAssertEqual(formula.preparation[0].details, "新准备详情1")
    }
    
    func testUpdateSteps() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newSteps = [
            CookingStep(step: "新料理1", details: "新料理详情1"),
            CookingStep(step: "新料理2", details: "新料理详情2")
        ]
        
        // When
        entity.updateSteps(newSteps)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.steps.count, 2)
        XCTAssertEqual(formula.steps[0].step, "新料理1")
        XCTAssertEqual(formula.steps[0].details, "新料理详情1")
    }
    
    func testUpdateTips() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newTips = ["新小贴士1", "新小贴士2", "新小贴士3", "新小贴士4"]
        
        // When
        entity.updateTips(newTips)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.tips.count, 4)
        XCTAssertEqual(formula.tips[0], "新小贴士1")
        XCTAssertEqual(formula.tips[1], "新小贴士2")
        XCTAssertEqual(formula.tips[2], "新小贴士3")
        XCTAssertEqual(formula.tips[3], "新小贴士4")
    }
    
    func testUpdateTags() throws {
        // Given
        let entity = createTestFormulaEntity()
        let newTags = ["新标签1", "新标签2"]
        
        // When
        entity.updateTags(newTags)
        
        // Then
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.tags.count, 2)
        XCTAssertEqual(formula.tags[0], "新标签1")
        XCTAssertEqual(formula.tags[1], "新标签2")
    }
    
    // MARK: - 边界情况测试
    
    func testUpdateMainIngredients_WithNilIngredients() throws {
        // Given
        let entity = FormulaEntity(context: context)
        entity.id = "test-id"
        entity.name = "测试"
        entity.ingredients = nil
        entity.tools = Data("[]".utf8)
        entity.preparation = Data("[]".utf8)
        entity.steps = Data("[]".utf8)
        entity.tips = Data("[]".utf8)
        entity.tags = Data("[]".utf8)
        
        let newMainIngredients = [
            Ingredient(name: "新主料", quantity: "100g", category: "测试")
        ]
        
        // When
        entity.updateMainIngredients(newMainIngredients)
        
        // Then
        // 应该不会崩溃，但也不会更新（因为无法获取当前 ingredients）
        let result = entity.toModel()
        XCTAssertNil(result, "无法获取当前 ingredients 时应返回 nil")
    }
    
    func testUpdateSpicesSeasonings_WithInvalidIngredientsData() throws {
        // Given
        let entity = createTestFormulaEntity()
        entity.ingredients = Data("invalid json".utf8)
        
        let newSpices = [
            Ingredient(name: "新调料", quantity: "适量", category: nil)
        ]
        
        // When
        entity.updateSpicesSeasonings(newSpices)
        
        // Then
        // 应该不会崩溃，但也不会更新（因为无法解码当前 ingredients）
        let result = entity.toModel()
        XCTAssertNil(result, "无法解码当前 ingredients 时应返回 nil")
    }
    
    func testUpdateMethods_WithEmptyArrays() throws {
        // Given
        let entity = createTestFormulaEntity()
        
        // When & Then
        entity.updateMainIngredients([])
        entity.updateSpicesSeasonings([])
        entity.updateSauce([])
        entity.updateTools([])
        entity.updatePreparation([])
        entity.updateSteps([])
        entity.updateTips([])
        entity.updateTags([])
        
        let result = entity.toModel()
        XCTAssertNotNil(result)
        
        let formula = try XCTUnwrap(result)
        XCTAssertEqual(formula.ingredients.mainIngredients.count, 0)
        XCTAssertEqual(formula.ingredients.spicesSeasonings.count, 0)
        XCTAssertEqual(formula.ingredients.sauce.count, 0)
        XCTAssertEqual(formula.tools.count, 0)
        XCTAssertEqual(formula.preparation.count, 0)
        XCTAssertEqual(formula.steps.count, 0)
        XCTAssertEqual(formula.tips.count, 0)
        XCTAssertEqual(formula.tags.count, 0)
    }
    
    // MARK: - 性能测试
    
    func testToModel_Performance() throws {
        // Given
        let entity = createTestFormulaEntity()
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                _ = entity.toModel()
            }
        }
    }
    
    func testFromModel_Performance() throws {
        // Given
        let formula = createTestFormula()
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                FormulaEntity.from(model: formula, in: context)
            }
        }
    }
}
