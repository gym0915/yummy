//
//  CuisineFormulaItemView.swift
//  yummy
//
//  Created by steve on 2025/7/28.
//

import SwiftUI

struct CuisineFormulaItemView: View {
    let formula: Formula
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // 左侧：菜谱图片区域
                imageSection
                
                // 右侧：菜谱名称
                VStack(alignment: .leading) {
                    Text(formula.name)
                        .appStyle(.cardTitle)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            // 分隔线
//            Divider()
//                .background(.lineFrame)
        }
    }
    
    // MARK: - 图片区域
    private var imageSection: some View {
        Group {
            if let imagePath = formula.imgpath, !imagePath.isEmpty {
                LocalImageView(imagePath: imagePath, placeholder: "图片加载失败")
                    .frame(width: 60, height: 60)
                    .cornerRadius(6)
            } else {
                // 占位符
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    )
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        CuisineFormulaItemView(
            formula: Formula.mock,
            onTap: {}
        )
        .padding(.horizontal, 16)
        
        CuisineFormulaItemView(
            formula: Formula.mockFinish,
            onTap: {}
        )
        .padding(.horizontal, 16)
    }
    .background(Color.backgroundDefault)
} 
