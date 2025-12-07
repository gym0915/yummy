//
//  yummyApp.swift
//  yummy
//
//  Created by steve on 2025/6/19.
//

import SwiftUI
import UserNotifications

@main
struct yummyApp: App {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var appStateManager = AppStateManager.shared
    @StateObject private var toastManager = ToastManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasPerformedStartupTasks = false
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(homeViewModel)
                .environmentObject(appStateManager)
                .environmentObject(toastManager)
                .overlay(
                    ToastHostView()
                        .environmentObject(toastManager)
                )
                .task {
                    if !hasPerformedStartupTasks {
                        await performStartupTasks()
                        hasPerformedStartupTasks = true
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    private func performStartupTasks() async {
        // 启动时处理残留 loading 状态：超时的设为error，未超时的继续重试
        await FormulaGenerationService.shared.handleStaleLoadingTasks()
        
        // 请求通知权限
        let notificationGranted = await NotificationService.shared.requestPermission()
        if notificationGranted {
            // 设置通知代理
            await setupNotificationDelegate()
        }
    }
    
    private func setupNotificationDelegate() async {
        await MainActor.run {
            UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        // 更新状态管理器
        appStateManager.updateScenePhase(newPhase)
        
        switch newPhase {
        case .active:
            AppLog("🌅 应用进入活跃状态", category: .app)
            
            // 清除通知徽章
            Task {
                await MainActor.run {
                    if #available(iOS 17.0, *) {
                        UNUserNotificationCenter.current().setBadgeCount(0)
                    } else {
                        UIApplication.shared.applicationIconBadgeNumber = 0
                    }
                }
            }
            
            // 清除菜谱相关通知
            NotificationService.shared.clearFormulaNotificationsOnForeground()
            
        case .inactive:
            AppLog("⚠️ 应用进入非活跃状态", level: .info, category: .app)
            
        case .background:
            AppLog("🌙 应用进入后台", level: .info, category: .app)
            // 在这里保存重要数据
            Task {
                await saveImportantData()
            }
            
        @unknown default:
            AppLog("❓ 未知状态变化", level: .warning, category: .app)
        }
    }
    
    private func saveImportantData() async {
        // 保存关键数据到持久化存储
    }
}
