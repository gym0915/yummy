//
//  BottomActionItem.swift
//  yummy
//
//  Created by steve on 2025/9/3.
//

import UIKit

/// 用于 BottomActionAreaView/ActionButtonItemView 的数据模型
/// - 采用泛型 ID 以支持强类型枚举作为标识（例如 enum BottomActionID: Hashable { ... }）
/// - 与现有 ButtonContentView/NavigationBarButtonConfiguration 兼容（icon 使用 UIImage?）
struct BottomActionItem<ID: Hashable> {
    /// 强类型标识（建议使用 enum）
    let id: ID
    /// 图标（使用 LucideIcons 生成的 UIImage）
    let icon: UIImage?
    /// 文案（显示在图标下方）
    let title: String
    /// 是否可点击
    var isEnabled: Bool = true

    init(id: ID,
         icon: UIImage?,
         title: String,
         isEnabled: Bool = true) {
        self.id = id
        self.icon = icon
        self.title = title
        self.isEnabled = isEnabled
    }
}