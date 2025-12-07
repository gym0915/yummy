//
//  NavigationBarButtonConfiguration.swift
//  yummy
//
//  Created by steve on 2025/6/20.
//

import Foundation
import SwiftUI // 为了使用 Image(systemName:)

// 定义导航栏按钮的配置结构体
struct NavigationBarButtonConfiguration {
//    let id = UUID() // 移除 id
    let iconName: UIImage? // LucideIcons (可选)
    let text: String?     // 文本 (可选)
    let action: (() -> Void)? // 按钮点击时触发的闭包
//    let alignment: HorizontalAlignment // 移除 alignment
    var isEnabled: Bool = true // 按钮是否可用，默认为 true
    var badgeCount: Int? = nil // 徽标数量 (可选)
} 
