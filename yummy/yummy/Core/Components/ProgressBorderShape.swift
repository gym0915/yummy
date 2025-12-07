//
//  ProgressBorderShape.swift
//  yummy
//
//  Created by steve on 2025/1/20.
//

import SwiftUI

/// 卡片进度边框Shape，用于显示loading状态的虚拟进度
struct ProgressBorderShape: Shape {
    var progress: Double
    private let cornerRadius: CGFloat = 8
    
    init(progress: Double = 1.0) {
        self.progress = max(0, min(1, progress)) // 确保progress在0-1之间
    }
    
    // MARK: - Animation support
    var animatableData: Double {
        get { progress }
        set { progress = max(0, min(1, newValue)) }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 第二步：根据进度值绘制部分边框
        if progress <= 0 {
            return path // 进度为0时返回空路径
        }
        
        // 计算各段的长度
        let topLength = rect.width / 2 - cornerRadius // 从中间到右上角圆弧起点（预留圆角半径）
        let rightLength = rect.height - 2 * cornerRadius // 右边直线部分
        let bottomLength = rect.width - 2 * cornerRadius // 底边直线部分
        let leftLength = rect.height - 2 * cornerRadius // 左边直线部分
        let backToTopLength = rect.width / 2 - cornerRadius // 从左上角回到顶部中间
        
        // 圆弧长度 (1/4圆周 = π * r / 2)
        let arcLength = .pi * cornerRadius / 2
        
        // 总周长
        let totalLength = topLength + arcLength + rightLength + arcLength + 
                         bottomLength + arcLength + leftLength + arcLength + backToTopLength
        
        // 根据进度计算当前绘制长度
        let currentLength = totalLength * progress
        
        // 起始位置：顶部边的中间
        let startPoint = CGPoint(x: rect.midX, y: rect.minY)
        path.move(to: startPoint)
        
        var remainingLength = currentLength
        
        // 1. 顶边右半部分 (从中间到右上角)
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, topLength)
            let endX = rect.midX + segmentLength
            path.addLine(to: CGPoint(x: endX, y: rect.minY))
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 2. 右上角圆弧
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, arcLength)
            let progress = segmentLength / arcLength
            
            // 当前点已在 (rect.maxX - cornerRadius, rect.minY)
            // 使用圆心 (rect.maxX - cornerRadius, rect.minY + cornerRadius)
            let center = CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius)
            let start = Angle.radians(-.pi / 2) // 从顶部向右的起点
            let end = Angle.radians(-.pi / 2 + (.pi / 2) * progress)
            path.addArc(center: center, radius: cornerRadius, startAngle: start, endAngle: end, clockwise: false)
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 3. 右边
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, rightLength)
            let endY = rect.minY + cornerRadius + segmentLength
            path.addLine(to: CGPoint(x: rect.maxX, y: endY))
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 4. 右下角圆弧
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, arcLength)
            let progress = segmentLength / arcLength
            
            let center = CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius)
            let start = Angle.radians(0)
            let end = Angle.radians((.pi / 2) * progress)
            path.addArc(center: center, radius: cornerRadius, startAngle: start, endAngle: end, clockwise: false)
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 5. 底边
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, bottomLength)
            let endX = rect.maxX - cornerRadius - segmentLength
            path.addLine(to: CGPoint(x: endX, y: rect.maxY))
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 6. 左下角圆弧
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, arcLength)
            let progress = segmentLength / arcLength
            
            let center = CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius)
            let start = Angle.radians(.pi / 2)
            let end = Angle.radians(.pi / 2 + (.pi / 2) * progress)
            path.addArc(center: center, radius: cornerRadius, startAngle: start, endAngle: end, clockwise: false)
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 7. 左边
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, leftLength)
            let endY = rect.maxY - cornerRadius - segmentLength
            path.addLine(to: CGPoint(x: rect.minX, y: endY))
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 8. 左上角圆弧
        if remainingLength > 0 {
            let segmentLength = min(remainingLength, arcLength)
            let progress = segmentLength / arcLength
            
            let center = CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius)
            let start = Angle.radians(.pi)
            let end = Angle.radians(.pi + (.pi / 2) * progress)
            path.addArc(center: center, radius: cornerRadius, startAngle: start, endAngle: end, clockwise: false)
            remainingLength -= segmentLength
            
            if remainingLength <= 0 { return path }
        }
        
        // 9. 回到起始点
        if remainingLength > 0 {
            // 从左上圆角终点 (rect.minX + cornerRadius, rect.minY) 向右到顶部中点
            let segmentLength = min(remainingLength, backToTopLength)
            let endX = rect.minX + cornerRadius + segmentLength
            path.addLine(to: CGPoint(x: endX, y: rect.minY))
            // 注：只有当remainingLength >= backToTopLength时，才真正回到startPoint
        }
        
        return path
    }
}

// MARK: - Preview
#Preview {
    struct AnimatedPreview: View {
        @State private var p: Double = 0
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.backgroundWhite)
                    .shadow(color: .lineDefault, radius: 2, x: 1, y: 1)
                VStack(spacing: 6) {
                    ProgressView()
                        .frame(width: 24, height: 24)
                    Text("\(Int(p * 100))%进度")
                        .appStyle(.cardGray)
                }
            }
            .frame(width: 140, height: 180)
            .overlay(
                ProgressBorderShape(progress: p)
                    .stroke(.accent, lineWidth: 3)
            )
            .padding()
            .background(.backgroundDefault)
            .onAppear {
                withAnimation(.linear(duration: 2.0)) { p = 1.0 }
            }
        }
    }
    return AnimatedPreview()
}
