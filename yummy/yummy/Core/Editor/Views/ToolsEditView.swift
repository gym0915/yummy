//
//  ToolsEditView.swift
//  yummy
//
//  Created by steve on 2025/9/8.
//

import SwiftUI
import LucideIcons

struct ToolsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ToolsEditViewModel
    
    let onSave: ([Tool]) -> Void
    private let maxTagCount: Int
    private let maxTagLength: Int
    
    init(formula: Formula,
         maxTagCount: Int = 10, 
         maxTagLength: Int = 30, 
         onSave: @escaping ([Tool]) -> Void = { _ in }) {
        self.onSave = onSave
        self.maxTagCount = maxTagCount
        self.maxTagLength = maxTagLength
        self._viewModel = StateObject(wrappedValue: ToolsEditViewModel(
            formula: formula,
            maxTagCount: maxTagCount,
            maxTagLength: maxTagLength
        ))
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
                    // 厨具编辑区域
                    toolsEditSection
                    
                    Spacer()
                }
                .padding(.vertical,16)
                .padding(.horizontal,8)
            }
        }
    }
    
    // MARK: - 厨具编辑区域
    private var toolsEditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardContainerView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // 标题
                    EditCardTitleView(
                        iconName: "icon-tools",
                        title: "厨具"
                    )
                    
                    // 已有厨具显示和添加新厨具
                    EditTagsView(
                        tags: Binding(
                            get: { viewModel.editedTools.map { $0.name } },
                            set: { newNames in
                                viewModel.editedTools = newNames.map { Tool(name: $0) }
                            }
                        ),
                        newTagText: $viewModel.newToolText,
                        maxTagCount: maxTagCount,
                        maxTagLength: maxTagLength,
                        placeholder: "请输入厨具名称",
                        tagWidth: 80,
                        canAddTag: viewModel.canAddTool,
                        onAddTag: {
                            viewModel.addNewTool()
                        },
                        onRemoveTag: { index in
                            viewModel.removeTool(at: index)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Navigation Bar Section
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

    
    // MARK: - 辅助方法
    private func handleSave() {
        Task {
            // 尝试保存数据到仓库
            let saveSuccess = await viewModel.saveTools()
            
            // 调用外部回调，传递编辑后的数据
            onSave(viewModel.editedTools)
            
            // 关闭编辑页面
            dismiss()
            
            if !saveSuccess {
                // TODO: 显示错误提示
                AppLog("⚠️ [厨具编辑] 保存失败，但用户界面已关闭", level: .warning, category: .ui)
            }
        }
    }
}

#Preview {
    ToolsEditView(
        formula: Formula(
            name: "示例菜谱",
            ingredients: Ingredients(
                mainIngredients: [],
                spicesSeasonings: [],
                sauce: []
            ),
            tools: [
                Tool(name: "案板11111111111111"),
                Tool(name: "刀"),
                Tool(name: "锅")
            ],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: Date(),
            state: .finish
        ),
        maxTagCount: 10,
        maxTagLength: 100,
        onSave: { tools in
            print("保存厨具: \(tools.map { $0.name })")
        }
    )
}
