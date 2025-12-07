import SwiftUI
import Combine

@MainActor
class MainIngredientsEditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var editedIngredients: [Ingredient]
    @Published var editedSauceIngredients: [SauceIngredient]

    // MARK: - Private Properties
    private let originalFormula: Formula
    private let formulaRepository: FormulaRepositoryProtocol
    private let editType: IngredientEditType

    // MARK: - Init
    init(formula: Formula, editType: IngredientEditType, formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared) {
        self.originalFormula = formula
        self.formulaRepository = formulaRepository
        self.editType = editType
        
        // 根据编辑类型初始化不同的数据
        switch editType {
        case .mainIngredients:
            self.editedIngredients = formula.ingredients.mainIngredients
            self.editedSauceIngredients = []
        case .spicesSeasonings:
            self.editedIngredients = formula.ingredients.spicesSeasonings
            self.editedSauceIngredients = []
        case .sauce:
            self.editedIngredients = []
            self.editedSauceIngredients = formula.ingredients.sauce
        }
    }

    // MARK: - Computed
    var hasChanges: Bool {
        switch editType {
        case .mainIngredients:
            return editedIngredients != originalFormula.ingredients.mainIngredients
        case .spicesSeasonings:
            return editedIngredients != originalFormula.ingredients.spicesSeasonings
        case .sauce:
            return editedSauceIngredients != originalFormula.ingredients.sauce
        }
    }

    var canSave: Bool {
        guard hasChanges else { return false }
        
        switch editType {
        case .mainIngredients, .spicesSeasonings:
            return !editedIngredients.isEmpty &&
                   editedIngredients.allSatisfy { ing in
                       !ing.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       !ing.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   }
        case .sauce:
            return !editedSauceIngredients.isEmpty &&
                   editedSauceIngredients.allSatisfy { ing in
                       !ing.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       !ing.quantity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   }
        }
    }

    // MARK: - Public Methods
    func addNewIngredient() {
        switch editType {
        case .mainIngredients, .spicesSeasonings:
            let newIngredient = Ingredient(name: "", quantity: "适量", category: nil)
            editedIngredients.append(newIngredient)
            AppLog("添加\(editType.title)空白项", level: .debug, category: .ui)
        case .sauce:
            let newSauceIngredient = SauceIngredient(name: "", quantity: "适量")
            editedSauceIngredients.append(newSauceIngredient)
            AppLog("添加\(editType.title)空白项", level: .debug, category: .ui)
        }
    }

    func removeIngredient(at index: Int) {
        switch editType {
        case .mainIngredients, .spicesSeasonings:
            guard index >= 0 && index < editedIngredients.count else { return }
            let removed = editedIngredients[index]
            editedIngredients.remove(at: index)
            AppLog("删除\(editType.title): \(removed.name)", level: .info, category: .ui)
        case .sauce:
            guard index >= 0 && index < editedSauceIngredients.count else { return }
            let removed = editedSauceIngredients[index]
            editedSauceIngredients.remove(at: index)
            AppLog("删除\(editType.title): \(removed.name)", level: .info, category: .ui)
        }
    }

    func save() async {
        guard canSave else {
            AppLog("保存失败: 条件不满足", level: .warning, category: .ui)
            ToastManager.shared.show("保存失败: 条件不满足", style: .warning, position: .top)
            return
        }

        do {
            // 根据编辑类型构造新的 Ingredients
            let newIngredients: Ingredients
            switch editType {
            case .mainIngredients:
                newIngredients = Ingredients(
                    mainIngredients: editedIngredients,
                    spicesSeasonings: originalFormula.ingredients.spicesSeasonings,
                    sauce: originalFormula.ingredients.sauce
                )
            case .spicesSeasonings:
                newIngredients = Ingredients(
                    mainIngredients: originalFormula.ingredients.mainIngredients,
                    spicesSeasonings: editedIngredients,
                    sauce: originalFormula.ingredients.sauce
                )
            case .sauce:
                newIngredients = Ingredients(
                    mainIngredients: originalFormula.ingredients.mainIngredients,
                    spicesSeasonings: originalFormula.ingredients.spicesSeasonings,
                    sauce: editedSauceIngredients
                )
            }

            // 构造新的 Formula，保持原有其他字段
            var updatedFormula = Formula(
                name: originalFormula.name,
                ingredients: newIngredients,
                tools: originalFormula.tools,
                preparation: originalFormula.preparation,
                steps: originalFormula.steps,
                tips: originalFormula.tips,
                tags: originalFormula.tags,
                date: originalFormula.date,
                prompt: originalFormula.prompt,
                state: originalFormula.state,
                imgpath: originalFormula.imgpath,
                isCuisine: originalFormula.isCuisine
            )
            updatedFormula.id = originalFormula.id

            try await formulaRepository.update(updatedFormula)

            let count = editType == .sauce ? editedSauceIngredients.count : editedIngredients.count
            AppLog("\(editType.title)保存成功: 共 \(count) 项", level: .info, category: .coredata)
            ToastManager.shared.show("保存成功", style: .success, position: .top)
        } catch {
            AppLog("保存\(editType.title)失败: \(error.localizedDescription)", level: .error, category: .coredata)
            ToastManager.shared.show("保存失败: \(error.localizedDescription)", style: .error, position: .top)
        }
    }

    func reset() {
        switch editType {
        case .mainIngredients:
            editedIngredients = originalFormula.ingredients.mainIngredients
        case .spicesSeasonings:
            editedIngredients = originalFormula.ingredients.spicesSeasonings
        case .sauce:
            editedSauceIngredients = originalFormula.ingredients.sauce
        }
        AppLog("重置\(editType.title)编辑状态", level: .debug, category: .ui)
    }
}
