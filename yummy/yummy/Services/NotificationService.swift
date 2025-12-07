import Foundation
import UserNotifications
import UIKit

// MARK: - Protocol
/// 通知服务协议，便于单元测试替换实现
protocol NotificationServiceProtocol {
    func sendFormulaCompletionNotification(formulaName: String, formulaId: String) async
}

// MARK: - NotificationService
/// 负责管理用户通知，包括权限请求和发送通知
final class NotificationService: NotificationServiceProtocol {
    /// 全局单例
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    private init() {}
    
    /// 请求通知权限
    func requestPermission() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            
            let granted = try await center.requestAuthorization(options: options)
            AppLog("📱 通知权限请求结果: \(granted ? "已授权" : "被拒绝")", category: .notification)
            return granted
        } catch {
            AppLog("❌ 通知权限请求失败: \(error)", level: .error, category: .notification)
            return false
        }
    }
    
    /// 检查当前通知权限状态
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// 发送菜谱生成完成通知
    /// - Parameters:
    ///   - formulaName: 生成的菜谱名称
    ///   - formulaId: 菜谱ID，用于点击通知时跳转
    func sendFormulaCompletionNotification(formulaName: String, formulaId: String) async {
        // 检查权限状态
        let status = await checkPermissionStatus()
        guard status == .authorized else {
            AppLog("⚠️ 通知权限未授权，无法发送通知", level: .warning, category: .notification)
            return
        }
        
        // 创建通知内容
        let content = UNMutableNotificationContent()
        content.title = "🍽️ 菜谱整理完成"
        content.body = "《\(formulaName)》已经为你整理好了，快来查看吧！"
        content.sound = .default
        content.badge = 1
        
        // 添加用户信息，用于点击通知时的跳转
        content.userInfo = [
            "type": "formula_completed",
            "formulaId": formulaId,
            "formulaName": formulaName
        ]
        
        // 立即触发的通知
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        // 创建通知请求
        let request = UNNotificationRequest(
            identifier: "formula_\(formulaId)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            AppLog("✅ 菜谱完成通知已发送: \(formulaName)", category: .notification)
        } catch {
            AppLog("❌ 发送通知失败: \(error)", level: .error, category: .notification)
        }
    }
    
    /// 清除所有待发送的通知
    func clearPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// 清除已发送的通知
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
    
    /// 处理通知点击事件
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let type = userInfo["type"] as? String,
              type == "formula_completed",
              let formulaId = userInfo["formulaId"] as? String else {
            return
        }
        
        AppLog("📱 用户点击了菜谱完成通知，菜谱ID: \(formulaId)", category: .notification)
        
        // 清除该通知
        center.removeDeliveredNotifications(withIdentifiers: ["formula_\(formulaId)"])
        
        // 发送事件给相关的 ViewModel 实现跳转
        NotificationCenter.default.post(
            name: .formulaNotificationTapped,
            object: nil,
            userInfo: ["formulaId": formulaId]
        )
    }
    
    /// 当app回到前台时清除所有菜谱相关通知
    func clearFormulaNotificationsOnForeground() {
        // 获取所有已发送的通知
        center.getDeliveredNotifications { [weak self] notifications in
            guard let self = self else { return }
            let formulaNotificationIds = notifications
                .filter { $0.request.identifier.hasPrefix("formula_") }
                .map { $0.request.identifier }
            
            if !formulaNotificationIds.isEmpty {
                self.center.removeDeliveredNotifications(withIdentifiers: formulaNotificationIds)
                AppLog("🧹 已清除 \(formulaNotificationIds.count) 个菜谱通知", category: .notification)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let formulaNotificationTapped = Notification.Name("formulaNotificationTapped")
}