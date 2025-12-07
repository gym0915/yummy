//
//  CuisineCardHeaderView.swift
//  yummy
//
//  Created by steve on 2025/8/14.
//

import SwiftUI

struct CuisineCardHeaderView: View {
    let formula: Formula
    let enableSwipeToDelete: Bool
    let onTapImage: () -> Void
    let onToggleExpand: () -> Void
    
    init(
        formula: Formula,
        enableSwipeToDelete: Bool = false,
        onTapImage: @escaping () -> Void,
        onToggleExpand: @escaping () -> Void
    ) {
        self.formula = formula
        self.enableSwipeToDelete = enableSwipeToDelete
        self.onTapImage = onTapImage
        self.onToggleExpand = onToggleExpand
    }
    
    var body: some View {
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
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleExpand()
        }
    }
    
    // MARK: - 图片区域
    private var imageSection: some View {
        Group {
            if let imagePath = formula.imgpath, !imagePath.isEmpty {
                LocalImageView(imagePath: imagePath, placeholder: "图片加载失败")
                    .frame(width: 60, height: 60)
                    .cornerRadius(6)
                    .clipped()
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
        .contentShape(Rectangle())
        .onTapGesture {
            // 阻止事件冒泡，保持图片的独立点击事件
            onTapImage()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CuisineCardHeaderView(
            formula: Formula.mock,
            enableSwipeToDelete: false,
            onTapImage: { AppLog("点击图片", level: .debug, category: .ui) },
            onToggleExpand: { AppLog("切换展开", level: .debug, category: .ui) }
        )
        
        CuisineCardHeaderView(
            formula: Formula.mockFinish,
            enableSwipeToDelete: true,
            onTapImage: { AppLog("点击图片", level: .debug, category: .ui) },
            onToggleExpand: { AppLog("切换展开", level: .debug, category: .ui) }
        )
    }
    .padding()
    .background(Color.backgroundDefault)
}
