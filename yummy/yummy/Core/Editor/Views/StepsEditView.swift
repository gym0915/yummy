//
//  StepsEditView.swift
//  yummy
//
//  Created by steve on 2025/9/9.
//

import SwiftUI
import LucideIcons

struct StepsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: StepsEditViewModel
    let editType: StepEditType
    let onSave: (Any) -> Void
    
    init(formula: Formula, editType: StepEditType, onSave: @escaping (Any) -> Void) {
        self.editType = editType
        self._viewModel = StateObject(wrappedValue: StepsEditViewModel(formula: formula, editType: editType))
        self.onSave = onSave
    }
    
    // 是否发生变更
    private var hasChanges: Bool { viewModel.hasChanges }
    
    private var isEmpty: Bool {
        switch editType {
        case .preparation:
            return viewModel.editedPreparationSteps.isEmpty
        case .cooking:
            return viewModel.editedCookingSteps.isEmpty
        case .tips:
            return viewModel.editedTips.isEmpty
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Modal Handle
            ModalHandleView()
                .padding(.top, 6)
            
            // Navigation Bar
            NavigationBarSection
            
            // Content
            ScrollView {
                contentView
                    .padding(.horizontal, 8)
                    .padding(.top, 16)
            }
        }
        .background(Color.backgroundDefault)
    }
    
    private var contentView: some View {
    
        VStack(spacing: 16) {
            CardContainerView {
                VStack(spacing: 16) {
                    EditCardTitleView(
                        iconName: editType.iconName,
                        title: editType.title,
                        showAddButton: true,
                        onAddButtonTap: {
                            addNewStep()
                        }
                    )
                    
                    if isEmpty {
                        Text(editType.emptyMessage)
                            .appStyle(.body)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(currentSteps.enumerated()), id: \.offset) { index, _ in
                                stepRow(at: index)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func stepRow(at index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // 步骤编号
            VStack(alignment: .center, spacing: 4) {
                CircularBadgeView(backgroundColor: .brandSecondary) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.accentColor)
                }
                .padding(.top, 8) // 对齐文本编辑器的顶部
            }
            
            // 文本编辑区域
            VStack(alignment: .leading, spacing: 4) {
                EditTextFieldView(
                    placeholder: editType.placeholder,
                    text: stepBinding(at: index),
                    maxLength: editType.maxLength,
                    isMultiline: true,
                    minHeight: 60
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 删除按钮
            VStack {
                CirculeButton(
                    iconName: "x",
                    isEnabled: true,
                    size: 36,
                    action: {
                        removeStep(at: index)
                    }
                )
                .padding(.top, 8) // 对齐文本编辑器的顶部
                
                Spacer() // 确保删除按钮保持在顶部
            }
        }
    }
    
    private var currentSteps: [Any] {
        switch editType {
        case .preparation:
            return viewModel.editedPreparationSteps
        case .cooking:
            return viewModel.editedCookingSteps
        case .tips:
            return viewModel.editedTips
        }
    }
    
    private func addNewStep() {
        viewModel.addNewStep()
    }
    
    private func removeStep(at index: Int) {
        viewModel.removeStep(at: index)
    }
    
    private func stepBinding(at index: Int) -> Binding<String> {
        switch editType {
        case .preparation:
            return Binding(
                get: { 
                    guard index < viewModel.editedPreparationSteps.count else { return "" }
                    return viewModel.editedPreparationSteps[index].details 
                },
                set: { newValue in
                    viewModel.updateStepDetails(at: index, details: newValue)
                }
            )
        case .cooking:
            return Binding(
                get: { 
                    guard index < viewModel.editedCookingSteps.count else { return "" }
                    return viewModel.editedCookingSteps[index].details 
                },
                set: { newValue in
                    viewModel.updateStepDetails(at: index, details: newValue)
                }
            )
        case .tips:
            return Binding(
                get: { 
                    guard index < viewModel.editedTips.count else { return "" }
                    return viewModel.editedTips[index] 
                },
                set: { newValue in
                    viewModel.updateStepDetails(at: index, details: newValue)
                }
            )
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
    
    // MARK: - 保存
    private func handleSave() {
        Task {
            await viewModel.save()
            
            // 根据编辑类型传递不同的数据
            switch editType {
            case .preparation:
                onSave(viewModel.editedPreparationSteps)
            case .cooking:
                onSave(viewModel.editedCookingSteps)
            case .tips:
                onSave(viewModel.editedTips)
            }
            
            dismiss()
        }
    }
}

#Preview {
    StepsEditView(
        formula: Formula.mock,
        editType: .tips
    ) { updatedSteps in
        print("Updated steps: \(updatedSteps)")
    }
}
