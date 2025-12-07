//
//  ToolsEditViewModelTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/21.
//

import XCTest
import Combine
@testable import yummy

@MainActor
final class ToolsEditViewModelTests: XCTestCase {
    
    var viewModel: ToolsEditViewModel!
    var mockRepository: MockFormulaRepository!
    var cancellables: Set<AnyCancellable>!
    var testFormula: Formula!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 初始化测试数据
        testFormula = createTestFormula()
        mockRepository = MockFormulaRepository()
        mockRepository.mockFormulas = [testFormula]
        cancellables = Set<AnyCancellable>()
        
        AppLog("🧪 [ToolsEditViewModelTests] 测试环境准备就绪", level: .debug, category: .viewmodel)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        testFormula = nil
        try super.tearDownWithError()
        
        AppLog("🧹 [ToolsEditViewModelTests] 测试环境清理完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() {
        // When
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, testFormula.tools.count)
        XCTAssertEqual(viewModel.editedTools, testFormula.tools)
        XCTAssertEqual(viewModel.newToolText, "")
        
        AppLog("✅ 初始化测试通过", level: .debug, category: .viewmodel)
    }
    
    func testInitializationWithCustomLimits() {
        // Given
        let maxTagCount = 5
        let maxTagLength = 10
        
        // When
        viewModel = ToolsEditViewModel(
            formula: testFormula,
            maxTagCount: maxTagCount,
            maxTagLength: maxTagLength,
            formulaRepository: mockRepository
        )
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, testFormula.tools.count)
        XCTAssertEqual(viewModel.editedTools, testFormula.tools)
        XCTAssertEqual(viewModel.newToolText, "")
        
        AppLog("✅ 自定义限制初始化测试通过", level: .debug, category: .viewmodel)
    }
    
    // MARK: - 计算属性测试
    
    func testCanAddToolWithValidInput() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        
        // When
        viewModel.newToolText = "新厨具"
        
        // Then
        XCTAssertTrue(viewModel.canAddTool, "应该可以添加有效的新厨具")
        
        AppLog("✅ 有效输入canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanAddToolWithEmptyInput() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        
        // When
        viewModel.newToolText = ""
        
        // Then
        XCTAssertFalse(viewModel.canAddTool, "不应该添加空的厨具")
        
        AppLog("✅ 空输入canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanAddToolWithWhitespaceInput() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        
        // When
        viewModel.newToolText = "   "
        
        // Then
        XCTAssertFalse(viewModel.canAddTool, "不应该只包含空白字符的厨具")
        
        AppLog("✅ 空白字符canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanAddToolWithDuplicateName() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let existingToolName = testFormula.tools.first?.name ?? "案板"
        
        // When
        viewModel.newToolText = existingToolName
        
        // Then
        XCTAssertFalse(viewModel.canAddTool, "不应该添加重复的厨具")
        
        AppLog("✅ 重复名称canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanAddToolWithDuplicateNameCaseInsensitive() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let existingToolName = testFormula.tools.first?.name ?? "案板"
        
        // When
        viewModel.newToolText = existingToolName.uppercased()
        
        // Then
        XCTAssertFalse(viewModel.canAddTool, "不应该添加重复的厨具（不区分大小写）")
        
        AppLog("✅ 重复名称（不区分大小写）canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanAddToolWithExceedingMaxLength() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, maxTagLength: 3, formulaRepository: mockRepository)
        
        // When
        viewModel.newToolText = "超长的厨具名称"
        
        // Then
        XCTAssertFalse(viewModel.canAddTool, "不应该添加超过最大长度的厨具")
        
        AppLog("✅ 超长名称canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanAddToolWithMaxCountReached() {
        // Given
        let limitedFormula = createTestFormulaWithLimitedTools(maxCount: 2)
        viewModel = ToolsEditViewModel(formula: limitedFormula, maxTagCount: 2, formulaRepository: mockRepository)
        
        // When
        viewModel.newToolText = "新厨具"
        
        // Then
        XCTAssertFalse(viewModel.canAddTool, "当达到最大数量时不应该再添加")
        
        AppLog("✅ 最大数量限制canAddTool测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanSaveWithNoChanges() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        
        // When/Then
        XCTAssertFalse(viewModel.canSave, "没有变化时不应该可以保存")
        
        AppLog("✅ 无变化canSave测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanSaveWithChanges() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        
        // When
        viewModel.editedTools.append(Tool(name: "新厨具"))
        
        // Then
        XCTAssertTrue(viewModel.canSave, "有变化且不为空时应该可以保存")
        
        AppLog("✅ 有变化canSave测试通过", level: .debug, category: .viewmodel)
    }
    
    func testCanSaveWithEmptyTools() {
        // Given
        let emptyToolsFormula = createTestFormulaWithEmptyTools()
        viewModel = ToolsEditViewModel(formula: emptyToolsFormula, formulaRepository: mockRepository)
        
        // When
        viewModel.editedTools = []
        
        // Then
        XCTAssertFalse(viewModel.canSave, "厨具为空时不应该可以保存")
        
        AppLog("✅ 空厨具canSave测试通过", level: .debug, category: .viewmodel)
    }
    
    // MARK: - 添加厨具测试
    
    func testAddNewToolSuccessfully() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let originalCount = viewModel.editedTools.count
        viewModel.newToolText = "新厨具"
        
        // When
        viewModel.addNewTool()
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount + 1)
        XCTAssertEqual(viewModel.editedTools.last?.name, "新厨具")
        XCTAssertEqual(viewModel.newToolText, "")
        
        AppLog("✅ 成功添加厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testAddNewToolWithInvalidInput() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let originalCount = viewModel.editedTools.count
        viewModel.newToolText = ""  // 空输入
        
        // When
        viewModel.addNewTool()
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount)
        XCTAssertEqual(viewModel.newToolText, "")  // 应该保持不变
        
        AppLog("✅ 无效输入添加厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testAddNewToolWithDuplicateName() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let originalCount = viewModel.editedTools.count
        let existingToolName = testFormula.tools.first?.name ?? "案板"
        viewModel.newToolText = existingToolName
        
        // When
        viewModel.addNewTool()
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount, "厨具数量不应改变")
        XCTAssertEqual(viewModel.newToolText, "", "输入框应该被清空")
        
        AppLog("✅ 重复名称添加厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testAddNewToolWithDuplicateNameCaseInsensitive() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let originalCount = viewModel.editedTools.count
        let existingToolName = testFormula.tools.first?.name ?? "案板"
        viewModel.newToolText = existingToolName.uppercased()
        
        // When
        viewModel.addNewTool()
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount, "厨具数量不应改变")
        XCTAssertEqual(viewModel.newToolText, "", "输入框应该被清空")
        
        AppLog("✅ 重复名称（不区分大小写）添加厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    // MARK: - 删除厨具测试
    
    func testRemoveToolAtValidIndex() {
        // Given
        let formulaWithTools = createTestFormula()
        viewModel = ToolsEditViewModel(formula: formulaWithTools, formulaRepository: mockRepository)
        
        let originalCount = viewModel.editedTools.count
        let indexToRemove = 0
        
        // Ensure there's something to remove
        guard indexToRemove < originalCount else {
            XCTFail("Test setup failed: No tools available to remove at the specified index.")
            return
        }
        
        let removedToolName = viewModel.editedTools[indexToRemove].name
        
        // When
        viewModel.removeTool(at: indexToRemove)
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount - 1)
        XCTAssertFalse(viewModel.editedTools.contains { $0.name == removedToolName })
        
        AppLog("✅ 有效索引删除厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testRemoveToolAtInvalidIndex() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let originalCount = viewModel.editedTools.count
        let invalidIndex = -1
        
        // When
        viewModel.removeTool(at: invalidIndex)
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount)
        XCTAssertEqual(viewModel.editedTools, testFormula.tools)
        
        AppLog("✅ 无效索引删除厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testRemoveToolAtOutOfBoundsIndex() {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        let originalCount = viewModel.editedTools.count
        let outOfBoundsIndex = originalCount + 10
        
        // When
        viewModel.removeTool(at: outOfBoundsIndex)
        
        // Then
        XCTAssertEqual(viewModel.editedTools.count, originalCount)
        XCTAssertEqual(viewModel.editedTools, testFormula.tools)
        
        AppLog("✅ 越界索引删除厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    // MARK: - 保存测试
    
    func testSaveToolsSuccessfully() async {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        viewModel.editedTools.append(Tool(name: "新厨具"))
        mockRepository.shouldReturnSuccess = true
        
        // When
        let result = await viewModel.saveTools()
        
        // Then
        XCTAssertTrue(result, "保存应该成功")
        XCTAssertTrue(mockRepository.updateCalled, "应该调用更新方法")
        
        AppLog("✅ 成功保存厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testSaveToolsWithFailure() async {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        viewModel.editedTools.append(Tool(name: "新厨具"))
        mockRepository.shouldThrowError = true
        mockRepository.updateError = MockError.updateFailed
        
        // When
        let result = await viewModel.saveTools()
        
        // Then
        XCTAssertFalse(result, "保存应该失败")
        XCTAssertTrue(mockRepository.updateCalled, "应该调用更新方法")
        
        AppLog("✅ 失败保存厨具测试通过", level: .debug, category: .viewmodel)
    }
    
    func testSaveToolsWithNoChanges() async {
        // Given
        viewModel = ToolsEditViewModel(formula: testFormula, formulaRepository: mockRepository)
        // 不修改 editedTools，保持与原始数据一致
        
        // When
        let result = await viewModel.saveTools()
        
        // Then
        XCTAssertFalse(viewModel.canSave, "没有变化时不应该可以保存")
        // 注意：即使调用了saveTools，也应该返回false，因为canSave为false
        
        AppLog("✅ 无变化保存厨具测试通过", level: .debug, category: .viewmodel)
    }
}

// MARK: - 测试辅助函数

private func createTestFormula() -> Formula {
    return Formula(
        name: "测试菜谱",
        ingredients: Ingredients(
            mainIngredients: [
                Ingredient(name: "主料1", quantity: "100g", category: "肉类")
            ],
            spicesSeasonings: [
                Ingredient(name: "调料1", quantity: "适量", category: nil)
            ],
            sauce: []
        ),
        tools: [
            Tool(name: "案板"),
            Tool(name: "刀"),
            Tool(name: "锅")
        ],
        preparation: [
            PreparationStep(step: "步骤1", details: "详情1")
        ],
        steps: [
            CookingStep(step: "烹饪1", details: "烹饪详情1")
        ],
        tips: ["小贴士1"],
        tags: ["标签1"],
        date: Date(),
        state: .finish
    )
}

private func createTestFormulaWithLimitedTools(maxCount: Int) -> Formula {
    var formula = createTestFormula()
    // 确保工具数量达到限制
    var tools = [Tool]()
    for i in 0..<maxCount {
        tools.append(Tool(name: "工具\(i+1)"))
    }
    formula = Formula(
        name: formula.name,
        ingredients: formula.ingredients,
        tools: tools,
        preparation: formula.preparation,
        steps: formula.steps,
        tips: formula.tips,
        tags: formula.tags,
        date: formula.date,
        state: formula.state
    )
    return formula
}

private func createTestFormulaWithEmptyTools() -> Formula {
    let formula = createTestFormula()
    return Formula(
        name: formula.name,
        ingredients: formula.ingredients,
        tools: [],
        preparation: formula.preparation,
        steps: formula.steps,
        tips: formula.tips,
        tags: formula.tags,
        date: formula.date,
        state: formula.state
    )
}