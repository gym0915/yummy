import XCTest
@testable import yummy

@MainActor
final class MainIngredientsEditViewModelTests: XCTestCase {
    private var repository: MockFormulaRepository!
    private var baseFormula: Formula!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockFormulaRepository()
        baseFormula = Formula(
            name: "测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "鸡胸肉", quantity: "200g", category: nil),
                    Ingredient(name: "胡萝卜", quantity: "1根", category: nil)
                ],
                spicesSeasonings: [
                    Ingredient(name: "盐", quantity: "2g", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "生抽", quantity: "1勺")
                ]
            ),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: Date(),
            state: .finish
        )
        baseFormula.id = "test-formula-id"
        repository.mockFormulas = [baseFormula]
    }

    override func tearDown() async throws {
        repository = nil
        baseFormula = nil
        try await super.tearDown()
    }

    // MARK: - 初始化
    func testInitialization_MainIngredients() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .mainIngredients,
            formulaRepository: repository
        )

        XCTAssertEqual(vm.editedIngredients, baseFormula.ingredients.mainIngredients)
        XCTAssertTrue(vm.editedSauceIngredients.isEmpty)
        XCTAssertFalse(vm.hasChanges)
        XCTAssertFalse(vm.canSave)
    }

    func testInitialization_SpicesSeasonings() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .spicesSeasonings,
            formulaRepository: repository
        )

        XCTAssertEqual(vm.editedIngredients, baseFormula.ingredients.spicesSeasonings)
        XCTAssertTrue(vm.editedSauceIngredients.isEmpty)
        XCTAssertFalse(vm.hasChanges)
        XCTAssertFalse(vm.canSave)
    }

    func testInitialization_Sauce() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .sauce,
            formulaRepository: repository
        )

        XCTAssertEqual(vm.editedSauceIngredients, baseFormula.ingredients.sauce)
        XCTAssertTrue(vm.editedIngredients.isEmpty)
        XCTAssertFalse(vm.hasChanges)
        XCTAssertFalse(vm.canSave)
    }

    // MARK: - 增删与校验
    func testAddNewIngredient_Main_AndCanSaveRule() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .mainIngredients,
            formulaRepository: repository
        )

        // 初始不允许保存
        XCTAssertFalse(vm.canSave)

        // 添加空白项：name 为 ""，quantity 为 "适量"，不满足保存条件
        vm.addNewIngredient()
        XCTAssertTrue(vm.hasChanges)
        XCTAssertFalse(vm.canSave)

        // 填写有效内容后允许保存
        vm.editedIngredients[vm.editedIngredients.count - 1] = Ingredient(name: "土豆", quantity: "2个", category: nil)
        XCTAssertTrue(vm.canSave)
    }

    func testRemoveIngredient_SafeBounds_Main() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .mainIngredients,
            formulaRepository: repository
        )

        let originalCount = vm.editedIngredients.count
        vm.removeIngredient(at: -1) // 越界不应崩溃
        vm.removeIngredient(at: originalCount) // 越界不应崩溃
        XCTAssertEqual(vm.editedIngredients.count, originalCount)

        vm.removeIngredient(at: 0)
        XCTAssertEqual(vm.editedIngredients.count, max(0, originalCount - 1))
    }

    func testReset_RestoresOriginal() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .sauce,
            formulaRepository: repository
        )

        // 修改
        var modified = vm.editedSauceIngredients
        modified.append(SauceIngredient(name: "蚝油", quantity: "半勺"))
        vm.editedSauceIngredients = modified
        XCTAssertTrue(vm.hasChanges)

        // 重置应恢复
        vm.reset()
        XCTAssertEqual(vm.editedSauceIngredients, baseFormula.ingredients.sauce)
        XCTAssertFalse(vm.hasChanges)
    }

    // MARK: - 保存逻辑
    func testSave_MainIngredients_SuccessUpdatesRepository() async throws {
        let changed = baseFormula!
        let vm = MainIngredientsEditViewModel(
            formula: changed,
            editType: .mainIngredients,
            formulaRepository: repository
        )

        // 添加一项并设置有效值以满足 canSave
        vm.addNewIngredient()
        vm.editedIngredients[vm.editedIngredients.count - 1] = Ingredient(name: "洋葱", quantity: "50g", category: nil)
        XCTAssertTrue(vm.canSave)

        await vm.save()

        XCTAssertTrue(repository.updateCalled)
        // 校验仓库中的记录被更新
        let updated = repository.formula(withId: changed.id)
        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.id, changed.id)
        XCTAssertEqual(updated?.ingredients.mainIngredients, vm.editedIngredients)
        // 其它字段保持不变
        XCTAssertEqual(updated?.ingredients.spicesSeasonings, changed.ingredients.spicesSeasonings)
        XCTAssertEqual(updated?.ingredients.sauce, changed.ingredients.sauce)
        XCTAssertEqual(updated?.name, changed.name)
    }

    func testSave_Sauce_InvalidThenValid() async throws {
        let vm = MainIngredientsEditViewModel(
            formula: baseFormula,
            editType: .sauce,
            formulaRepository: repository
        )

        // 添加空白蘸料 -> 不可保存
        vm.addNewIngredient()
        XCTAssertFalse(vm.canSave)

        // 补全有效
        vm.editedSauceIngredients[vm.editedSauceIngredients.count - 1] = SauceIngredient(name: "辣椒油", quantity: "1勺")
        XCTAssertTrue(vm.canSave)

        await vm.save()
        XCTAssertTrue(repository.updateCalled)
    }
}


