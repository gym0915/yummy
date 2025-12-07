//
//  StepsEditViewModel.swift
//  yummy
//
//  Created by steve on 2025/9/9.
//

import SwiftUI
import Combine

// MARK: - 步骤编辑类型枚举
enum StepEditType {
    case preparation
    case cooking
    case tips
    
    var title: String {
        switch self {
        case .preparation:
            return "备菜"
        case .cooking:
            return "料理"
        case .tips:
            return "小窍门"
        }
    }
    
    var iconName: String {
        switch self {
        case .preparation:
            return "icon-prepare"
        case .cooking:
            return "icon-cook"
        case .tips:
            return "icon-tips"
        }
    }
    
    var emptyMessage: String {
        switch self {
        case .preparation:
            return "暂无备菜步骤，点击右上角加号添加"
        case .cooking:
            return "暂无料理步骤，点击右上角加号添加"
        case .tips:
            return "暂无小窍门，点击右上角加号添加"
        }
    }
    
    var placeholder: String {
        switch self {
        case .preparation:
            return "请输入备菜步骤"
        case .cooking:
            return "请输入料理步骤"
        case .tips:
            return "请输入小窍门"
        }
    }
    
    var maxLength: Int {
        switch self {
        case .preparation, .tips, .cooking:
            return 150
        }
    }
}

@MainActor
class StepsEditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var editedPreparationSteps: [PreparationStep] = []
    @Published var editedCookingSteps: [CookingStep] = []
    @Published var editedTips: [String] = []

    // MARK: - Private Properties
    private let originalFormula: Formula
    private let formulaRepository: FormulaRepositoryProtocol
    private let editType: StepEditType

    // MARK: - Init
    init(formula: Formula, editType: StepEditType, formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared) {
        self.originalFormula = formula
        self.formulaRepository = formulaRepository
        self.editType = editType
        
        // 根据编辑类型初始化不同的数据
        switch editType {
        case .preparation:
            self.editedPreparationSteps = formula.preparation
        case .cooking:
            self.editedCookingSteps = formula.steps
        case .tips:
            self.editedTips = formula.tips
        }
    }

    // MARK: - Computed Properties
    var hasChanges: Bool {
        switch editType {
        case .preparation:
            return editedPreparationSteps != originalFormula.preparation
        case .cooking:
            return editedCookingSteps != originalFormula.steps
        case .tips:
            return editedTips != originalFormula.tips
        }
    }

    var canSave: Bool {
        guard hasChanges else { return false }
        
        switch editType {
        case .preparation:
            return !editedPreparationSteps.isEmpty &&
                   editedPreparationSteps.allSatisfy { step in
                       !step.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   }
        case .cooking:
            return !editedCookingSteps.isEmpty &&
                   editedCookingSteps.allSatisfy { step in
                       !step.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   }
        case .tips:
            return !editedTips.isEmpty &&
                   editedTips.allSatisfy { tip in
                       !tip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                   }
        }
    }

    var currentStepCount: Int {
        switch editType {
        case .preparation:
            return editedPreparationSteps.count
        case .cooking:
            return editedCookingSteps.count
        case .tips:
            return editedTips.count
        }
    }

    // MARK: - Public Methods
    func addNewStep() {
        switch editType {
        case .preparation:
            let newStep = PreparationStep(step: "", details: "")
            editedPreparationSteps.append(newStep)
            AppLog("添加\(editType.title)空白项", level: .debug, category: .ui)
        case .cooking:
            let newStep = CookingStep(step: "", details: "")
            editedCookingSteps.append(newStep)
            AppLog("添加\(editType.title)空白项", level: .debug, category: .ui)
        case .tips:
            editedTips.append("")
            AppLog("添加\(editType.title)空白项", level: .debug, category: .ui)
        }
    }

    func removeStep(at index: Int) {
        switch editType {
        case .preparation:
            guard index >= 0 && index < editedPreparationSteps.count else { return }
            let removed = editedPreparationSteps[index]
            editedPreparationSteps.remove(at: index)
            AppLog("删除\(editType.title): \(removed.details)", level: .info, category: .ui)
        case .cooking:
            guard index >= 0 && index < editedCookingSteps.count else { return }
            let removed = editedCookingSteps[index]
            editedCookingSteps.remove(at: index)
            AppLog("删除\(editType.title): \(removed.details)", level: .info, category: .ui)
        case .tips:
            guard index >= 0 && index < editedTips.count else { return }
            let removed = editedTips[index]
            editedTips.remove(at: index)
            AppLog("删除\(editType.title): \(removed)", level: .info, category: .ui)
        }
    }

    func updateStepDetails(at index: Int, details: String) {
        switch editType {
        case .preparation:
            guard index >= 0 && index < editedPreparationSteps.count else { return }
            let currentStep = editedPreparationSteps[index]
            editedPreparationSteps[index] = PreparationStep(step: currentStep.step, details: details)
        case .cooking:
            guard index >= 0 && index < editedCookingSteps.count else { return }
            let currentStep = editedCookingSteps[index]
            editedCookingSteps[index] = CookingStep(step: currentStep.step, details: details)
        case .tips:
            guard index >= 0 && index < editedTips.count else { return }
            editedTips[index] = details
        }
    }

    func save() async {
        guard canSave else {
            AppLog("保存失败: 条件不满足", level: .warning, category: .ui)
            ToastManager.shared.show("保存失败: 条件不满足", style: .warning, position: .top)
            return
        }

        do {
            // 根据编辑类型构造新的 Formula
            let updatedFormula: Formula
            switch editType {
            case .preparation:
                updatedFormula = Formula(
                    name: originalFormula.name,
                    ingredients: originalFormula.ingredients,
                    tools: originalFormula.tools,
                    preparation: editedPreparationSteps,
                    steps: originalFormula.steps,
                    tips: originalFormula.tips,
                    tags: originalFormula.tags,
                    date: originalFormula.date,
                    prompt: originalFormula.prompt,
                    state: originalFormula.state,
                    imgpath: originalFormula.imgpath,
                    isCuisine: originalFormula.isCuisine
                )
            case .cooking:
                updatedFormula = Formula(
                    name: originalFormula.name,
                    ingredients: originalFormula.ingredients,
                    tools: originalFormula.tools,
                    preparation: originalFormula.preparation,
                    steps: editedCookingSteps,
                    tips: originalFormula.tips,
                    tags: originalFormula.tags,
                    date: originalFormula.date,
                    prompt: originalFormula.prompt,
                    state: originalFormula.state,
                    imgpath: originalFormula.imgpath,
                    isCuisine: originalFormula.isCuisine
                )
            case .tips:
                updatedFormula = Formula(
                    name: originalFormula.name,
                    ingredients: originalFormula.ingredients,
                    tools: originalFormula.tools,
                    preparation: originalFormula.preparation,
                    steps: originalFormula.steps,
                    tips: editedTips,
                    tags: originalFormula.tags,
                    date: originalFormula.date,
                    prompt: originalFormula.prompt,
                    state: originalFormula.state,
                    imgpath: originalFormula.imgpath,
                    isCuisine: originalFormula.isCuisine
                )
            }

            // 保持原有的 id
            var finalFormula = updatedFormula
            finalFormula.id = originalFormula.id

            try await formulaRepository.update(finalFormula)

            let count = currentStepCount
            AppLog("\(editType.title)保存成功: 共 \(count) 项", level: .info, category: .coredata)
            ToastManager.shared.show("保存成功", style: .success, position: .top)
        } catch {
            AppLog("保存\(editType.title)失败: \(error.localizedDescription)", level: .error, category: .coredata)
            ToastManager.shared.show("保存失败: \(error.localizedDescription)", style: .error, position: .top)
        }
    }

    func reset() {
        switch editType {
        case .preparation:
            editedPreparationSteps = originalFormula.preparation
        case .cooking:
            editedCookingSteps = originalFormula.steps
        case .tips:
            editedTips = originalFormula.tips
        }
        AppLog("重置\(editType.title)编辑状态", level: .debug, category: .ui)
    }
}
