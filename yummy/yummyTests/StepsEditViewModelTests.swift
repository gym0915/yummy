//
//  StepsEditViewModelTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/17.
//

import XCTest
import Combine
@testable import yummy

@MainActor
final class StepsEditViewModelTests: XCTestCase {
    
    var viewModel: StepsEditViewModel!
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
        
        AppLog("🧪 [StepsEditViewModelTests] 测试环境准备就绪", level: .debug, category: .ui)
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockRepository = nil
        cancellables = nil
        testFormula = nil
        try super.tearDownWithError()
        
        AppLog("🧹 [StepsEditViewModelTests] 测试环境清理完成", level: .debug, category: .ui)
    }
    
    // MARK: - 初始化测试
    
    func testInitializationWithPreparationType() {
        // Given
        let editType = StepEditType.preparation
        
        // When
        viewModel = StepsEditViewModel(formula: testFormula, editType: editType, formulaRepository: mockRepository)
        
        // Then
        XCTAssertEqual(viewModel.editedPreparationSteps.count, testFormula.preparation.count)
        XCTAssertEqual(viewModel.editedPreparationSteps, testFormula.preparation)
        XCTAssertEqual(viewModel.currentStepCount, testFormula.preparation.count)
        
        AppLog("✅ 备菜类型初始化测试通过", level: .debug, category: .ui)
    }
    
    func testInitializationWithCookingType() {
        // Given
        let editType = StepEditType.cooking
        
        // When
        viewModel = StepsEditViewModel(formula: testFormula, editType: editType, formulaRepository: mockRepository)
        
        // Then
        XCTAssertEqual(viewModel.editedCookingSteps.count, testFormula.steps.count)
        XCTAssertEqual(viewModel.editedCookingSteps, testFormula.steps)
        XCTAssertEqual(viewModel.currentStepCount, testFormula.steps.count)
        
        AppLog("✅ 料理类型初始化测试通过", level: .debug, category: .ui)
    }
    
    func testInitializationWithTipsType() {
        // Given
        let editType = StepEditType.tips
        
        // When
        viewModel = StepsEditViewModel(formula: testFormula, editType: editType, formulaRepository: mockRepository)
        
        // Then
        XCTAssertEqual(viewModel.editedTips.count, testFormula.tips.count)
        XCTAssertEqual(viewModel.editedTips, testFormula.tips)
        XCTAssertEqual(viewModel.currentStepCount, testFormula.tips.count)
        
        AppLog("✅ 小窍门类型初始化测试通过", level: .debug, category: .ui)
    }
    
    // MARK: - 状态检测测试
    
    func testHasChangesWithNoModification() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        
        // When/Then
        XCTAssertFalse(viewModel.hasChanges, "未修改时应该没有变化")
        
        AppLog("✅ 无修改状态检测测试通过", level: .debug, category: .ui)
    }
    
    func testHasChangesWithModification() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        
        // When
        viewModel.updateStepDetails(at: 0, details: "修改后的备菜步骤")
        
        // Then
        XCTAssertTrue(viewModel.hasChanges, "修改后应该有变化")
        
        AppLog("✅ 有修改状态检测测试通过", level: .debug, category: .ui)
    }
    
    func testCanSaveWithValidData() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        
        // When
        viewModel.updateStepDetails(at: 0, details: "有效的备菜步骤")
        
        // Then
        XCTAssertTrue(viewModel.canSave, "有效数据应该可以保存")
        
        AppLog("✅ 有效数据保存检测测试通过", level: .debug, category: .ui)
    }
    
    func testCanSaveWithEmptySteps() {
        // Given
        let emptyFormula = createEmptyTestFormula()
        viewModel = StepsEditViewModel(formula: emptyFormula, editType: .preparation, formulaRepository: mockRepository)
        
        // When/Then
        XCTAssertFalse(viewModel.canSave, "空步骤不应该可以保存")
        
        AppLog("✅ 空步骤保存检测测试通过", level: .debug, category: .ui)
    }
    
    func testCanSaveWithEmptyStepDetails() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        
        // When
        viewModel.addNewStep() // 添加空白步骤
        
        // Then
        XCTAssertFalse(viewModel.canSave, "包含空白步骤不应该可以保存")
        
        AppLog("✅ 空白步骤详情保存检测测试通过", level: .debug, category: .ui)
    }
    
    // MARK: - 步骤管理测试
    
    func testAddNewStepPreparation() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        
        // When
        viewModel.addNewStep()
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount + 1)
        XCTAssertEqual(viewModel.editedPreparationSteps.count, originalCount + 1)
        XCTAssertEqual(viewModel.editedPreparationSteps.last?.details, "")
        XCTAssertEqual(viewModel.editedPreparationSteps.last?.step, "")
        
        AppLog("✅ 添加备菜步骤测试通过", level: .debug, category: .ui)
    }
    
    func testAddNewStepCooking() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .cooking, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        
        // When
        viewModel.addNewStep()
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount + 1)
        XCTAssertEqual(viewModel.editedCookingSteps.count, originalCount + 1)
        XCTAssertEqual(viewModel.editedCookingSteps.last?.details, "")
        XCTAssertEqual(viewModel.editedCookingSteps.last?.step, "")
        
        AppLog("✅ 添加料理步骤测试通过", level: .debug, category: .ui)
    }
    
    func testAddNewStepTips() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .tips, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        
        // When
        viewModel.addNewStep()
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount + 1)
        XCTAssertEqual(viewModel.editedTips.count, originalCount + 1)
        XCTAssertEqual(viewModel.editedTips.last, "")
        
        AppLog("✅ 添加小窍门测试通过", level: .debug, category: .ui)
    }
    
    func testRemoveStepPreparation() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        let stepToRemove = viewModel.editedPreparationSteps[0]
        
        // When
        viewModel.removeStep(at: 0)
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount - 1)
        XCTAssertEqual(viewModel.editedPreparationSteps.count, originalCount - 1)
        XCTAssertFalse(viewModel.editedPreparationSteps.contains(stepToRemove))
        
        AppLog("✅ 删除备菜步骤测试通过", level: .debug, category: .ui)
    }
    
    func testRemoveStepCooking() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .cooking, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        let stepToRemove = viewModel.editedCookingSteps[0]
        
        // When
        viewModel.removeStep(at: 0)
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount - 1)
        XCTAssertEqual(viewModel.editedCookingSteps.count, originalCount - 1)
        XCTAssertFalse(viewModel.editedCookingSteps.contains(stepToRemove))
        
        AppLog("✅ 删除料理步骤测试通过", level: .debug, category: .ui)
    }
    
    func testRemoveStepTips() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .tips, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        let tipToRemove = viewModel.editedTips[0]
        
        // When
        viewModel.removeStep(at: 0)
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount - 1)
        XCTAssertEqual(viewModel.editedTips.count, originalCount - 1)
        XCTAssertFalse(viewModel.editedTips.contains(tipToRemove))
        
        AppLog("✅ 删除小窍门测试通过", level: .debug, category: .ui)
    }
    
    func testRemoveStepAtInvalidIndex() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let originalCount = viewModel.currentStepCount
        
        // When
        viewModel.removeStep(at: -1) // 无效索引
        viewModel.removeStep(at: 999) // 超出范围索引
        
        // Then
        XCTAssertEqual(viewModel.currentStepCount, originalCount, "删除无效索引不应该影响数据")
        
        AppLog("✅ 删除无效索引步骤测试通过", level: .debug, category: .ui)
    }
    
    // MARK: - 步骤更新测试
    
    func testUpdateStepDetailsPreparation() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let newDetails = "更新后的备菜步骤详情"
        
        // When
        viewModel.updateStepDetails(at: 0, details: newDetails)
        
        // Then
        XCTAssertEqual(viewModel.editedPreparationSteps[0].details, newDetails)
        XCTAssertTrue(viewModel.hasChanges, "更新后应该有变化")
        
        AppLog("✅ 更新备菜步骤详情测试通过", level: .debug, category: .ui)
    }
    
    func testUpdateStepDetailsCooking() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .cooking, formulaRepository: mockRepository)
        let newDetails = "更新后的料理步骤详情"
        
        // When
        viewModel.updateStepDetails(at: 0, details: newDetails)
        
        // Then
        XCTAssertEqual(viewModel.editedCookingSteps[0].details, newDetails)
        XCTAssertTrue(viewModel.hasChanges, "更新后应该有变化")
        
        AppLog("✅ 更新料理步骤详情测试通过", level: .debug, category: .ui)
    }
    
    func testUpdateStepDetailsTips() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .tips, formulaRepository: mockRepository)
        let newTip = "更新后的小窍门"
        
        // When
        viewModel.updateStepDetails(at: 0, details: newTip)
        
        // Then
        XCTAssertEqual(viewModel.editedTips[0], newTip)
        XCTAssertTrue(viewModel.hasChanges, "更新后应该有变化")
        
        AppLog("✅ 更新小窍门详情测试通过", level: .debug, category: .ui)
    }
    
    func testUpdateStepDetailsAtInvalidIndex() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let originalSteps = viewModel.editedPreparationSteps
        
        // When
        viewModel.updateStepDetails(at: -1, details: "无效更新")
        viewModel.updateStepDetails(at: 999, details: "无效更新")
        
        // Then
        XCTAssertEqual(viewModel.editedPreparationSteps, originalSteps, "无效索引更新不应该影响数据")
        
        AppLog("✅ 更新无效索引步骤详情测试通过", level: .debug, category: .ui)
    }
    
    // MARK: - 重置功能测试
    
    func testResetPreparation() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let originalSteps = viewModel.editedPreparationSteps
        
        // When
        viewModel.updateStepDetails(at: 0, details: "修改后的内容")
        viewModel.reset()
        
        // Then
        XCTAssertEqual(viewModel.editedPreparationSteps, originalSteps, "重置后应该恢复原始数据")
        XCTAssertFalse(viewModel.hasChanges, "重置后应该没有变化")
        
        AppLog("✅ 重置备菜编辑状态测试通过", level: .debug, category: .ui)
    }
    
    func testResetCooking() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .cooking, formulaRepository: mockRepository)
        let originalSteps = viewModel.editedCookingSteps
        
        // When
        viewModel.updateStepDetails(at: 0, details: "修改后的内容")
        viewModel.reset()
        
        // Then
        XCTAssertEqual(viewModel.editedCookingSteps, originalSteps, "重置后应该恢复原始数据")
        XCTAssertFalse(viewModel.hasChanges, "重置后应该没有变化")
        
        AppLog("✅ 重置料理编辑状态测试通过", level: .debug, category: .ui)
    }
    
    func testResetTips() {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .tips, formulaRepository: mockRepository)
        let originalTips = viewModel.editedTips
        
        // When
        viewModel.updateStepDetails(at: 0, details: "修改后的小窍门")
        viewModel.reset()
        
        // Then
        XCTAssertEqual(viewModel.editedTips, originalTips, "重置后应该恢复原始数据")
        XCTAssertFalse(viewModel.hasChanges, "重置后应该没有变化")
        
        AppLog("✅ 重置小窍门编辑状态测试通过", level: .debug, category: .ui)
    }
    
    // MARK: - 保存功能测试
    
    func testSaveWithValidPreparationChanges() async {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        let newDetails = "更新后的备菜步骤"
        viewModel.updateStepDetails(at: 0, details: newDetails)
        
        // When
        await viewModel.save()
        
        // Then
        XCTAssertTrue(mockRepository.updateCalled, "应该调用更新方法")
        let updatedFormula = mockRepository.mockFormulas.first { $0.id == testFormula.id }
        XCTAssertNotNil(updatedFormula, "应该找到更新的菜谱")
        XCTAssertEqual(updatedFormula?.preparation[0].details, newDetails, "备菜步骤应该被更新")
        
        AppLog("✅ 保存有效备菜修改测试通过", level: .debug, category: .ui)
    }
    
    func testSaveWithValidCookingChanges() async {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .cooking, formulaRepository: mockRepository)
        let newDetails = "更新后的料理步骤"
        viewModel.updateStepDetails(at: 0, details: newDetails)
        
        // When
        await viewModel.save()
        
        // Then
        XCTAssertTrue(mockRepository.updateCalled, "应该调用更新方法")
        let updatedFormula = mockRepository.mockFormulas.first { $0.id == testFormula.id }
        XCTAssertNotNil(updatedFormula, "应该找到更新的菜谱")
        XCTAssertEqual(updatedFormula?.steps[0].details, newDetails, "料理步骤应该被更新")
        
        AppLog("✅ 保存有效料理修改测试通过", level: .debug, category: .ui)
    }
    
    func testSaveWithValidTipsChanges() async {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .tips, formulaRepository: mockRepository)
        let newTip = "更新后的小窍门"
        viewModel.updateStepDetails(at: 0, details: newTip)
        
        // When
        await viewModel.save()
        
        // Then
        XCTAssertTrue(mockRepository.updateCalled, "应该调用更新方法")
        let updatedFormula = mockRepository.mockFormulas.first { $0.id == testFormula.id }
        XCTAssertNotNil(updatedFormula, "应该找到更新的菜谱")
        XCTAssertEqual(updatedFormula?.tips[0], newTip, "小窍门应该被更新")
        
        AppLog("✅ 保存有效小窍门修改测试通过", level: .debug, category: .ui)
    }
    
    func testSaveWithNoChanges() async {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        
        // When
        await viewModel.save()
        
        // Then
        XCTAssertFalse(mockRepository.updateCalled, "没有变化时不应该调用更新方法")
        
        AppLog("✅ 无修改保存测试通过", level: .debug, category: .ui)
    }
    
    func testSaveWithInvalidData() async {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        viewModel.addNewStep() // 添加空白步骤
        
        // When
        await viewModel.save()
        
        // Then
        XCTAssertFalse(mockRepository.updateCalled, "无效数据时不应该调用更新方法")
        
        AppLog("✅ 无效数据保存测试通过", level: .debug, category: .ui)
    }
    
    func testSaveWithRepositoryError() async {
        // Given
        viewModel = StepsEditViewModel(formula: testFormula, editType: .preparation, formulaRepository: mockRepository)
        mockRepository.shouldThrowError = true
        mockRepository.updateError = MockError.updateFailed
        let newDetails = "更新后的备菜步骤"
        viewModel.updateStepDetails(at: 0, details: newDetails)
        
        // When
        await viewModel.save()
        
        // Then
        XCTAssertTrue(mockRepository.updateCalled, "应该尝试调用更新方法")
        // 错误处理已经在save方法中处理，这里主要验证调用了更新方法
        
        AppLog("✅ 仓库错误保存测试通过", level: .debug, category: .ui)
    }
    
    // MARK: - 辅助方法
    
    private func createTestFormula() -> Formula {
        return Formula(
            name: "测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "测试食材1", quantity: "100g", category: "测试分类")
                ],
                spicesSeasonings: [
                    Ingredient(name: "测试调料", quantity: "适量", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "测试酱汁", quantity: "适量")
                ]
            ),
            tools: [
                Tool(name: "测试工具")
            ],
            preparation: [
                PreparationStep(step: "测试备菜步骤1", details: "测试备菜详情1"),
                PreparationStep(step: "测试备菜步骤2", details: "测试备菜详情2")
            ],
            steps: [
                CookingStep(step: "测试料理步骤1", details: "测试料理详情1"),
                CookingStep(step: "测试料理步骤2", details: "测试料理详情2")
            ],
            tips: [
                "测试小窍门1",
                "测试小窍门2"
            ],
            tags: ["测试标签"],
            date: Date(),
            state: .loading,
            imgpath: nil,
            isCuisine: false
        )
    }
    
    private func createEmptyTestFormula() -> Formula {
        return Formula(
            name: "空测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [],
                spicesSeasonings: [],
                sauce: []
            ),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: Date(),
            state: .loading,
            imgpath: nil,
            isCuisine: false
        )
    }
}