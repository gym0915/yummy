//
//  BottomActionAreaView.swift
//  yummy
//
//  Created by steve on 2025/9/3.
//

import SwiftUI
import LucideIcons

/// 通用底部操作区域
/// - 单行多按钮（最多 4 个），超出丢弃并打印 warning
/// - 复用 ActionButtonItemView 保持图标与文字整体可点
/// - 背景使用 .ultraThinMaterial，顶部圆角与指示条与现有 ShareOverlay 对齐
/// - 不处理动效（动画、拖拽等），由上层控制
struct BottomActionAreaView<ID: Hashable>: View {
    private let items: [BottomActionItem<ID>]
    private let onActionTap: (ID) -> Void

    init(items: [BottomActionItem<ID>], onActionTap: @escaping (ID) -> Void) {
        if items.count > 4 {
            AppLog("⚠️ [BottomActionAreaView] 传入按钮数超过 4 个，将丢弃多余项。count=\(items.count)", level: .warning, category: .ui)
        }
        self.items = Array(items.prefix(4))
        self.onActionTap = onActionTap
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部指示条
            Rectangle()
                .fill(.lineBlack)
                .frame(width: 50, height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 999))
                .padding(.top, 6)
                .padding(.bottom, 32)

            // 多按钮横向布局
            HStack(spacing: 46) {
                ForEach(items, id: \.id) { item in
                    ActionButtonItemView(item: item) { id in
                        onActionTap(id)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(
            .ultraThinMaterial,
            in: RoundedCorner(radius: 16, corners: [.topLeft, .topRight])
        )
    }
}

#Preview("BottomActionAreaView - Items (1~5)") {
    VStack {
        Spacer()
        let items: [BottomActionItem<BottomActionAreaDemoAction>] = [
            .init(id: .share, icon: Lucide.share, title: "分享"),
            .init(id: .save, icon: Lucide.download, title: "保存"),
            .init(id: .like, icon: Lucide.heart, title: "喜欢"),
            .init(id: .comment, icon: Lucide.messageCircle, title: "评论"),
            .init(id: .more, icon: Lucide.ellipsisVertical, title: "更多") // 将被丢弃
        ]
        BottomActionAreaView(items: items) { id in
            AppLog("👆 [Preview] 点击: \(id)", level: .debug, category: .ui)
        }
    }
    .background(Color(.systemBackground))
}

fileprivate enum BottomActionAreaDemoAction: Hashable { case share, save, like, comment, more }
