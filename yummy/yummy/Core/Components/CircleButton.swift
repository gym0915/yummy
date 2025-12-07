//
//  CircleButtons.swift
//  yummy
//
//  Created by steve on 2025/9/8.
//

import SwiftUI

struct CirculeButton: View {
    private let iconName: String
    private let isEnabled: Bool
    private let action: () -> Void
    private let size: CGFloat
    
    /// 初始化圆形添加按钮
    /// - Parameters:
    ///   - iconName: 图标名称
    ///   - isEnabled: 是否启用
    ///   - size: 按钮大小，默认44
    ///   - action: 点击回调
    init(
        iconName: String,
        isEnabled: Bool,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.isEnabled = isEnabled
        self.size = size
        self.action = action
    }
    
    var body: some View {
        ButtonContentView(
            buttonConfig: NavigationBarButtonConfiguration(
                iconName: UIImage(lucideId: iconName),
                text: nil,
                action: action
            )
        )
        .background(
            Circle()
                .fill(Color.backgroundDefault)
                .frame(width: size, height: size)
                .overlay(content: {
                    Circle()
                        .stroke(Color.lineFrame, lineWidth: 0.5)
                })
        )
        .frame(width: size, height: size)
        .disabled(!isEnabled)
    }
}

#Preview {
    CirculeButton(iconName: "plus", isEnabled: true, action: {})
}
