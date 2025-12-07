//
//  CuisineViewModel.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class CuisineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var cuisineFormulas: [Formula] = []
    @Published var selectedTab: CuisineTab = .procurement  // 确保默认 Tab 为采购
    @Published var tabStatuses: [CuisineTabStatus] = []
    // 修改为存储每个 tab 当前展开的单个菜谱 ID（nil 表示没有展开的）
    @Published var expandedFormulaIdsByTab: [CuisineTab: String?] = [:]
    
    // MARK: - Private Properties
    // 跟踪用户是否进行了手动交互（点击展开/收缩）
    private var hasUserInteracted = false
    
    // MARK: - Dependencies
    private let formulaRepository: FormulaRepositoryProtocol
    private let cuisineStateRepository: CuisineStateRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared,
         cuisineStateRepository: CuisineStateRepositoryProtocol = CuisineStateRepository.shared) {
        self.formulaRepository = formulaRepository
        self.cuisineStateRepository = cuisineStateRepository
        setupDataSubscription()
    }
    
    // MARK: - Private Methods
    
    private func setupDataSubscription() {
        AppLog("📚 [CuisineViewModel] 开始设置数据订阅", level: .debug, category: .viewmodel)
        
        // 标记是否是首次加载
        var isFirstLoad = true
        
        // 订阅料理清单
        formulaRepository.formulasPublisher
            .map { formulas in formulas.filter { $0.isCuisine } }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formulas in
                guard let self = self else { return }
                AppLog("📚 [CuisineViewModel] 收到菜谱更新 - 总数: \(formulas.count), 料理清单: \(formulas.count)", level: .debug, category: .viewmodel)
                self.cuisineFormulas = formulas
                
                // 只在首次加载时检查状态
                if isFirstLoad {
                    isFirstLoad = false
                    Task { 
                        await self.ensureTabStatusesExist(for: formulas) 
                    }
                }
                
                // 根据最新数据确保默认展开
                self.ensureDefaultExpandedForCurrentTab()
            }
            .store(in: &cancellables)
        
        // 订阅Tab状态
        cuisineStateRepository.cuisineTabStatusesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statuses in
                guard let self = self else { return }
                AppLog("📡 [CuisineViewModel] 收到Tab状态更新 - 状态数量: \(statuses.count)", level: .debug, category: .viewmodel)
                
                // 避免重复更新
                if self.tabStatuses != statuses {
                    self.tabStatuses = statuses
                    AppLog("✅ [CuisineViewModel] Tab状态已更新", level: .info, category: .viewmodel)
                } else {
                    AppLog("⏭️ [CuisineViewModel] Tab状态未变化，跳过更新", level: .debug, category: .viewmodel)
                }
                
                // 状态变化后确保默认展开
                self.ensureDefaultExpandedForCurrentTab()
            }
            .store(in: &cancellables)
        
        // 订阅选中 Tab 变化，切换时重置为该 Tab 的第一个卡片展开
        $selectedTab
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTab in
                // 移除自动调用 ensureDefaultExpandedForCurrentTab，防止覆盖 focusId 聚焦
                AppLog("📋 [CuisineViewModel] Tab 切换到: \(newTab.displayName)", level: .info, category: .viewmodel)
            }
            .store(in: &cancellables)
        
        AppLog("📚 [CuisineViewModel] 数据订阅设置完成", level: .debug, category: .viewmodel)
    }
    
    private func ensureTabStatusesExist(for formulas: [Formula]) async {
        AppLog("🔧 [CuisineViewModel] 检查Tab状态 - 菜谱数量: \(formulas.count)", level: .debug, category: .cuisine)
        
        for formula in formulas {
            AppLog("🔍 [CuisineViewModel] 检查菜谱: \(formula.name)", level: .debug, category: .cuisine)
            
            // 检查每个tab是否存在，只创建不存在的tab
            for tab in CuisineTab.allCases {
                let hasState = tabStatuses.contains { 
                    $0.formulaId == formula.id && $0.tabType == tab 
                }
//                AppLog("  - \(tab.displayName): \(hasState ? \"✅ 已存在\" : \"❌ 不存在\")", level: .debug, category: .cuisine)
                
                if !hasState {
                    AppLog("🆕 [CuisineViewModel] 为菜谱 \(formula.name) 创建 \(tab.displayName) Tab状态", level: .debug, category: .cuisine)
                    try? await cuisineStateRepository.createTabStatus(from: formula, tabType: tab)
                    AppLog("✅ [CuisineViewModel] 为菜谱 \(formula.name) 创建 \(tab.displayName) Tab状态完成", level: .debug, category: .cuisine)
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 切换项目完成状态（核心交互方法）
    func toggleItemCompletion(itemId: String, formulaId: String) async {
        AppLog("🔄 [CuisineViewModel] 开始切换项目状态 - itemId: \(itemId), formulaId: \(formulaId), tab: \(selectedTab.displayName)", level: .debug, category: .cuisine)

        // ✅ 使用@Published的tabStatuses属性获取状态
        guard var tabStatus = tabStatuses.first(where: {
            $0.formulaId == formulaId && $0.tabType == selectedTab
        }) else {
            AppLog("❌ [CuisineViewModel] 找不到Tab状态 - formulaId: \(formulaId), tab: \(selectedTab)", level: .error, category: .cuisine)
            return
        }

        AppLog("📋 [CuisineViewModel] 找到Tab状态 - 总项目数: \(tabStatus.items.count), 已完成: \(tabStatus.completedCount)", level: .debug, category: .cuisine)

        // 记录切换前的状态
        if let item = tabStatus.items.first(where: { $0.id == itemId }) {
            AppLog("📝 [CuisineViewModel] 切换前状态 - itemId: \(itemId), title: \(item.title), isCompleted: \(item.isCompleted)", level: .debug, category: .cuisine)
        }

        // 显示保存前的完整状态
        AppLog("💾 [CuisineViewModel] === 保存前状态 ===", level: .debug, category: .cuisine)
        for (index, item) in tabStatus.items.enumerated() {
            AppLog("  [\(index)] \(item.title) - 完成: \(item.isCompleted)", level: .debug, category: .cuisine)
        }

        tabStatus.toggleItemCompletion(itemId: itemId)

        // 记录切换后的状态
        if let item = tabStatus.items.first(where: { $0.id == itemId }) {
            AppLog("📝 [CuisineViewModel] 切换后状态 - itemId: \(itemId), title: \(item.title), isCompleted: \(item.isCompleted)", level: .debug, category: .cuisine)
        }

        // 显示保存后的完整状态
        AppLog("💾 [CuisineViewModel] === 保存后状态 ===", level: .debug, category: .cuisine)
        for (index, item) in tabStatus.items.enumerated() {
            AppLog("  [\(index)] \(item.title) - 完成: \(item.isCompleted)", level: .debug, category: .cuisine)
        }

        AppLog("💾 [CuisineViewModel] 准备保存状态 - 总项目数: \(tabStatus.items.count), 已完成: \(tabStatus.completedCount)", level: .debug, category: .cuisine)

        do {
            try await cuisineStateRepository.save(tabStatus)
            AppLog("✅ [CuisineViewModel] 项目状态更新成功 - Tab: \(selectedTab.displayName)", level: .info, category: .cuisine)
        } catch {
            AppLog("❌ [CuisineViewModel] 项目状态更新失败: \(error)", level: .error, category: .cuisine)
        }
    }
    
    /// 获取当前Tab的所有项目（已排序）
    func getCurrentTabItems() -> [CuisineListItem] {
        // ✅ 使用@Published的tabStatuses属性，确保UI响应式更新
        let allCurrentTabStatuses = tabStatuses.filter { $0.tabType == selectedTab }
        return allCurrentTabStatuses.flatMap { $0.sortedItems }
    }
    
    /// 获取当前Tab按Formula分组的数据
    func getGroupedTabItems() -> [(formula: Formula, items: [CuisineListItem])] {
        AppLog("📋 [CuisineViewModel] 获取分组数据 - tab: \(selectedTab.displayName), 菜谱数量: \(cuisineFormulas.count), 状态数量: \(tabStatuses.count)", level: .debug, category: .cuisine)
        
        // 调试：显示所有状态信息
        AppLog("🔍 [CuisineViewModel] 所有状态详情:", level: .debug, category: .cuisine)
        for (index, status) in tabStatuses.enumerated() {
            AppLog("  [\(index)] formulaId: \(status.formulaId), tab: \(status.tabType.displayName), 项目数: \(status.items.count)", level: .debug, category: .cuisine)
        }
        
        // 调试：显示所有菜谱信息
        AppLog("🔍 [CuisineViewModel] 所有菜谱详情:", level: .debug, category: .cuisine)
        for (index, formula) in cuisineFormulas.enumerated() {
            AppLog("  [\(index)] id: \(formula.id), name: \(formula.name), isCuisine: \(formula.isCuisine)", level: .debug, category: .cuisine)
        }
        
        // 调试：检查所有已保存菜谱的状态
        AppLog("🔍 [CuisineViewModel] 检查所有状态对应的菜谱:", level: .debug, category: .cuisine)
        for (index, status) in tabStatuses.enumerated() {
            let formulaExists = cuisineFormulas.contains { $0.id == status.formulaId }
//            AppLog("  [\(index)] formulaId: \(status.formulaId), tab: \(status.tabType.displayName), 菜谱存在: \(formulaExists ? \"✅\" : \"❌\")", level: .debug, category: .cuisine)
        }
        
        var result: [(formula: Formula, items: [CuisineListItem])] = []
        
        for formula in cuisineFormulas {
            // ✅ 使用@Published的tabStatuses属性，确保UI响应式更新
            if let tabStatus = tabStatuses.first(where: { 
                $0.formulaId == formula.id && $0.tabType == selectedTab 
            }) {
                let sortedItems = tabStatus.sortedItems
                if !sortedItems.isEmpty {
                    result.append((formula: formula, items: sortedItems))
                    AppLog("📝 [CuisineViewModel] 添加菜谱分组 - \(formula.name): \(sortedItems.count) 个项目", level: .debug, category: .cuisine)
                    
                    // 调试：显示项目详情
                    for (itemIndex, item) in sortedItems.enumerated() {
                        AppLog("    [\(itemIndex)] \(item.title) - 完成: \(item.isCompleted)", level: .debug, category: .cuisine)
                    }
                }
            } else {
                AppLog("⚠️ [CuisineViewModel] 菜谱 \(formula.name) 没有找到对应的Tab状态", level: .warning, category: .cuisine)
            }
        }
        
        AppLog("📊 [CuisineViewModel] 分组数据获取完成 - 总分组数: \(result.count)", level: .debug, category: .cuisine)
        return result
    }
    
    /// 获取特定菜谱在当前Tab的状态
    func getTabStatus(for formulaId: String) -> CuisineTabStatus? {
        // ✅ 使用@Published的tabStatuses属性，确保UI响应式更新
        tabStatuses.first { $0.formulaId == formulaId && $0.tabType == selectedTab }
    }
    
    /// 获取当前Tab的整体进度
    func getCurrentTabProgress() -> Double {
        let statuses = tabStatuses.filter { $0.tabType == selectedTab }
        guard !statuses.isEmpty else { return 0 }
        
        let totalProgress = statuses.reduce(0) { $0 + $1.progress }
        return totalProgress / Double(statuses.count)
    }
    
    /// 移除菜谱（同时清理Tab状态）
    func removeFromCuisine(formula: Formula) async {
        var updatedFormula = formula
        updatedFormula.isCuisine = false
        
        do {
            try await formulaRepository.save(updatedFormula)
            try await cuisineStateRepository.deleteTabStatuses(formulaId: formula.id)
            AppLog("✅ [料理清单] 移除成功 - \(formula.name)", level: .info, category: .cuisine)
        } catch {
            AppLog("❌ [料理清单] 移除失败 - \(formula.name): \(error)", level: .error, category: .cuisine)
        }
    }
    
    /// 根据 focusId 在当前 Tab 应用展开态（如果该菜谱在当前 Tab 可见）
    func applyFocusIfNeeded(_ focusId: String?) {
        // 如果用户已经进行了手动交互，则不再应用 focusId 聚焦
        if hasUserInteracted {
            AppLog("🚫 [CuisineViewModel] 用户已进行手动交互，跳过 focusId 聚焦", level: .debug, category: .viewmodel)
            return
        }
        
        guard let targetId = focusId else { 
            // 当 focusId 为 nil 时（如从 HomeView 进入），强制调用默认展开逻辑
            AppLog("🏠 [CuisineViewModel] focusId 为 nil，强制应用默认展开逻辑", level: .debug, category: .viewmodel)
            ensureDefaultExpandedForCurrentTab()
            return 
        }
        // 计算当前 Tab 可见的菜谱列表
        let visibleIds: [String]
        if selectedTab == .cuisine {
            visibleIds = cuisineFormulas.map { $0.id }
        } else {
            visibleIds = getGroupedTabItems().map { $0.formula.id }
        }
        guard visibleIds.contains(targetId) else {
            AppLog("⚠️ [CuisineViewModel] focusId 不在当前 Tab 可见列表中，跳过: \(targetId)", level: .warning, category: .viewmodel)
            return
        }
        AppLog("🎯 [CuisineViewModel] 应用聚焦展开 - id: \(targetId) @ Tab: \(selectedTab.displayName)", level: .debug, category: .viewmodel)
        expandedFormulaIdsByTab[selectedTab] = targetId
    }
    
    /// 清空所有料理清单
    func clearAllCuisineFormulas() async {
        AppLog("🗑️ [CuisineViewModel] 开始清空所有料理清单 - 数量: \(cuisineFormulas.count)", level: .debug, category: .cuisine)
        
        guard !cuisineFormulas.isEmpty else {
            AppLog("⚠️ [CuisineViewModel] 料理清单已为空，无需清空", level: .warning, category: .cuisine)
            return
        }
        
        do {
            // 先捕获一份待清理的 formulaId 列表，避免在保存后订阅回调导致列表被清空
            let formulaIdsToDelete = cuisineFormulas.map { $0.id }
            
            // 批量更新所有菜谱的 isCuisine 状态
            for formula in cuisineFormulas {
                var updatedFormula = formula
                updatedFormula.isCuisine = false
                try await formulaRepository.save(updatedFormula)
                AppLog("✅ [CuisineViewModel] 已移除料理清单 - \(formula.name)", level: .info, category: .cuisine)
            }
            
            // 批量删除所有相关的Tab状态
            for formulaId in formulaIdsToDelete {
                try await cuisineStateRepository.deleteTabStatuses(formulaId: formulaId)
                AppLog("✅ [CuisineViewModel] 已清理状态 - formulaId: \(formulaId)", level: .info, category: .cuisine)
            }
            
            AppLog("✅ [CuisineViewModel] 所有料理清单清空完成", level: .info, category: .cuisine)
        } catch {
            AppLog("❌ [CuisineViewModel] 清空料理清单失败: \(error)", level: .error, category: .cuisine)
        }
    }
    
    // MARK: - Computed Properties
    
    var cuisineCount: Int {
        cuisineFormulas.count
    }
    
    var isEmpty: Bool {
        cuisineFormulas.isEmpty
    }
    
    // MARK: - Debug Methods
    
    /// 调试方法：检查数据一致性
    func debugDataConsistency() {
        AppLog("🔍 [CuisineViewModel] === 数据一致性检查 ===", level: .debug, category: .cuisine)
        AppLog("📊 菜谱数量: \(cuisineFormulas.count)", level: .debug, category: .cuisine)
        AppLog("📊 状态数量: \(tabStatuses.count)", level: .debug, category: .cuisine)
        
        // 检查每个菜谱的状态
        for formula in cuisineFormulas {
            let formulaStatuses = tabStatuses.filter { $0.formulaId == formula.id }
            AppLog("📋 菜谱 '\(formula.name)': \(formulaStatuses.count) 个状态", level: .debug, category: .cuisine)
            
            for status in formulaStatuses {
                AppLog("  - \(status.tabType.displayName): \(status.items.count) 个项目, 已完成: \(status.completedCount)", level: .debug, category: .cuisine)
            }
        }
        
        // 检查孤立的状态
        let orphanedStatuses = tabStatuses.filter { status in
            !cuisineFormulas.contains { $0.id == status.formulaId }
        }
        
        if !orphanedStatuses.isEmpty {
            AppLog("⚠️ 发现 \(orphanedStatuses.count) 个孤立状态:", level: .warning, category: .cuisine)
            for status in orphanedStatuses {
                AppLog("  - formulaId: \(status.formulaId), tab: \(status.tabType.displayName)", level: .debug, category: .cuisine)
            }
        }
        
        AppLog("🔍 [CuisineViewModel] === 检查完成 ===", level: .debug, category: .cuisine)
    }
    
    /// 清理孤立的状态数据
    func cleanupOrphanedStates() async {
        AppLog("🧹 [CuisineViewModel] 开始清理孤立状态", level: .debug, category: .cuisine)

        let orphanedStatuses = tabStatuses.filter { status in
            !cuisineFormulas.contains { $0.id == status.formulaId }
        }

        if orphanedStatuses.isEmpty {
            AppLog("✅ [CuisineViewModel] 没有发现孤立状态", level: .debug, category: .cuisine)
            return
        }

        AppLog("🗑️ [CuisineViewModel] 发现 \(orphanedStatuses.count) 个孤立状态，准备清理", level: .debug, category: .cuisine)

        // 按 formulaId 分组删除
        let orphanedFormulaIds = Set(orphanedStatuses.map { $0.formulaId })

        for formulaId in orphanedFormulaIds {
            do {
                try await cuisineStateRepository.deleteTabStatuses(formulaId: formulaId)
                AppLog("✅ [CuisineViewModel] 已清理 formulaId: \(formulaId) 的状态", level: .info, category: .cuisine)
            } catch {
                AppLog("❌ [CuisineViewModel] 清理失败 formulaId: \(formulaId) - \(error)", level: .error, category: .cuisine)
            }
        }

        AppLog("🧹 [CuisineViewModel] 孤立状态清理完成", level: .debug, category: .cuisine)
    }
    
    // MARK: - 数据状态显示
    func displayCurrentDataState() {
        AppLog("📊 [CuisineViewModel] === 当前数据状态 ===", level: .debug, category: .cuisine)
        AppLog("📋 菜谱数量: \(cuisineFormulas.count)", level: .debug, category: .cuisine)
        AppLog("📋 状态数量: \(tabStatuses.count)", level: .debug, category: .cuisine)
        
        for (index, formula) in cuisineFormulas.enumerated() {
            AppLog("🍳 菜谱[\(index)]: \(formula.name) (ID: \(formula.id))", level: .debug, category: .cuisine)
            
            let formulaStatuses = tabStatuses.filter { $0.formulaId == formula.id }
            for status in formulaStatuses {
                AppLog("  📋 \(status.tabType.displayName): \(status.items.count) 个项目", level: .debug, category: .cuisine)
                for (itemIndex, item) in status.items.enumerated() {
                    AppLog("    [\(itemIndex)] \(item.title) - 完成: \(item.isCompleted)", level: .debug, category: .cuisine)
                }
            }
        }
        AppLog("📊 [CuisineViewModel] === 数据状态显示完成 ===", level: .debug, category: .cuisine)
    }
    
    // MARK: - 展开态管理
    
    /// 检查指定菜谱在当前Tab是否展开（单一展开：仅当其 ID 等于当前 Tab 的记录时为展开）
    func isExpanded(formulaId: String) -> Bool {
        let currentExpanded = expandedFormulaIdsByTab[selectedTab] ?? nil
        return currentExpanded == formulaId
    }
    
    /// 切换指定菜谱为展开（单一展开：点击即将该卡片设为唯一展开；再次点击已展开项则折叠）
    func toggleExpand(for formulaId: String) {
        // 标记用户已进行手动交互
        hasUserInteracted = true
        AppLog("👆 [CuisineViewModel] 用户手动交互，标记 hasUserInteracted = true", level: .debug, category: .viewmodel)
        
        let currentExpanded = expandedFormulaIdsByTab[selectedTab] ?? nil
        if currentExpanded == formulaId {
            AppLog("📂 [CuisineViewModel] 折叠当前展开菜谱: \(formulaId) 在 Tab: \(selectedTab.displayName)", level: .debug, category: .viewmodel)
            expandedFormulaIdsByTab[selectedTab] = nil
        } else {
            AppLog("📂 [CuisineViewModel] 设置唯一展开菜谱: \(formulaId) 在 Tab: \(selectedTab.displayName)", level: .debug, category: .viewmodel)
            expandedFormulaIdsByTab[selectedTab] = formulaId
        }
    }
    
    /// 确保当前 Tab 存在默认展开项：优先取该 Tab 可见列表的第一个
    /// 注意：不会覆盖已存在的聚焦展开状态，也不会在用户已交互后强制设置
    private func ensureDefaultExpandedForCurrentTab() {
        // 如果用户已经进行了手动交互，则不再强制设置默认展开
        if hasUserInteracted {
            AppLog("🚫 [CuisineViewModel] 用户已进行手动交互，跳过默认展开设置", level: .debug, category: .viewmodel)
            return
        }
        
        // 如果当前 Tab 已有展开状态，则保持不变（保护 focusId 聚焦状态）
        let currentExpanded = expandedFormulaIdsByTab[selectedTab] ?? nil
        if currentExpanded != nil {
            AppLog("🔒 [CuisineViewModel] Tab \(selectedTab.displayName) 已有展开状态，保持不变: \(currentExpanded!)", level: .debug, category: .viewmodel)
            return
        }
        
        // 计算当前 Tab 可见的菜谱 ID 列表
        let visibleFormulaIds: [String]
        if selectedTab == .cuisine {
            visibleFormulaIds = cuisineFormulas.map { $0.id }
        } else {
            visibleFormulaIds = getGroupedTabItems().map { $0.formula.id }
        }
        
        // 如果没有可见项，则清空展开记录
        guard let firstId = visibleFormulaIds.first else {
            expandedFormulaIdsByTab[selectedTab] = nil
            return
        }
        
        // 如当前记录为空，则设置为第一个
        AppLog("✨ [CuisineViewModel] 设置默认展开为第一个: \(firstId) 在 Tab: \(selectedTab.displayName)", level: .debug, category: .viewmodel)
        expandedFormulaIdsByTab[selectedTab] = firstId
    }
    
    /// 强制设置当前 Tab 的默认展开项（用于从 HomeView 进入时）
    /// 注意：会覆盖现有展开状态
    private func forceSetDefaultExpandedForCurrentTab() {
        // 计算当前 Tab 可见的菜谱 ID 列表
        let visibleFormulaIds: [String]
        if selectedTab == .cuisine {
            visibleFormulaIds = cuisineFormulas.map { $0.id }
        } else {
            visibleFormulaIds = getGroupedTabItems().map { $0.formula.id }
        }
        
        // 如果没有可见项，则清空展开记录
        guard let firstId = visibleFormulaIds.first else {
            expandedFormulaIdsByTab[selectedTab] = nil
            return
        }
        
        // 强制设置为第一个
        AppLog("🏠 [CuisineViewModel] 强制设置默认展开为第一个: \(firstId) 在 Tab: \(selectedTab.displayName)", level: .debug, category: .viewmodel)
        expandedFormulaIdsByTab[selectedTab] = firstId
    }
}
