//
//  ActionButtonItemView.swift
//  yummy
//
//  Created by steve on 2025/9/3.
//

import SwiftUI
import LucideIcons

/// 底部操作区域的单个按钮视图
/// - 整体（图标+文字）可点击
/// - 内部复用 ButtonContentView + NavigationBarButtonConfiguration，保持风格一致
/// - 不处理动效，动画由上层控制
struct ActionButtonItemView<ID: Hashable>: View {
    let item: BottomActionItem<ID>
    let onTap: (ID) -> Void

    init(item: BottomActionItem<ID>, onTap: @escaping (ID) -> Void) {
        self.item = item
        self.onTap = onTap
    }

    var body: some View {
        VStack(spacing: 24) {
            // 使用 ButtonContentView 复用图标渲染与启用/禁用样式
            ButtonContentView(
                buttonConfig: NavigationBarButtonConfiguration(
                    iconName: item.icon,
                    text: nil,
                    action: nil, // 点击交互交由外层整体处理，避免双触发
                    isEnabled: item.isEnabled
                )
            )

            Text(item.title)
                .appStyle(.body)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isEnabled {
                AppLog("⚠️ [ActionButtonItemView] id = \(item.id)" , level: .debug, category: .ui)
                onTap(item.id)
            }
        }
        .disabled(!item.isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text(item.title))
    }
}

#Preview("ActionButtonItemView - Enabled/Disabled") {
    VStack(spacing: 24) {
        let enabledItem = BottomActionItem(id: ActionButtonDemoAction.share, icon: Lucide.share, title: "分享",isEnabled: true)
        let disabledItem = BottomActionItem(id: ActionButtonDemoAction.save, icon: Lucide.download, title: "保存", isEnabled: false)

        HStack(spacing: 32) {
            ActionButtonItemView(item: enabledItem) { id in
                AppLog("👆 [Preview] 点击: \(id)", level: .debug, category: .ui)
            }
            ActionButtonItemView(item: disabledItem) { id in
                AppLog("👆 [Preview] 点击: \(id)", level: .debug, category: .ui)
            }
        }
        .padding()
    }
    .frame(maxWidth: .infinity)
    .background(Color(.systemBackground))
}

fileprivate enum ActionButtonDemoAction: Hashable { case share, save }
