import XCTest
@testable import yummy

@MainActor
final class NameAndTagsEditViewModelTests: XCTestCase {
    private var repository: MockFormulaRepository!
    private var baseFormula: Formula!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockFormulaRepository()
        baseFormula = Formula(
            name: "番茄炒蛋",
            ingredients: Ingredients(),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: ["家常", "快手"],
            date: Date(),
            state: .finish
        )
        baseFormula.id = "name-tags-formula-id"
        repository.mockFormulas = [baseFormula]
    }

    override func tearDown() async throws {
        repository = nil
        baseFormula = nil
        try await super.tearDown()
    }

    // MARK: - 初始化
    func testInitialization() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)
        XCTAssertEqual(vm.editedName, baseFormula.name)
        XCTAssertEqual(vm.editedTags, baseFormula.tags)
        XCTAssertEqual(vm.newTagText, "")
        XCTAssertFalse(vm.hasChanges)
        XCTAssertFalse(vm.canSave)
    }

    // MARK: - 名称校验
    func testNameValidation() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)
        XCTAssertFalse(vm.isNameValid(""))
        XCTAssertFalse(vm.isNameValid("   "))
        // 15个字符超长（上限14）
        XCTAssertFalse(vm.isNameValid(String(repeating: "啊", count: 15)))
        XCTAssertTrue(vm.isNameValid("红烧肉"))
        XCTAssertTrue(vm.isNameValid(String(repeating: "一", count: 14)))
    }

    // MARK: - 标签校验
    func testTagValidationAndCanAddRules() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)

        // 基础校验
        XCTAssertFalse(vm.isTagValid(""))
        XCTAssertFalse(vm.isTagValid("   "))
        // 超过4个字符无效（5个汉字）
        XCTAssertFalse(vm.isTagValid("超过长度啦"))
        // 重复无效
        XCTAssertFalse(vm.isTagValid("家常"))
        // 合法
        XCTAssertTrue(vm.isTagValid("素"))

        // canAddTag 依赖 newTagText 与数量、重复
        vm.newTagText = "素"
        XCTAssertTrue(vm.canAddTag)

        // 添加到3个后不再允许
        vm.addNewTag()
        XCTAssertEqual(vm.editedTags.count, 3)
        XCTAssertEqual(vm.newTagText, "")

        // 再次尝试添加（已满）
        vm.newTagText = "辣"
        XCTAssertFalse(vm.canAddTag)

        // 重复标签不允许
        vm.newTagText = vm.editedTags.first ?? "家常"
        XCTAssertFalse(vm.canAddTag)
    }

    // MARK: - 增删标签
    func testAddAndRemoveTag() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)
        let originalCount = vm.editedTags.count

        vm.newTagText = "素"
        vm.addNewTag()
        XCTAssertEqual(vm.editedTags.count, originalCount + 1)
        XCTAssertEqual(vm.editedTags.last, "素")
        XCTAssertEqual(vm.newTagText, "")

        // 安全边界删除
        vm.removeTag(at: -1)
        vm.removeTag(at: vm.editedTags.count) // 越界
        XCTAssertEqual(vm.editedTags.count, originalCount + 1)

        vm.removeTag(at: vm.editedTags.count - 1)
        XCTAssertEqual(vm.editedTags.count, originalCount)
    }

    // MARK: - 保存逻辑
    func testSave_SuccessUpdatesRepository() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)

        // 修改名称触发 hasChanges / canSave
        vm.editedName = "西红柿炒蛋"
        XCTAssertTrue(vm.hasChanges)
        XCTAssertTrue(vm.canSave)

        await vm.save()
        XCTAssertTrue(repository.updateCalled)

        let updated = repository.formula(withId: baseFormula.id)
        XCTAssertNotNil(updated)
        XCTAssertEqual(updated?.id, baseFormula.id)
        XCTAssertEqual(updated?.name, "西红柿炒蛋")
        // 其它字段保持不变
        XCTAssertEqual(updated?.tags, baseFormula.tags)
    }

    func testSave_InvalidDoesNotCallRepository() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)
        // 不修改任何内容 -> canSave 为 false
        XCTAssertFalse(vm.canSave)
        await vm.save()
        XCTAssertFalse(repository.updateCalled)
    }

    // MARK: - 重置
    func testReset_RestoresOriginal() async throws {
        let vm = NameAndTagsEditViewModel(formula: baseFormula, formulaRepository: repository)
        vm.editedName = "新名字"
        vm.newTagText = "素"
        vm.addNewTag()
        XCTAssertTrue(vm.hasChanges)

        vm.reset()
        XCTAssertEqual(vm.editedName, baseFormula.name)
        XCTAssertEqual(vm.editedTags, baseFormula.tags)
        XCTAssertEqual(vm.newTagText, "")
        XCTAssertFalse(vm.hasChanges)
        XCTAssertFalse(vm.canSave)
    }
}


