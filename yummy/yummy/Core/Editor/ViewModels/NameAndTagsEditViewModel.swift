//
//  NameAndTagsEditViewModel.swift
//  yummy
//
//  Created by steve on 2025/1/7.
//

import Foundation
import SwiftUI
import Combine

/// NameAndTagsEditView 的 ViewModel，负责管理名字和标签编辑的业务逻辑和状态
@MainActor
class NameAndTagsEditViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 编辑中的菜谱名字
    @Published var editedName: String
    
    /// 编辑中的标签列表
    @Published var editedTags: [String]
    
    /// 新标签输入文本
    @Published var newTagText: String = ""
    
    // 移除 isSaving、errorMessage 和 showError 状态
    // 改用 ToastManager 来显示保存结果
    
    // MARK: - Private Properties
    
    /// 原始菜谱数据
    private let originalFormula: Formula
    
    /// FormulaRepository 依赖注入
    private let formulaRepository: FormulaRepositoryProtocol
    
    /// Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    
    private let maxNameLength = 14
    private let maxTagLength = 4
    private let maxTagCount = 3
    
    // MARK: - Computed Properties
    
    /// 是否有变更
    var hasChanges: Bool {
        editedName != originalFormula.name || editedTags != originalFormula.tags
    }
    
    /// 保存按钮是否可用
    var canSave: Bool {
        hasChanges && 
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 添加标签按钮是否可用
    var canAddTag: Bool {
        !newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editedTags.count < maxTagCount &&
        !editedTags.contains(newTagText.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    // MARK: - Initialization
    
    init(formula: Formula, formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared) {
        self.originalFormula = formula
        self.formulaRepository = formulaRepository
        self.editedName = formula.name
        self.editedTags = formula.tags
        
        setupValidation()
    }
    
    // MARK: - Private Methods
    
    /// 设置输入验证
    private func setupValidation() {
        // 字符限制现在由 EditTextFieldView 组件自动处理
        // 这里可以添加其他验证逻辑，如实时检查重复标签等
    }
    
    // MARK: - Public Methods
    
    /// 添加新标签
    func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard canAddTag else {
            AppLogger.shared.debug("无法添加标签: 条件不满足")
            return
        }
        
        editedTags.append(trimmedTag)
        newTagText = ""
        
        AppLogger.shared.debug("添加新标签: \(trimmedTag)")
    }
    
    /// 删除标签
    func removeTag(at index: Int) {
        guard index >= 0 && index < editedTags.count else {
            AppLogger.shared.warning("删除标签失败: 索引越界 \(index)")
            return
        }
        
        let removedTag = editedTags[index]
        editedTags.remove(at: index)
        
        AppLogger.shared.debug("删除标签: \(removedTag)")
    }
    
    /// 保存更改
    func save() async {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard canSave else {
            AppLogger.shared.warning("保存失败: 条件不满足")
            ToastManager.shared.show("保存失败: 条件不满足", style: .warning)
            return
        }
        
        do {
            // 创建更新后的 Formula
            var updatedFormula = Formula(
                name: trimmedName,
                ingredients: originalFormula.ingredients,
                tools: originalFormula.tools,
                preparation: originalFormula.preparation,
                steps: originalFormula.steps,
                tips: originalFormula.tips,
                tags: editedTags,
                date: originalFormula.date,
                prompt: originalFormula.prompt,
                state: originalFormula.state,
                imgpath: originalFormula.imgpath,
                isCuisine: originalFormula.isCuisine
            )
            // 保持原有的 id
            updatedFormula.id = originalFormula.id
            
            // 更新到 Repository
            try await formulaRepository.update(updatedFormula)
            
            AppLogger.shared.info("菜谱名字和标签保存成功: \(trimmedName), 标签: \(editedTags)")
            ToastManager.shared.show("保存成功", style: .success,position: .top)
            
        } catch {
            AppLogger.shared.error("保存菜谱失败: \(error.localizedDescription)")
            ToastManager.shared.show("保存失败: \(error.localizedDescription)", style: .error,position: .top)
        }
    }
    
    /// 重置到原始状态
    func reset() {
        editedName = originalFormula.name
        editedTags = originalFormula.tags
        newTagText = ""
        
        AppLogger.shared.debug("重置编辑状态")
    }
    

}

// MARK: - Validation Helpers

extension NameAndTagsEditViewModel {
    
    /// 验证名字是否有效
    func isNameValid(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxNameLength
    }
    
    /// 验证标签是否有效
    func isTagValid(_ tag: String) -> Bool {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && 
               trimmed.count <= maxTagLength && 
               !editedTags.contains(trimmed)
    }
    

}
