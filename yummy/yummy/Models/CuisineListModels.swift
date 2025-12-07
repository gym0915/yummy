//
//  CuisineListModels.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import Foundation

// MARK: - 列表项类型
enum CuisineItemType: String, Codable {
    case ingredient = "ingredient"          // 采购食材
    case preparationStep = "preparation"    // 备菜步骤
    case saucePreparation = "sauce"        // 酱汁调制
}

// MARK: - 通用列表项
struct CuisineListItem: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let formulaId: String
    let formulaName: String
    
    // 内容信息
    let title: String           // 主标题
    let subtitle: String        // 副标题（数量/详情）
    let type: CuisineItemType   // 项目类型
    
    // 位置管理
    let originalIndex: Int      // 原始位置（永不改变）
    var isCompleted: Bool = false // 是否已完成
    
    // 时间戳
    var createdAt: Date         // 修复编码问题：改为var
    var updatedAt: Date         // 修复编码问题：移除默认值
    
    init(formulaId: String, formulaName: String, title: String, subtitle: String, type: CuisineItemType, originalIndex: Int, isCompleted: Bool = false) {
        // 使用稳定的ID：formulaId + type + originalIndex，确保每次生成相同
        self.id = "\(formulaId)_\(type.rawValue)_\(originalIndex)"
        self.formulaId = formulaId
        self.formulaName = formulaName
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.originalIndex = originalIndex
        self.isCompleted = isCompleted
        self.createdAt = Date() // 在初始化器中设置
        self.updatedAt = Date() // 在初始化器中设置
    }
}

// MARK: - Tab页面状态
struct CuisineTabStatus: Codable, Identifiable, Equatable {
    let id: String
    let formulaId: String
    let formulaName: String
    let tabType: CuisineTab
    var items: [CuisineListItem]
    var createdAt: Date         // 修复编码问题：改为var
    var updatedAt: Date         // 修复编码问题：移除默认值
    
    init(formulaId: String, formulaName: String, tabType: CuisineTab, items: [CuisineListItem] = []) {
        // 使用稳定的ID：formulaId + tabType，确保每次生成相同
        self.id = "\(formulaId)_\(tabType.rawValue)"
        self.formulaId = formulaId
        self.formulaName = formulaName
        self.tabType = tabType
        self.items = items
        self.createdAt = Date() // 在初始化器中设置
        self.updatedAt = Date() // 在初始化器中设置
    }
    
    // MARK: - 计算属性
    
    /// 完成进度
    var progress: Double {
        guard !items.isEmpty else { return 0 }
        let completedCount = items.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(items.count)
    }
    
    /// 按显示顺序排序的项目（核心排序逻辑）
    var sortedItems: [CuisineListItem] {
        let completed = items.filter { $0.isCompleted }.sorted { $0.updatedAt < $1.updatedAt }
        let uncompleted = items.filter { !$0.isCompleted }.sorted { $0.originalIndex < $1.originalIndex }
        return uncompleted + completed
    }
    
    /// 已完成数量
    var completedCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    /// 总数量
    var totalCount: Int {
        items.count
    }
    
    // MARK: - 方法
    
    /// 切换完成状态（核心交互逻辑）
    mutating func toggleItemCompletion(itemId: String) {
        AppLog("🔄 [CuisineTabStatus] 开始切换项目完成状态 - itemId: \(itemId)", level: .debug, category: .cuisine)
        
        if let index = items.firstIndex(where: { $0.id == itemId }) {
            let oldStatus = items[index].isCompleted
            items[index].isCompleted.toggle()
            items[index].updatedAt = Date()
            self.updatedAt = Date()
            
            AppLog("✅ [CuisineTabStatus] 状态切换成功 - itemId: \(itemId), 旧状态: \(oldStatus) -> 新状态: \(items[index].isCompleted)", level: .debug, category: .cuisine)
            AppLog("📊 [CuisineTabStatus] 更新统计 - 总项目数: \(items.count), 已完成: \(items.filter { $0.isCompleted }.count)", level: .debug, category: .cuisine)
        } else {
            AppLog("❌ [CuisineTabStatus] 找不到项目 - itemId: \(itemId)", level: .warning, category: .cuisine)
        }
    }
    
    /// 从Formula创建采购Tab状态
    static func createProcurementTab(from formula: Formula) -> CuisineTabStatus {
        var items: [CuisineListItem] = []
        var index = 0
        
        // 主料
        for ingredient in formula.ingredients.mainIngredients {
            items.append(CuisineListItem(
                formulaId: formula.id,
                formulaName: formula.name,
                title: ingredient.name,
                subtitle: ingredient.quantity,
                type: .ingredient,
                originalIndex: index
            ))
            index += 1
        }
        
        // 辛料
        for ingredient in formula.ingredients.spicesSeasonings {
            items.append(CuisineListItem(
                formulaId: formula.id,
                formulaName: formula.name,
                title: ingredient.name,
                subtitle: ingredient.quantity,
                type: .ingredient,
                originalIndex: index
            ))
            index += 1
        }
        
        // 蘸料
        for sauce in formula.ingredients.sauce {
            items.append(CuisineListItem(
                formulaId: formula.id,
                formulaName: formula.name,
                title: sauce.name,
                subtitle: sauce.quantity,
                type: .ingredient,
                originalIndex: index
            ))
            index += 1
        }
        
        return CuisineTabStatus(
            formulaId: formula.id,
            formulaName: formula.name,
            tabType: .procurement,
            items: items
        )
    }
    
    /// 从Formula创建备菜Tab状态
    static func createPreparationTab(from formula: Formula) -> CuisineTabStatus {
        var items: [CuisineListItem] = []
        var index = 0
        
        // 准备工作步骤
        for prep in formula.preparation {
            items.append(CuisineListItem(
                formulaId: formula.id,
                formulaName: formula.name,
                title: prep.step,
                subtitle: prep.details,
                type: .preparationStep,
                originalIndex: index
            ))
            index += 1
        }
        
        // 酱汁调制（作为备菜的一个整体项目）
        if !formula.ingredients.sauce.isEmpty {
            // 将所有酱料名称组合作为 subtitle
            let sauceNames = formula.ingredients.sauce.map { $0.name }.joined(separator: "、")
            items.append(CuisineListItem(
                formulaId: formula.id,
                formulaName: formula.name,
                title: "料汁",
                subtitle: sauceNames,
                type: .saucePreparation,
                originalIndex: index
            ))
            index += 1
        }
        
        return CuisineTabStatus(
            formulaId: formula.id,
            formulaName: formula.name,
            tabType: .prepare,
            items: items
        )
    }
    
    /// 从Formula创建料理Tab状态
    static func createCuisineTab(from formula: Formula) -> CuisineTabStatus {
        var items: [CuisineListItem] = []
        var index = 0
        
        // 料理步骤
        for step in formula.steps {
            items.append(CuisineListItem(
                formulaId: formula.id,
                formulaName: formula.name,
                title: step.step,
                subtitle: step.details,
                type: .preparationStep, // 复用preparationStep类型
                originalIndex: index
            ))
            index += 1
        }
        
        return CuisineTabStatus(
            formulaId: formula.id,
            formulaName: formula.name,
            tabType: .cuisine,
            items: items
        )
    }
}

// MARK: - Tab枚举
enum CuisineTab: String, Codable, CaseIterable {
    case procurement = "procurement"
    case prepare = "prepare"
    case cuisine = "cuisine"
    
    var displayName: String {
        switch self {
        case .procurement: return "采购"
        case .prepare: return "备菜"
        case .cuisine: return "料理"
        }
    }
}