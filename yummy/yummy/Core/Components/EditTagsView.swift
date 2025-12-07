//
//  EditTagsView.swift
//  yummy
//
//  Created by Steve on 2025/1/6.
//

import SwiftUI
import LucideIcons

// MARK: - 编辑标签视图

struct EditTagsView: View {
    @Binding private var tags: [String]
    @Binding private var newTagText: String
    private let maxTagCount: Int
    private let maxTagLength: Int
    private let placeholder: String
    private let tagWidth: CGFloat
    private let onAddTag: () -> Void
    private let onRemoveTag: (Int) -> Void
    private let canAddTag: Bool
    
    // MARK: - 初始化
    
    /// 初始化编辑标签视图
    /// - Parameters:
    ///   - tags: 标签数组绑定
    ///   - newTagText: 新标签文本绑定
    ///   - maxTagCount: 最大标签数量，默认3个
    ///   - maxTagLength: 单个标签最大长度，默认4个字符
    ///   - placeholder: 输入框占位符文本，默认"添加标签"
    ///   - tagWidth: 标签宽度，默认100
    ///   - canAddTag: 是否可以添加标签
    ///   - onAddTag: 添加标签回调
    ///   - onRemoveTag: 删除标签回调
    init(
        tags: Binding<[String]>,
        newTagText: Binding<String>,
        maxTagCount: Int = 3,
        maxTagLength: Int = 100,
        placeholder: String = "添加标签",
        tagWidth: CGFloat = 100,
        canAddTag: Bool,
        onAddTag: @escaping () -> Void,
        onRemoveTag: @escaping (Int) -> Void
    ) {
        self._tags = tags
        self._newTagText = newTagText
        self.maxTagCount = maxTagCount
        self.maxTagLength = maxTagLength
        self.placeholder = placeholder
        self.tagWidth = tagWidth
        self.canAddTag = canAddTag
        self.onAddTag = onAddTag
        self.onRemoveTag = onRemoveTag
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 已有标签显示
            if !tags.isEmpty {
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 80, maximum: 250), spacing: 8)
                    ],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(tags.indices, id: \.self) { index in
                        TagView(
                            text: tags[index],
                            showDeleteButton: true,
                            onDelete: {
                                onRemoveTag(index)
                            },
                            maxWidth: tagWidth
                        )
                    }
                }
            }
            
            // 添加新标签
            if tags.count < maxTagCount {
                HStack(spacing: 16) {
                    // 输入框
                    EditTextFieldView(
                        placeholder: placeholder,
                        text: $newTagText,
                        maxLength: maxTagLength
                    )
                    
                    // 添加按钮
                    CirculeButton(
                        iconName: "plus",
                        isEnabled: canAddTag,
                        action: onAddTag
                    )
                }
            }
        }
    }
}

// MARK: - 预览
#Preview {
    @Previewable @State var tags = ["川菜", "家常菜afafaf"]
    @Previewable @State var newTagText = ""
    
    VStack(spacing: 16) {
        CardContainerView {
            VStack(alignment: .leading, spacing: 16) {
                EditCardTitleView(
                    iconName: "icon-tags",
                    title: "标签"
                )
                
                EditTagsView(
                    tags: $tags,
                    newTagText: $newTagText,
                    placeholder: "添加标签",
                    tagWidth: 120,
                    canAddTag: !newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && newTagText.count <= 10,
                    onAddTag: {
                        let trimmedText = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedText.isEmpty && trimmedText.count <= 10 && !tags.contains(trimmedText) {
                            tags.append(trimmedText)
                            newTagText = ""
                        }
                    },
                    onRemoveTag: { index in
                        tags.remove(at: index)
                    }
                )
            }
        }
    }
    .padding()
    .background(Color.backgroundDefault)
}
