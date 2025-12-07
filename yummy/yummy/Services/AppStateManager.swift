import Foundation
import UIKit
import SwiftUI

// MARK: - Protocol
protocol AppStateManaging: AnyObject {
    func isAppInBackground() async -> Bool
}

// MARK: - AppStateManager
/// 管理应用状态，提供统一的状态检测接口
@MainActor
final class AppStateManager: ObservableObject, AppStateManaging {
    /// 全局单例
    static let shared = AppStateManager()
    
    @Published private(set) var currentScenePhase: ScenePhase = .active
    
    private init() {
        // 监听应用状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    /// 更新当前场景阶段
    func updateScenePhase(_ newPhase: ScenePhase) {
        currentScenePhase = newPhase
    }
    
    /// 检查应用是否在后台
    func isAppInBackground() async -> Bool {
        return currentScenePhase == .background
    }
    
    /// 检查应用是否在前台
    var isAppActive: Bool {
        return currentScenePhase == .active
    }
    
    /// 兼容旧代码的只读属性（同步，主线程访问）
    var isAppInBackground: Bool {
        return currentScenePhase == .background
    }

    @objc private func appDidEnterBackground() {
        AppLog("🌙 AppStateManager: 应用进入后台", category: .app)
        updateScenePhase(.background)
    }
    
    @objc private func appWillEnterForeground() {
        AppLog("🌅 AppStateManager: 应用即将进入前台", category: .app)
        updateScenePhase(.active)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}