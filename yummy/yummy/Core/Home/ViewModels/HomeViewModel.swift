//
//  HomeViewModel.swift
//  yummy
//
//  Created by steve on 2025/6/20.
//

import Foundation
import Combine
import LucideIcons
import SwiftUI
 

@MainActor
class HomeViewModel: ObservableObject {
    
    @Published var navigationTitle: AnyView = AnyView(Text("食记").appStyle(.navigationTitle))
    @Published var leadingNavigationButton: NavigationBarButtonConfiguration?
    @Published var trailingNavigationButtonRight: NavigationBarButtonConfiguration?
    
    @Published var formulaList: [Formula] = []
    @Published var selectedFormulaFromNotification: Formula?
    @Published var cuisineCount: Int = 0
    // 第六步：共享计时器，用于驱动所有卡片的虚拟进度（避免为每张卡片单独起任务/也不使用字典存储进度）
    @Published var tick: Int = 0
 
    // 删除覆盖层状态：仅允许单一可见，记录目标 Formula 的 id
    @Published var deleteOverlayTargetId: String?
    // 删除确认请求：当子视图触发时设置为目标 id，HomeView 监听后弹出 Alert 并清空
    @Published var deleteConfirmationRequestId: String?
    @Published private(set) var deletingIds: Set<String> = []
 
    private let repository: FormulaRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?
    private var networkCancellable: AnyCancellable?
 
    // 第八步：网络重置锚点；当网络断开或重连时重置为当前时间
    private var networkResetAt: Date?
    // 细节优化：重试时的重置锚点；点击错误卡片重试后，从 0 重新开始显示虚拟进度
    private var retryResetAnchors: [String: Date] = [:]
 
    // 删除覆盖层自动隐藏调度器
    private var overlayAutoHideTask: Task<Void, Never>?
    
    // 新的初始化方法，允许注入 Repository；默认使用单例
    init(repository: FormulaRepositoryProtocol = FormulaRepository.shared) {
        self.repository = repository
        setupNotificationObserver()
        setupSharedTimer()
        setupNetworkObserver()
 
        // 订阅数据流
        repository.formulasPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$formulaList)
        
        // 订阅料理数量变化
        $formulaList
            .map { formulas in formulas.filter { $0.isCuisine }.count }
            .assign(to: &$cuisineCount)
    }
    
    /// 设置通知点击监听
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .formulaNotificationTapped)
            .compactMap { $0.userInfo?["formulaId"] as? String }
            .compactMap { [weak self] formulaId in
                guard let self = self else { return nil }
                return self.formulaList.first { $0.id == formulaId }
            }
            .assign(to: &$selectedFormulaFromNotification)
    }
    
    /// 共享计时器：每 50ms 递增一次 tick
    private func setupSharedTimer() {
        timerCancellable?.cancel()
        // 放慢刷新频率：150ms 一次，降低刷新速率与功耗
        timerCancellable = Timer.publish(every: 0.15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick &+= 1
            }
    }
 
    /// 监听网络变化：统一订阅 NetworkMonitor.shared，断网/重连时重置锚点并触发刷新
    private func setupNetworkObserver() {
        networkCancellable?.cancel()
        networkCancellable = NetworkMonitor.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.networkResetAt = Date()
                self.tick &+= 1
            }
    }
    
    /// 计算某条记录当前应显示的虚拟进度（0...cap）
    /// 不使用字典存储，基于 formula.date 和当前时间推导；
    /// 但为满足“错误后点击重试应从 0 开始”的需求，引入 per-id 的重试锚点。
    func virtualProgress(for formula: Formula) -> Double {
        guard formula.state == .loading else { return 0 }
        // 93% 之后仍缓慢增长到 98%
        let plateauStart: Double = 0.93
        let plateauEnd: Double = 0.98
        let now = Date()
        // 起点取“配方创建时间”、“网络重置时间”和“重试重置时间”的较晚者，实现断网/重连/重试后从 0 重新开始
        let retryAnchor = retryResetAnchors[formula.id]
        let startDate = [formula.date, networkResetAt, retryAnchor].compactMap { $0 }.max() ?? formula.date
        let elapsed = max(0, now.timeIntervalSince(startDate))
        // 放慢整体推进速度，并新增尾段：0.93 -> 0.98 用更长时间缓慢上升
        let segments: [(target: Double, duration: Double)] = [
            (0.30,  2.0),
            (0.60,  4.0),
            (0.85,  6.0),
            (plateauStart, 8.0),
            (plateauEnd,  20.0)
        ]
        var current: Double = 0
        var remaining = elapsed
        for (target, duration) in segments {
            if remaining <= 0 { break }
            let delta = target - current
            if remaining >= duration {
                current = target
                remaining -= duration
            } else {
                let ratio = remaining / duration
                current += delta * ratio
                remaining = 0
            }
        }
        return min(max(0, current), plateauEnd)
    }
 
    // MARK: - 删除覆盖层逻辑
    /// 是否允许删除：仅 upload / finish 状态可删除
    func canDelete(_ formula: Formula) -> Bool {
        return formula.state == .upload || formula.state == .finish
    }
 
    /// 显示删除覆盖层，并（重新）启动 5 秒自动隐藏
    func showDeleteOverlay(for formulaId: String) {
        // 取消旧的自动隐藏任务
        overlayAutoHideTask?.cancel()
    
        // 如果重复点击同一张卡片，只需重置自动隐藏计时
        if deleteOverlayTargetId == formulaId {
            scheduleOverlayAutoHide(for: formulaId)
            return
        }
    
        // 若当前已有其它卡片的覆盖层显示，先清空，再在下一次主线程循环中设置为新的目标，
        // 以强制 SwiftUI 完成一次视图刷新，避免偶现的“保持旧层不消失且新层不出现”的视觉竞态
        if deleteOverlayTargetId != nil {
            deleteOverlayTargetId = nil
            overlayAutoHideTask = nil
            Task { [weak self] in
                guard let self = self else { return }
                await MainActor.run {
                    self.deleteOverlayTargetId = formulaId
                    self.scheduleOverlayAutoHide(for: formulaId)
                }
            }
        } else {
            // 没有已显示的覆盖层，直接显示新的
            deleteOverlayTargetId = formulaId
            scheduleOverlayAutoHide(for: formulaId)
        }
    }
 
    /// 手动隐藏覆盖层
    func hideDeleteOverlay() {
        overlayAutoHideTask?.cancel()
        overlayAutoHideTask = nil
        if deleteOverlayTargetId != nil {
            deleteOverlayTargetId = nil
        }
    }
    
    /// 暂停/取消覆盖层自动隐藏计时器（用于进入 Alert 时避免中途超时）
    func suspendOverlayAutoHide() {
        overlayAutoHideTask?.cancel()
        overlayAutoHideTask = nil
    }
    
    /// 启动/重置覆盖层的自动隐藏计时（默认 5 秒）
    private func scheduleOverlayAutoHide(for targetId: String, after seconds: TimeInterval = 5.0) {
        overlayAutoHideTask?.cancel()
        overlayAutoHideTask = Task { [weak self] in
            let ns = UInt64((seconds * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: ns)
            guard let self = self else { return }
            if Task.isCancelled { return }
            // 仅当仍然是同一张卡片的覆盖层时才清空，避免旧任务误清空新目标
            if self.deleteOverlayTargetId == targetId {
                self.deleteOverlayTargetId = nil
            }
        }
    }
    
    /// 触发删除确认请求，由 HomeView 监听并弹窗
    func requestDeleteConfirmation(for formulaId: String) {
        deleteConfirmationRequestId = formulaId
    }

    // MARK: - 删除并发防护
    func isDeleting(_ id: String) -> Bool {
        return deletingIds.contains(id)
    }
    func markDeletingStart(_ id: String) {
        deletingIds.insert(id)
    }
    func markDeletingEnd(_ id: String) {
        deletingIds.remove(id)
    }
 
    /// 标记某条记录的“错误重试”开始时间，使其虚拟进度从 0 重新开始
    func markRetryStart(for formulaId: String) {
        retryResetAnchors[formulaId] = Date()
        // 触发一次 UI 刷新
        tick &+= 1
    }
    
    /// 清除通知选中状态
    func clearNotificationSelection() {
        selectedFormulaFromNotification = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        timerCancellable?.cancel()
        networkCancellable?.cancel()
        overlayAutoHideTask?.cancel()
    }
}
