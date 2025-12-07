//
//  ModalHandleView.swift
//  yummy
//
//  Created by steve on 2025/1/7.
//

import SwiftUI

/// 模态页面拖拽指示器组件
/// 显示在模态页面顶部的小横条，提示用户可以拖拽关闭
struct ModalHandleView: View {
    private let width: CGFloat
    private let height: CGFloat
    private let color: Color
    
    /// 初始化模态拖拽指示器
    /// - Parameters:
    ///   - width: 指示器宽度，默认为 36
    ///   - height: 指示器高度，默认为 5
    ///   - color: 指示器颜色，默认为 Color.lineFrame
    init(
        width: CGFloat = 36,
        height: CGFloat = 5,
        color: Color = Color.lineFrame
    ) {
        self.width = width
        self.height = height
        self.color = color
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(color)
            .frame(width: width, height: height)
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        // 默认样式
        ModalHandleView()
        
        // 自定义样式
        ModalHandleView(
            width: 50,
            height: 6,
            color: .gray
        )
        
        // 在模态页面中的使用示例
        VStack(spacing: 16) {
            ModalHandleView()
            
            Text("模态页面内容")
                .font(.title2)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.backgroundDefault)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}