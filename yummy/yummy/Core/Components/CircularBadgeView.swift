//
//  CircularBadgeView.swift
//  yummy
//
//  Created by steve on 2025/9/9.
//

import SwiftUI

/// 圆形徽章视图组件
/// 用于显示数字或小标识的圆形背景视图
struct CircularBadgeView<Content: View>: View {
    let backgroundColor: Color
    let content: Content
    let size: CGFloat
    
    /// 初始化圆形徽章视图
    /// - Parameters:
    ///   - backgroundColor: 背景颜色
    ///   - size: 徽章大小，默认24
    ///   - content: 徽章内容
    init(
        backgroundColor: Color = .brandSecondary,
        size: CGFloat = 24,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.size = size
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            content
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CircularBadgeView(backgroundColor: .brandSecondary) {
            Text("1")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.accentColor)
        }
        
        CircularBadgeView(backgroundColor: .red, size: 32) {
            Text("99")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
        }
        
        CircularBadgeView(backgroundColor: .blue, size: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.white)
        }
    }
    .padding()
}