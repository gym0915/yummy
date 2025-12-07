import Foundation
import SwiftUI
import UIKit
import LucideIcons

// MARK: - ToastStyle
enum ToastStyle: String {
    case success
    case warning
    case error

    var backgroundColor: Color {
        switch self {
        case .success:
            return Color.green.opacity(0.92)
        case .warning:
            return Color.orange.opacity(0.92)
        case .error:
            return Color.red.opacity(0.92)
        }
    }

    var hapticType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: return .success
        case .warning: return .warning
        case .error: return .error
        }
    }

    var iconImage: UIImage {
        switch self {
        case .success:
            return Lucide.check.withRenderingMode(.alwaysTemplate)
        case .warning:
            return Lucide.triangleAlert.withRenderingMode(.alwaysTemplate)
        case .error:
            return Lucide.circleX.withRenderingMode(.alwaysTemplate)
        }
    }
}

// MARK: - ToastPosition
enum ToastPosition: String {
    case top
    case bottom

    var transitionEdge: Edge {
        switch self {
        case .top: return .top
        case .bottom: return .bottom
        }
    }
}

// MARK: - ToastItem
struct ToastItem: Identifiable, Equatable {
    let id: UUID = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval
    let hapticsEnabled: Bool
    let position: ToastPosition

    var dedupeKey: String { "\(message)|\(style.rawValue)|\(position.rawValue)" }
}

// MARK: - ToastManager
@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published private(set) var currentItem: ToastItem?

    private var queue: [ToastItem] = []
    private var pendingDedupeKeys: Set<String> = []
    private var dismissTask: Task<Void, Never>?

    private init() {}

    /// 展示一个 Toast。支持队列与去重，同款正在显示时刷新剩余时长。
    func show(_ message: String,
              style: ToastStyle,
              duration: TimeInterval = 2.0,
              haptics: Bool = true,
              position: ToastPosition = .bottom) {
        let item = ToastItem(message: message,
                             style: style,
                             duration: duration,
                             hapticsEnabled: haptics,
                             position: position)

        // 正在显示同款：仅刷新计时
        if let current = self.currentItem, current.dedupeKey == item.dedupeKey {
            self.startDismissTimer(duration: duration)
            return
        }

        // 已在队列中：忽略
        if self.pendingDedupeKeys.contains(item.dedupeKey) {
            return
        }

        // 立即展示或入队
        if self.currentItem == nil {
            self.present(item)
        } else {
            self.queue.append(item)
            self.pendingDedupeKeys.insert(item.dedupeKey)
        }
    }

    /// 立即清空所有 Toast
    func dismissImmediately() {
        dismissTask?.cancel()
        dismissTask = nil
        currentItem = nil
        queue.removeAll()
        pendingDedupeKeys.removeAll()
    }

    // MARK: - Private
    private func present(_ item: ToastItem) {
        currentItem = item
        pendingDedupeKeys.remove(item.dedupeKey)
        if item.hapticsEnabled {
            HapticsManager.shared.notification(type: item.style.hapticType)
        }
        startDismissTimer(duration: item.duration)
    }

    private func startDismissTimer(duration: TimeInterval) {
        dismissTask?.cancel()

        dismissTask = Task { [weak self] in
            guard let self else { return }
            let durationNs = UInt64((duration * 1_000_000_000).rounded())
            try? await Task.sleep(nanoseconds: durationNs)

            withAnimation(.easeInOut(duration: 0.25)) {
                self.currentItem = nil
            }
            // 出场动画结束后展示下一条
            try? await Task.sleep(nanoseconds: UInt64((0.28 * 1_000_000_000).rounded()))
            self.showNextIfNeeded()
        }
    }

    private func showNextIfNeeded() {
        guard currentItem == nil else { return }
        if let next = queue.first {
            queue.removeFirst()
            present(next)
        }
    }
}


