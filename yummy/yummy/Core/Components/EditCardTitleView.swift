//
//  EditCardTitleView.swift
//  yummy
//
//  Created by steve on 2025/1/7.
//

import SwiftUI

/// 编辑页面卡片标题组件
/// 显示带图标和文字的卡片标题，用于各种编辑页面的 section 标题
struct EditCardTitleView: View {
    private let iconName: String
    private let title: String
    private let height: CGFloat
    private let spacing: CGFloat
    private let verticalPadding: CGFloat
    private let showAddButton: Bool
    private let onAddButtonTap: (() -> Void)?
    
    /// 初始化编辑卡片标题视图
    /// - Parameters:
    ///   - iconName: 图标名称
    ///   - title: 标题文字
    ///   - height: 标题高度，默认为 44
    ///   - spacing: 图标与文字间距，默认为 8
    ///   - verticalPadding: 垂直内边距，默认为 8
    ///   - showAddButton: 是否显示加号按钮，默认为 false
    ///   - onAddButtonTap: 加号按钮点击回调
    init(
        iconName: String,
        title: String,
        height: CGFloat = 44,
        spacing: CGFloat = 8,
        verticalPadding: CGFloat = 8,
        showAddButton: Bool = false,
        onAddButtonTap: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.title = title
        self.height = height
        self.spacing = spacing
        self.verticalPadding = verticalPadding
        self.showAddButton = showAddButton
        self.onAddButtonTap = onAddButtonTap
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            Image(iconName)
                .resizable()
                .frame(width: 36, height: 36)
            Text(title)
                .appStyle(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if showAddButton {
                
                ButtonContentView(
                    buttonConfig: NavigationBarButtonConfiguration.init(
                        iconName: UIImage(lucideId: "plus"),
                        text: nil,
                        action: {
                            onAddButtonTap?()
                        }
                    )
                )
            }
        }
        .frame(height: height)
        .padding(.vertical, verticalPadding)
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 16) {
        EditCardTitleView(
            iconName: "icon-food",
            title: "美食名字"
        )
        
        EditCardTitleView(
            iconName: "icon-tags",
            title: "标签"
        )
        
        EditCardTitleView(
            iconName: "icon-tips",
            title: "小窍门",
            height: 50,
            spacing: 12,
            showAddButton: true
        )
    }
    .padding()
    .background(Color.backgroundDefault)
}
