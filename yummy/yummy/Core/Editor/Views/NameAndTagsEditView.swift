//
//  NameAndTagsEditView.swift
//  yummy
//
//  Created by steve on 2025/1/7.
//

import SwiftUI
import LucideIcons

struct NameAndTagsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NameAndTagsEditViewModel
    
    // 回调
    let onSave: (String, [String]) -> Void
    
    init(formula: Formula, onSave: @escaping (String, [String]) -> Void) {
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: NameAndTagsEditViewModel(formula: formula))
    }
    
    var body: some View {
        ZStack {
            Color.backgroundDefault.ignoresSafeArea()
            
            VStack(spacing: 16) {
                
                // 拖拽指示器
                ModalHandleView()
                    .padding(.top, 6)
                
                // 自定义导航栏
                NavigationBarSection
                
                VStack(spacing: 8) {
                    // 名字编辑区域
                    nameEditSection
                    
                    // 标签编辑区域
                    tagsEditSection
                    
                    Spacer()
                }
                .padding(.vertical,16)
                .padding(.horizontal,8)
            }
        }
        // 移除错误处理的 alert 和加载状态的 overlay
        // 改用 ToastManager 来显示保存结果
    }
    

    
    private var NavigationBarSection: some View {
        CustomNavigationBar(
            title: AnyView(Text("修改").appStyle(.navigationTitle)),
            titleIcon: Image("icon-edit"),
            leadingButton: nil,
            trailingButtonLeft: nil,
            trailingButtonRight: NavigationBarButtonConfiguration(
                iconName: Lucide.check,
                text: nil,
                action: {
                    handleSave()
                },
                isEnabled: viewModel.canSave
            )
        )
    }
    
    // MARK: - 名字编辑区域
    private var nameEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardContainerView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题
                    EditCardTitleView(
                        iconName: "icon-food",
                        title: "美食名字"
                    )
                    
                    // 输入框
                    EditTextFieldView(
                    placeholder: "请输入美食名字",
                    text: $viewModel.editedName,
                    maxLength: 14
                )
                }
            }
        }
    }
    
    // MARK: - 标签编辑区域
    private var tagsEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardContainerView {
                VStack(alignment: .leading, spacing: 16) {
                    // 标题
                    EditCardTitleView(
                        iconName: "icon-tags",
                        title: "标签"
                    )
                    
                    EditTagsView(
                        tags: $viewModel.editedTags,
                        newTagText: $viewModel.newTagText,
                        tagWidth: 60,
                        canAddTag: viewModel.canAddTag,
                        onAddTag: {
                            viewModel.addNewTag()
                        },
                        onRemoveTag: { index in
                            viewModel.removeTag(at: index)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    private func handleSave() {
        Task {
            await viewModel.save()
            
            // 保存完成后调用回调并关闭页面
            // Toast 会自动显示保存结果
            onSave(viewModel.editedName, viewModel.editedTags)
            dismiss()
        }
    }
}

// MARK: - 预览
#Preview {
    NameAndTagsEditView(
        formula: Formula.mock,
        onSave: { name, tags in
            print("保存: \(name), 标签: \(tags)")
        }
    )
}
