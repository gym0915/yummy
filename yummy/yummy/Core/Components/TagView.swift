//
//  TagView.swift
//  yummy
//
//  Created by steve on 2025/6/22.
//

import SwiftUI

struct TagView: View {
    let text: String
    let showDeleteButton: Bool
    let onDelete: (() -> Void)?
    let maxWidth: CGFloat
    
    init(text: String, showDeleteButton: Bool = false, onDelete: (() -> Void)? = nil, maxWidth: CGFloat = .infinity) {
        self.text = text
        self.showDeleteButton = showDeleteButton
        self.onDelete = onDelete
        self.maxWidth = maxWidth
    }
    
    var body: some View {
        let content = HStack(spacing: 4) {
            Text(text)
                .appStyle(.tag)
                .lineLimit(1)
                .truncationMode(.tail)
            
            
            if showDeleteButton {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.accent)
                    .padding(2)
                    .contentShape(.interaction, .rect)
                    .onTapGesture {
                        onDelete?()
                    }
            }
        }
        .frame(minWidth: 50)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(.backgroundTag)
        .clipShape(Capsule())
        
        if maxWidth == .infinity {
            content
        } else {
            content
                .frame(maxWidth: maxWidth, alignment: .leading)
        }
    }
}

#Preview {
    VStack(alignment:.leading, spacing: 16) {
        // 短文字 - 自适应宽度（受最小宽度45限制）
        TagView(text: "菜")
        
         // 中等文字 - 自适应宽度
         TagView(text: "家常菜")
        
         // 带删除按钮 - 自适应宽度
         TagView(text: "营养", showDeleteButton: true) {
             print("删除标签")
         }
        
         // 较长文字，maxWidth=120 - 在120宽度内自适应
         TagView(text: "这是一个长标签名称", maxWidth: 120)
        
         // 超长文字，maxWidth=120 - 达到最大宽度，文字截断
         TagView(text: "这是一个很长很长的标签名称用于测试宽度控制和截断功能", maxWidth: 120)
        
         // 超长文字带删除按钮 - 默认maxWidth=80，文字截断
         TagView(
             text: "超长标签测试超长标签测试超长标签测试",
             showDeleteButton: true
         )
        
        // 演示不同maxWidth的效果
        VStack(alignment: .leading, spacing: 8) {
            Text("不同maxWidth效果对比：")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 测试120pt限制
            TagView(text: "这是一个非常非常非常非常长的厨具名称用于测试120pt宽度限制", showDeleteButton: true, maxWidth: 150)
            
            TagView(text: "相同的长文字内容", maxWidth: 80)
            TagView(text: "相同的长文字内容", maxWidth: 120)
            TagView(text: "相同的长文字内容", maxWidth: 140)
        }
    }
    .padding()
}
