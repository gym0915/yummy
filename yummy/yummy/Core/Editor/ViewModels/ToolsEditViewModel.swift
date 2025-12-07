//
//  ToolsEditViewModel.swift
//  yummy
//
//  Created by steve on 2025/9/8.
//

import SwiftUI
import Combine

@MainActor
class ToolsEditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var editedTools: [Tool] = []
    @Published var newToolText: String = ""
    
    // MARK: - Private Properties
    private let originalFormula: Formula
    private let maxTagCount: Int
    private let maxTagLength: Int
    private let formulaRepository: FormulaRepositoryProtocol
    
    // MARK: - Computed Properties
    
    /// 是否可以添加新厨具
    var canAddTool: Bool {
        let trimmedText = newToolText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty &&
        trimmedText.count <= maxTagLength &&
        !editedTools.contains(where: { $0.name.caseInsensitiveCompare(trimmedText) == .orderedSame }) &&
        editedTools.count < maxTagCount
    }
    
    /// 是否可以保存（有变化且至少有一个厨具）
    var canSave: Bool {
        let hasChanges = editedTools != originalFormula.tools
        let hasTools = !editedTools.isEmpty
        return hasChanges && hasTools
    }
    
    // MARK: - Initialization
    
    /// 初始化厨具编辑ViewModel
    /// - Parameters:
    ///   - formula: 原始菜谱数据
    ///   - maxTagCount: 最大标签数量，默认8个
    ///   - maxTagLength: 最大标签长度，默认6个字符
    ///   - formulaRepository: 菜谱仓库，用于数据持久化
    init(formula: Formula,
         maxTagCount: Int = 8, 
         maxTagLength: Int = 6,
         formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared) {
        self.originalFormula = formula
        self.editedTools = formula.tools
        self.maxTagCount = maxTagCount
        self.maxTagLength = maxTagLength
        self.formulaRepository = formulaRepository
    }
    
    // MARK: - Public Methods
    
    /// 添加新厨具
    func addNewTool() {
        let trimmedText = newToolText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard canAddTool else {
            // 如果因为重复（即使是大小写不同）而无法添加，也清空文本框
            if editedTools.contains(where: { $0.name.caseInsensitiveCompare(trimmedText) == .orderedSame }) {
                newToolText = ""
            }
            return
        }
        
        let newTool = Tool(name: trimmedText)
        editedTools.append(newTool)
        newToolText = ""
    }
    
    /// 删除厨具
    func removeTool(at index: Int) {
        guard index >= 0 && index < editedTools.count else {
            return
        }
        
        editedTools.remove(at: index)
    }
    
    /// 保存厨具数据到仓库
    /// - Returns: 保存是否成功
    @discardableResult
    func saveTools() async -> Bool {
        do {
            // 创建新的 Formula 实例，更新厨具数据
            let updatedFormula = Formula(
                name: originalFormula.name,
                ingredients: originalFormula.ingredients,
                tools: editedTools, // 更新厨具数据
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
            
            // 保持相同的 ID
            var finalFormula = updatedFormula
            finalFormula.id = originalFormula.id
            
            // 保存到仓库
            try await formulaRepository.update(finalFormula)
            
            AppLog("✅ [厨具编辑] 厨具数据保存成功 - 菜谱: \(finalFormula.name), 厨具数量: \(editedTools.count)", level: .info, category: .viewmodel)
            
            // 显示保存成功提示
            ToastManager.shared.show("保存成功", style: .success, position: .top)
            
            return true
        } catch {
            AppLog("❌ [厨具编辑] 厨具数据保存失败: \(error.localizedDescription)", level: .error, category: .viewmodel)
            
            // 显示保存失败提示
            ToastManager.shared.show("保存失败: \(error.localizedDescription)", style: .error, position: .top)
            
            return false
        }
    }
}
