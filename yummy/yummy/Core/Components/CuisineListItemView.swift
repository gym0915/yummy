//
//  CuisineListItemView.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import SwiftUI

struct CuisineListItemView: View {
    let item: CuisineListItem
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 48) { // 根据Figma设计调整间距为48px
                // 左侧：食材名称区域
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .appStyle(item.isCompleted ? .subtitle : .cardTitle)
                        .strikethrough(item.isCompleted)
                        .foregroundColor(item.isCompleted ? .textLightGray : .textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 中间：用量信息
                Text(item.subtitle)
                    .appStyle(item.isCompleted ? .subtitle : .cardTitle)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .textLightGray : .textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // 右侧：复选框区域
                CuisineCheckboxView(isCompleted: item.isCompleted, action: onToggle)
                    .padding(.vertical, 10) // 根据Figma设计添加垂直内边距
            }
//            .padding(.horizontal, 8)
            .padding(.vertical, 16) // 根据Figma设计调整垂直内边距
            .background(.backgroundWhite) // 复刻Figma设计中的白色背景
//            .animation(.easeInOut(duration: 0.3), value: item.isCompleted)
            
            // 分隔线
//            Divider()
//                .background(.lineFrame) // 模拟设计中的#E9E9E9
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        CuisineGroupHeaderView(formulaName: "老母鸡汤")
        
        CuisineListItemView(
            item: CuisineListItem(
                formulaId: "1",
                formulaName: "老母鸡汤",
                title: "菲力牛排",
                subtitle: "1 块",
                type: .ingredient,
                originalIndex: 0,
                isCompleted: false
            ),
            onToggle: {}
        )
        
        CuisineListItemView(
            item: CuisineListItem(
                formulaId: "1",
                formulaName: "老母鸡汤",
                title: "洋葱",
                subtitle: "适量",
                type: .ingredient,
                originalIndex: 1,
                isCompleted: true
            ),
            onToggle: {}
        )
        
        CuisineGroupHeaderView(formulaName: "手撕包菜")
        
        CuisineListItemView(
            item: CuisineListItem(
                formulaId: "2",
                formulaName: "手撕包菜",
                title: "大白菜",
                subtitle: "1 棵",
                type: .ingredient,
                originalIndex: 0,
                isCompleted: false
            ),
            onToggle: {}
        )
    }
    .background(Color.backgroundDefault)
} 
