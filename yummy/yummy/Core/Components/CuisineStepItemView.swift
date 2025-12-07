//
//  CuisineStepItemView.swift
//  yummy
//
//  Created by steve on 2025/7/28.
//

import SwiftUI

struct CuisineStepItemView: View {
    let item: CuisineListItem
    let stepIndex: Int
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // 左侧：步骤序号和标题区域
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // 步骤序号
                        Text("\(stepIndex). ")
                            .appStyle(item.isCompleted ? .subtitle : .body)
                            .strikethrough(item.isCompleted)
                            
                        
                        // 步骤标题
//                        Text(item.title)
//                            .appStyle(item.isCompleted ? .subtitle : .cardTitle)
//                            .strikethrough(item.isCompleted)
//                            .foregroundColor(item.isCompleted ? .textLightGray : .textPrimary)
//                            .lineLimit(2)
                        
                        // 步骤详情
                        if !item.subtitle.isEmpty {
                            Text(item.subtitle)
                                .appStyle(item.isCompleted ? .subtitle : .body)
                                .strikethrough(item.isCompleted)
//                                .padding(.leading, 32) // 与标题对齐
                                .frame(maxWidth: .infinity,alignment: .leading)
    //                            .background(.blue)
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 右侧：复选框区域
                HStack {
//                    Spacer()
                    CuisineCheckboxView(isCompleted: item.isCompleted, action: onToggle)
                }
                .frame(width: 32,alignment: .center)
//                .background(.green)
            }
//            .padding(8)
            .padding(.vertical,8)
            .background(.backgroundWhite)
            
            // 分隔线
//            Divider()
//                .background(.lineFrame)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        CuisineStepItemView(
            item: CuisineListItem(
                formulaId: "1",
                formulaName: "红烧肉",
                title: "五花肉切块",
                subtitle: "将五花肉切成3cm见方的块，用清水冲洗干净，沥干水分备用。",
                type: .preparationStep,
                originalIndex: 0,
                isCompleted: false
            ),
            stepIndex: 1,
            onToggle: {}
        )
        
        CuisineStepItemView(
            item: CuisineListItem(
                formulaId: "1",
                formulaName: "红烧肉",
                title: "焯水去腥",
                subtitle: "锅中加入适量清水，放入五花肉块，大火烧开后焯水2-3分钟，去除血水和腥味。",
                type: .preparationStep,
                originalIndex: 1,
                isCompleted: true
            ),
            stepIndex: 2,
            onToggle: {}
        )
    }
    .background(Color.backgroundDefault)
} 
