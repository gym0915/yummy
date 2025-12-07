import Foundation
import UIKit
import AudioToolbox

// MARK: - HapticsManager
/// 全局震动反馈管理器，提供统一的震动反馈接口
class HapticsManager {
    /// 全局单例
    static let shared = HapticsManager()
    
    // 私有初始化，确保单例模式
    private init() {}
    
    /// 通知类型的震动反馈
    /// - Parameter type: 通知反馈类型（成功、警告、错误）
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// 冲击类型的震动反馈
    /// - Parameter style: 冲击反馈强度（轻、中、重）
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// 成功反馈：震动 + 音效
    /// 用于重要操作完成时的反馈
    func successWithSound() {
        notification(type: .success)
//        AudioServicesPlaySystemSound(1519) // 系统成功提示音
    }
    
    /// 选择反馈：轻微震动
    /// 用于选择操作的反馈
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
} 
