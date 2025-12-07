//
//  CuisineFormulaRowView.swift
//  yummy
//
//  Created by steve on 2025/8/14.
//

import SwiftUI
import LucideIcons

struct CuisineFormulaRowView: View {
    let formula: Formula
    let isExpanded: Bool
    let onTapImage: () -> Void
    let onToggleExpand: () -> Void
    // 新增：左滑删除相关
    let isSwipedOpen: Bool
    let onSwipe: (CGFloat) -> Void
    let onDelete: () -> Void
    
    @GestureState private var dragTranslation: CGFloat = 0
    
    // 自定义初始化，给新增参数提供默认值，保证旧调用方与预览不受影响
    init(
        formula: Formula,
        isExpanded: Bool,
        onTapImage: @escaping () -> Void,
        onToggleExpand: @escaping () -> Void,
        isSwipedOpen: Bool = false,
        onSwipe: @escaping (CGFloat) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) {
        self.formula = formula
        self.isExpanded = isExpanded
        self.onTapImage = onTapImage
        self.onToggleExpand = onToggleExpand
        self.isSwipedOpen = isSwipedOpen
        self.onSwipe = onSwipe
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack {
            // 背景：删除按钮（仅在折叠状态下可见）
            if !isExpanded {
                HStack {
                    Spacer()
                    Button(action: { onDelete() }) {
                        Text("删除")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                    }
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.trailing, 16)
                }
            }
            
            // 前景：实际内容，只有折叠时可左滑
            CardContainerView {
                VStack(spacing: 0) {
                    // 卡片头部
                    CuisineCardHeaderView(
                        formula: formula,
                        enableSwipeToDelete: true,
                        onTapImage: onTapImage,
                        onToggleExpand: onToggleExpand
                    )
                    
                    // 展开内容预览（移除 transition，遵循参考实现）
                    if isExpanded {
                        expandedContent
                    }
                }
                .contentShape(Rectangle())
//                .onTapGesture {
//                    onToggleExpand()
//                }
            }
            .offset(x: isExpanded ? 0 : computedOffset)  // 展开时偏移固定为0，禁用左滑效果
            .gesture(isExpanded ? nil : dragGesture)  // 展开时禁用拖拽手势
            .animation(.easeInOut(duration: 0.3), value: isSwipedOpen)
        }
    }
    
    // 计算偏移量：仿参考实现
    private var computedOffset: CGFloat {
        let base: CGFloat = isSwipedOpen ? -96 : 0
        let drag = min(0, dragTranslation)
        return max(base + drag, -96)
    }
    
    // 拖拽手势：仿参考实现
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragTranslation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                onSwipe(value.translation.width)
            }
    }
    
    // MARK: - 展开内容预览
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
//            stepHeader
            stepsList
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 步骤标题
    private var stepHeader: some View {
        HStack(spacing: 8) {
            Image(uiImage: Lucide.chefHat)
                .renderingMode(.template)
                .foregroundColor(.iconDefault)
                .frame(width: 24, height: 24)
            
            Text("步骤")
                .fontWeight(.bold)
                .appStyle(.cardTitle)
                
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
    
    // MARK: - 步骤列表
    private var stepsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(formula.steps.enumerated()), id: \.offset) { index, step in
                stepRow(index: index, step: step)
            }
        }
    }
    
    // MARK: - 单个步骤行
    private func stepRow(index: Int, step: CookingStep) -> some View {
        VStack(spacing: 0) {
            // 步骤标题行 - 根据 Figma 设计使用紫色背景
            HStack(alignment: .center, spacing: 8) {
                Text("\(index + 1).")
                    .fontWeight(.bold)
                    .appStyle(.cardTitle)
                
                Text(step.step)
                    .appStyle(.cardTitle)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(.brandSecondary)
            
            // 步骤详细内容
            if !step.details.isEmpty {
                HStack(alignment: .top, spacing: 16) {
                    Text(step.details)
                        .appStyle(.body)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CuisineFormulaRowView(
            formula: Formula.mock,
            isExpanded: false,
            onTapImage: { AppLog("点击图片", level: .debug, category: .ui) },
            onToggleExpand: { AppLog("切换展开", level: .debug, category: .ui) }
        )
        
        CuisineFormulaRowView(
            formula: Formula.mockFinish,
            isExpanded: true,
            onTapImage: { AppLog("点击图片", level: .debug, category: .ui) },
            onToggleExpand: { AppLog("切换展开", level: .debug, category: .ui) }
        )
    }
    .padding()
    .background(Color.backgroundDefault)
}
