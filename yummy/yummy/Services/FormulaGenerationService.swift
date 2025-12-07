import Foundation
import UIKit
import UserNotifications
import SwiftUI

// MARK: - FormulaGenerationService
/// 负责调用大模型生成菜谱并持久化，任务脱离视图生命周期运行。
actor FormulaGenerationService {
    /// 全局单例
    static let shared = FormulaGenerationService()

    // MARK: - Dependencies
    private let bigModelRepository: BigModelRepository
    private let formulaRepository: FormulaRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let appStateManager: AppStateManaging

    init(bigModelRepository: BigModelRepository = BigModelRepositoryImpl(
            apiKeyProvider: KeychainAPIKeyProvider(),
            modelProvider: KeychainModelProvider()
        ),
        formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared,
        appStateManager: AppStateManaging = AppStateManager.shared) {
        self.bigModelRepository = bigModelRepository
        self.formulaRepository = formulaRepository
        self.notificationService = notificationService
        self.appStateManager = appStateManager
    }

    /// 生成菜谱并保存。该方法会立即返回，真正的网络调用在后台执行。
    /// - Parameter prompt: 用户输入的原始 prompt
    func generateAndSave(prompt: String) {
        // 检查提示词是否为空
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLog("⚠️ [菜谱生成] 提示词为空，跳过生成", level: .warning, category: .formula)
            return
        }
        
        AppLog("🚀 [菜谱生成] 开始生成菜谱 - Prompt: \(prompt)", category: .formula)
        
        // 使用 detached 任务，确保与调用方生命周期解耦
        Task.detached(priority: .background) {
            // 检查当前app状态，决定是否为后台生成（主线程隔离）
            let isCurrentlyBackground = await self.appStateManager.isAppInBackground()
            await self.executeGeneration(prompt: prompt, isBackground: isCurrentlyBackground)
        }
    }

    /// 重试生成：保留同一条记录（同 id），将其状态重置为 .loading
    /// - Parameter formula: 需要重试的 Formula
    func retry(formula: Formula) {
        guard let prompt = formula.prompt else {
            AppLog("⚠️ [菜谱重试] 无法重试，prompt 为空 (id: \(formula.id))", level: .warning, category: .formula)
            return
        }

        AppLog("🔄 [菜谱重试] 开始重试生成 - ID: \(formula.id), Prompt: \(prompt)", level: .info, category: .formula)
        
        Task.detached(priority: .background) {
            await self.executeRetry(formula: formula, prompt: prompt)
        }
    }

    // MARK: - 启动时处理残留的 loading 状态：超过5分钟的标记为 error，其他继续重试
    func handleStaleLoadingTasks() async {
        let current = formulaRepository.all()
        let loadingOnes = current.filter { $0.state == .loading }
        guard !loadingOnes.isEmpty else { 
            AppLog("✅ [启动处理] 没有发现残留的 loading 状态记录", level: .info, category: .formula)
            return 
        }

        AppLog("🧹 [启动处理] 发现 \(loadingOnes.count) 条 loading 状态记录，开始处理...", level: .info, category: .formula)
        
        let currentTime = Date()
        let timeoutInterval: TimeInterval = 5 * 60 // 5分钟
        
        var expiredCount = 0
        var retryCount = 0

        for item in loadingOnes {
            let taskAge = currentTime.timeIntervalSince(item.date)
            
            if taskAge > timeoutInterval {
                // 超过5分钟，标记为error
                var errorItem = item
                errorItem.state = .error
                AppLog("❌ [状态变更] \(item.id) - \(item.name): loading -> error (超时: \(Int(taskAge/60))分钟)", level: .warning, category: .formula)
                try? await formulaRepository.save(errorItem)
                expiredCount += 1
            } else {
                // 未超时，继续重试
                guard let prompt = item.prompt else {
                    AppLog("⚠️ [启动处理] 无法重试任务，prompt 为空 - ID: \(item.id)", level: .warning, category: .formula)
                    continue
                }
                
                AppLog("🔄 [启动处理] 继续执行未超时任务 - ID: \(item.id), 已运行: \(Int(taskAge))秒", level: .debug, category: .formula)
                
                // 重新启动任务（后台执行），保持原有创建时间
                Task.detached(priority: .background) {
                    await self.executeExistingGeneration(formula: item, isBackground: true)
                }
                retryCount += 1
            }
        }
        
        AppLog("✅ [启动处理] 完成 - 超时标记错误: \(expiredCount)条, 继续重试: \(retryCount)条", level: .info, category: .formula)
    }

    // MARK: - 重新启动已存在的任务（保持原始创建时间）
    private func executeExistingGeneration(formula: Formula, isBackground: Bool) async {
        guard let prompt = formula.prompt else {
            AppLog("⚠️ [任务重启] 无法重启任务，prompt 为空 - ID: \(formula.id)", level: .warning, category: .formula)
            return
        }

        do {
            // 1️⃣ 确保任务状态为 loading（实际上应该已经是了）
            var loadingFormula = formula
            loadingFormula.state = .loading
            loadingFormula.name = "整理中…"
            // 保持原有的创建时间和其他属性
            
            // 2️⃣ 调用大模型生成真正的菜谱
            AppLog("🤖 [大模型请求] 重新启动任务 - ID: \(formula.id)", level: .info, category: .formula)
            let generatedFormula = try await bigModelRepository.generateFormula(from: prompt)
            
            // 创建新的Formula实例，使用原有的id和创建时间
            var newFormula = Formula(
                name: generatedFormula.name,
                ingredients: generatedFormula.ingredients,
                tools: generatedFormula.tools,
                preparation: generatedFormula.preparation,
                steps: generatedFormula.steps,
                tips: generatedFormula.tips,
                tags: generatedFormula.tags,
                date: formula.date, // 保持原有创建时间
                prompt: prompt,
                state: .upload,
                imgpath: formula.imgpath, // 保持原有图片路径
                isCuisine: formula.isCuisine // 保持原有isCuisine状态
            )
            newFormula.id = formula.id // 使用原有ID

            // 3️⃣ 将正式菜谱保存（会触发 update）
            AppLog("📤 [状态变更] \(newFormula.id) - \(newFormula.name): loading -> upload (重启完成)", level: .info, category: .formula)
            try await formulaRepository.save(newFormula)

            AppLog("✅ [任务重启] 任务重启成功 - ID: \(formula.id), 名称: \(newFormula.name)", level: .info, category: .formula)

            // 4️⃣ 完成反馈
            await handleTaskCompletion(formula: newFormula, isBackground: isBackground)

        } catch {
            await handleGenerationError(for: formula, context: "任务重启", error: error, isBackground: isBackground)
        }
    }

    // MARK: - 统一的执行逻辑
    private func executeGeneration(prompt: String, isBackground: Bool, existingId: String? = nil) async {
        let placeholder = createPlaceholder(prompt: prompt, id: existingId)

        do {
            // 1️⃣ 如果是新任务，先写入占位对象（state = .loading），让首页立即出现卡片
            if existingId == nil {
                AppLog("💾 [状态变更] \(placeholder.id) - \(placeholder.name): 新建 -> loading", level: .info, category: .formula)
                try await formulaRepository.save(placeholder)
            }

            // 2️⃣ 调用大模型生成真正的菜谱
            AppLog("🤖 [大模型请求] 开始请求生成菜谱 - ID: \(placeholder.id)", level: .info, category: .formula)
            var formula = try await bigModelRepository.generateFormula(from: prompt)
            // 使用与占位相同的 id，更新同一条记录
            formula.id = placeholder.id
            formula.prompt = prompt
            formula.state = .upload
            formula.isCuisine = placeholder.isCuisine // 保持占位符的isCuisine状态

            // 3️⃣ 将正式菜谱保存（会触发 update）
            AppLog("📤 [状态变更] \(formula.id) - \(formula.name): loading -> upload", level: .info, category: .formula)
            try await formulaRepository.save(formula)

            AppLog("✅ [菜谱生成] 菜谱已生成并保存 - ID: \(formula.id), 名称: \(formula.name)", level: .info, category: .formula)

            // 4️⃣ 完成反馈
            await handleTaskCompletion(formula: formula, isBackground: isBackground)

        } catch {
            await handleGenerationError(for: placeholder, context: isBackground ? "后台生成" : "前台生成", error: error, isBackground: isBackground)
        }
    }

    private func executeRetry(formula: Formula, prompt: String) async {
        do {
            // 1️⃣ 重置状态为 loading，立即刷新首页
            var loadingFormula = formula
            loadingFormula.name = "整理中…"
            loadingFormula.state = .loading
            AppLog("🔄 [状态变更] \(formula.id) - \(formula.name): error -> loading (重试)", level: .info, category: .formula)
            try await formulaRepository.save(loadingFormula)

            // 2️⃣ 重新请求大模型
            AppLog("🤖 [大模型请求] 重试请求生成菜谱 - ID: \(formula.id)", level: .info, category: .formula)
            var newFormula = try await bigModelRepository.generateFormula(from: prompt)
            newFormula.id = formula.id             // 复用 id
            newFormula.prompt = prompt
            newFormula.state = .upload
            newFormula.isCuisine = formula.isCuisine // 保持原有isCuisine状态

            // 3️⃣ 保存
            AppLog("📤 [状态变更] \(newFormula.id) - \(newFormula.name): loading -> upload (重试成功)", level: .info, category: .formula)
            try await formulaRepository.save(newFormula)

            AppLog("✅ [菜谱重试] 重试成功 - ID: \(formula.id), 名称: \(newFormula.name)", level: .info, category: .formula)

            // 4️⃣ 完成反馈（重试也是前台行为）
            await handleTaskCompletion(formula: newFormula, isBackground: false)

        } catch {
            await handleGenerationError(for: formula, context: "重试", error: error, isBackground: false)
        }
    }

    // MARK: - 完成后的反馈处理
    private func handleTaskCompletion(formula: Formula, isBackground: Bool) async {
        // 再次检查当前状态，因为生成过程中app状态可能已改变
        let currentlyInBackground = await appStateManager.isAppInBackground()
        
        AppLog("🎉 [任务完成] ID: \(formula.id), 名称: \(formula.name)", level: .info, category: .formula)
        AppLog("📱 [任务完成] 当前App状态: \(currentlyInBackground ? "后台" : "前台")", level: .debug, category: .app)
        
        if currentlyInBackground || isBackground {
            // 后台完成：发送通知
            await notificationService.sendFormulaCompletionNotification(
                formulaName: formula.name,
                formulaId: formula.id
            )
            AppLog("📬 [后台任务完成] 已发送通知 - 菜谱: \(formula.name)", level: .info, category: .notification)
        } else {
            // 前台完成：震动反馈
            await triggerHapticFeedback()
        }
    }

    // MARK: - 震动反馈
    private func triggerHapticFeedback() async {
        await MainActor.run {
            HapticsManager.shared.successWithSound()
            AppLog("📳 [前台任务完成] 触发震动反馈 - 菜谱生成完成", level: .info, category: .ui)
        }
    }

    // MARK: - 错误处理
    private func handleGenerationError(for formula: Formula, context: String, error: Error, isBackground: Bool) async {
        let isCancelled = (error as? URLError)?.code == .cancelled || error is CancellationError
        var updated = formula
        if isCancelled {
            AppLog("⚠️ [菜谱生成] \(context) 任务被取消/挂起，保持 loading 状态 - ID: \(formula.id)", level: .warning, category: .formula)
            updated.state = .loading // 确保仍为 loading
        } else {
            AppLog("❌ [状态变更] \(formula.id) - \(formula.name): \(formula.state) -> error", level: .error, category: .formula)
            updated.state = .error
        }
        try? await formulaRepository.save(updated)
    }

    // MARK: - 辅助方法
    private func createPlaceholder(prompt: String, id: String? = nil) -> Formula {
        var formula = Formula(
            name: "整理中…",
            ingredients: Ingredients(mainIngredients: [], spicesSeasonings: [], sauce: []),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: DateFormatterUtility.currentDate(),
            prompt: prompt,
            state: .loading,
            imgpath: nil,
            isCuisine: false // 占位符默认为非菜系
        )
        
        // 如果提供了 id，则使用它；否则保持自动生成的 id
        if let existingId = id {
            formula.id = existingId
        }
        
        AppLog("📝 [占位符创建] ID: \(formula.id), 状态: loading, Prompt: \(prompt)", level: .info, category: .formula)
        
        return formula
    }
}
