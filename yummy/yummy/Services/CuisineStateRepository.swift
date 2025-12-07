//
//  CuisineStateRepository.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import Foundation
import Combine

protocol CuisineStateRepositoryProtocol {
    var cuisineTabStatusesPublisher: AnyPublisher<[CuisineTabStatus], Never> { get }
    func save(_ status: CuisineTabStatus) async throws
    func getTabStatus(formulaId: String, tab: CuisineTab) -> CuisineTabStatus?
    func createTabStatuses(from formula: Formula) async throws
    func createTabStatus(from formula: Formula, tabType: CuisineTab) async throws
    func deleteTabStatuses(formulaId: String) async throws
}

class CuisineStateRepository: CuisineStateRepositoryProtocol {
    static let shared = CuisineStateRepository()
    
    private let subject = CurrentValueSubject<[CuisineTabStatus], Never>([])
    var cuisineTabStatusesPublisher: AnyPublisher<[CuisineTabStatus], Never> {
        subject.eraseToAnyPublisher()
    }
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "cuisine_tab_statuses"
    
    private init() {
        loadFromStorage()
    }
    
    func save(_ status: CuisineTabStatus) async throws {
        AppLog("💾 [CuisineStateRepository] 开始保存Tab状态 - formulaId: \(status.formulaId), tab: \(status.tabType.displayName)", category: .coredata)
        AppLog("📊 [CuisineStateRepository] 状态详情 - 总项目数: \(status.items.count), 已完成: \(status.completedCount)", level: .debug, category: .coredata)
        
        await MainActor.run {
            var currentStatuses = subject.value
            AppLog("📋 [CuisineStateRepository] 当前内存中的状态数量: \(currentStatuses.count)", level: .debug, category: .coredata)
            
            // 更新或添加状态
            if let index = currentStatuses.firstIndex(where: { 
                $0.formulaId == status.formulaId && $0.tabType == status.tabType 
            }) {
                AppLog("🔄 [CuisineStateRepository] 更新现有状态 - 索引: \(index)", level: .debug, category: .coredata)
                currentStatuses[index] = status
            } else {
                AppLog("➕ [CuisineStateRepository] 添加新状态", level: .debug, category: .coredata)
                currentStatuses.append(status)
            }
            
            AppLog("💾 [CuisineStateRepository] 保存到UserDefaults - 状态数量: \(currentStatuses.count)", category: .coredata)
            do {
                let data = try JSONEncoder().encode(currentStatuses)
                userDefaults.set(data, forKey: storageKey)
                AppLog("✅ [CuisineStateRepository] UserDefaults保存成功 - 数据大小: \(data.count) bytes", category: .coredata)
                
                // 使用摘要日志记录大 JSON 数据
                AppLogDataSummary(data, description: "保存到UserDefaults的JSON数据", category: .coredata, level: .debug)

                // 验证保存是否成功
                if let savedData = userDefaults.data(forKey: storageKey) {
                    AppLog("✅ [CuisineStateRepository] 验证保存成功 - 读取数据大小: \(savedData.count) bytes", category: .coredata)
                } else {
                    AppLog("❌ [CuisineStateRepository] 验证保存失败 - 无法读取保存的数据", level: .error, category: .coredata)
                }
            } catch {
                AppLog("❌ [CuisineStateRepository] UserDefaults保存失败 - JSON编码错误: \(error)", level: .error, category: .coredata)
                AppLog("❌ [CuisineStateRepository] 错误详情: \(error.localizedDescription)", level: .error, category: .coredata)

                // 尝试逐个编码以找出问题
                for (index, status) in currentStatuses.enumerated() {
                    do {
                        let _ = try JSONEncoder().encode(status)
                        AppLog("✅ [CuisineStateRepository] 状态 \(index) 编码成功", level: .debug, category: .coredata)
                    } catch {
                        AppLog("❌ [CuisineStateRepository] 状态 \(index) 编码失败: \(error)", level: .error, category: .coredata)
                    }
                }
            }
            
            AppLog("📡 [CuisineStateRepository] 发布更新到订阅者", category: .coredata)
            subject.send(currentStatuses)
            
            AppLog("✅ [CuisineStateRepository] 保存完成", category: .coredata)
        }
    }
    
    func getTabStatus(formulaId: String, tab: CuisineTab) -> CuisineTabStatus? {
        subject.value.first { $0.formulaId == formulaId && $0.tabType == tab }
    }
    
    func createTabStatuses(from formula: Formula) async throws {
        let procurementStatus = CuisineTabStatus.createProcurementTab(from: formula)
        let preparationStatus = CuisineTabStatus.createPreparationTab(from: formula)
        
        try await save(procurementStatus)
        try await save(preparationStatus)
    }
    
    /// 创建单个tab状态（新增方法）
    func createTabStatus(from formula: Formula, tabType: CuisineTab) async throws {
        let status: CuisineTabStatus
        
        switch tabType {
        case .procurement:
            status = CuisineTabStatus.createProcurementTab(from: formula)
        case .prepare:
            status = CuisineTabStatus.createPreparationTab(from: formula)
        case .cuisine:
            status = CuisineTabStatus.createCuisineTab(from: formula)
        }
        
        try await save(status)
    }
    
    func deleteTabStatuses(formulaId: String) async throws {
        await MainActor.run {
            let filteredStatuses = subject.value.filter { $0.formulaId != formulaId }
            saveToStorage(filteredStatuses)
            subject.send(filteredStatuses)
        }
    }
    
    private func loadFromStorage() {
        AppLog("📚 [CuisineStateRepository] 开始从UserDefaults加载数据", category: .coredata)

        guard let data = userDefaults.data(forKey: storageKey) else {
            AppLog("📚 [CuisineStateRepository] 没有找到保存的数据，使用空数组", category: .coredata)
            subject.send([])
            return
        }

        AppLog("📚 [CuisineStateRepository] 找到保存的数据，大小: \(data.count) bytes", category: .coredata)
        
        // 使用摘要日志记录大 JSON 数据
        AppLogDataSummary(data, description: "从UserDefaults读取的JSON数据", category: .coredata, level: .debug)

        do {
            let statuses = try JSONDecoder().decode([CuisineTabStatus].self, from: data)
            subject.send(statuses)
            AppLog("✅ [CuisineStateRepository] 数据加载成功 - 状态数量: \(statuses.count)", category: .coredata)
        } catch {
            AppLog("❌ [CuisineStateRepository] 数据加载失败 - JSON解码错误: \(error)", level: .error, category: .coredata)
            AppLog("❌ [CuisineStateRepository] 错误详情: \(error.localizedDescription)", level: .error, category: .coredata)

            // 尝试解析原始数据
            if let jsonString = String(data: data, encoding: .utf8) {
                AppLog("📄 [CuisineStateRepository] 原始JSON数据: \(jsonString.prefix(500))...", level: .debug, category: .coredata)
            }

            // 使用空数组作为后备
            subject.send([])
        }
    }
    
    private func saveToStorage(_ statuses: [CuisineTabStatus]) {
        AppLog("💾 [CuisineStateRepository] 开始保存到UserDefaults - 状态数量: \(statuses.count)", category: .coredata)
        
        do {
            let data = try JSONEncoder().encode(statuses)
            userDefaults.set(data, forKey: storageKey)
            AppLog("✅ [CuisineStateRepository] UserDefaults保存成功 - 数据大小: \(data.count) bytes", category: .coredata)
            
            // 验证保存是否成功
            if let savedData = userDefaults.data(forKey: storageKey) {
                AppLog("✅ [CuisineStateRepository] 验证保存成功 - 读取数据大小: \(savedData.count) bytes", category: .coredata)
            } else {
                AppLog("❌ [CuisineStateRepository] 验证保存失败 - 无法读取保存的数据", level: .error, category: .coredata)
            }
        } catch {
            AppLog("❌ [CuisineStateRepository] UserDefaults保存失败 - JSON编码错误: \(error)", level: .error, category: .coredata)
            AppLog("❌ [CuisineStateRepository] 错误详情: \(error.localizedDescription)", level: .error, category: .coredata)
            
            // 尝试逐个编码以找出问题
            for (index, status) in statuses.enumerated() {
                do {
                    let _ = try JSONEncoder().encode(status)
                    AppLog("✅ [CuisineStateRepository] 状态 \(index) 编码成功", level: .debug, category: .coredata)
                } catch {
                    AppLog("❌ [CuisineStateRepository] 状态 \(index) 编码失败: \(error)", level: .error, category: .coredata)
                }
            }
        }
    }
}