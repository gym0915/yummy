//
//  MainIngredientsEditView.swift
//  yummy
//
//  Created by Trae AI on 2025/01/11.
//

import SwiftUI
import LucideIcons

// MARK: - 食材编辑类型枚举
enum IngredientEditType {
    case mainIngredients
    case spicesSeasonings
    case sauce
    
    var title: String {
        switch self {
        case .mainIngredients:
            return "主料"
        case .spicesSeasonings:
            return "配料"
        case .sauce:
            return "蘸料"
        }
    }
    
    var iconName: String {
        switch self {
        case .mainIngredients:
            return "icon-mainfood"
        case .spicesSeasonings:
            return "icon-spices"
        case .sauce:
            return "icon-sauce"
        }
    }
    
    var emptyMessage: String {
        switch self {
        case .mainIngredients:
            return "暂无主料，点击右上角加号添加"
        case .spicesSeasonings:
            return "暂无配料，点击右上角加号添加"
        case .sauce:
            return "暂无蘸料，点击右上角加号添加"
        }
    }
}

struct MainIngredientsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MainIngredientsEditViewModel
    let editType: IngredientEditType
    let onSave: (Any) -> Void
    
    init(formula: Formula, editType: IngredientEditType, onSave: @escaping (Any) -> Void) {
        self.editType = editType
        self._viewModel = StateObject(wrappedValue: MainIngredientsEditViewModel(formula: formula, editType: editType))
        self.onSave = onSave
    }
    
    // 是否发生变更
    private var hasChanges: Bool { viewModel.hasChanges }
    
    private var currentIngredients: [Any] {
        switch editType {
        case .mainIngredients, .spicesSeasonings:
            return viewModel.editedIngredients
        case .sauce:
            return viewModel.editedSauceIngredients
        }
    }
    
    private var isEmpty: Bool {
        switch editType {
        case .mainIngredients, .spicesSeasonings:
            return viewModel.editedIngredients.isEmpty
        case .sauce:
            return viewModel.editedSauceIngredients.isEmpty
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
                VStack(spacing: 16) {
                    CardContainerView {
                        VStack(spacing: 16) {
                            EditCardTitleView(
                                iconName: editType.iconName,
                                title: editType.title,
                                showAddButton: true,
                                onAddButtonTap: {
                                    addNewIngredient()
                                }
                            )
                            
                            if isEmpty {
                                Text(editType.emptyMessage)
                                    .appStyle(.body)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                            } else {
                                // 小标题
                                HStack(spacing: 12) {
                                    Text("材料")
                                        .appStyle(.body)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    Text("用量")
                                        .appStyle(.body)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    // 预留删除按钮列的宽度
                                    Color.clear
                                        .frame(width: 36, height: 1)
                                }

                                ForEach(currentIngredients.indices, id: \.self) { index in
                                    if index < currentIngredients.count {
                                        ingredientRow(at: index)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .background(Color.backgroundDefault)
//        .overlay(
//            ToastHostView()
//                .environmentObject(ToastManager.shared)
//        )
     }
 
     @ViewBuilder
     private func ingredientRow(at index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // 材料列
            VStack(alignment: .leading, spacing: 4) {
                
                EditTextFieldView(
                    placeholder: "请输入材料",
                    text: nameBinding(at: index),
                    maxLength: 10
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 用量列
            VStack(alignment: .leading, spacing: 4) {
                
                EditTextFieldView(
                    placeholder: "请输入用量",
                    text: quantityBinding(at: index),
                    maxLength: 6
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 删除按钮
            CirculeButton(
                iconName: "x",
                isEnabled: true,
                size: 36,
                action: {
                    removeIngredient(
                        at: index
                    )
                }
            )
        }
    }
    
    private func addNewIngredient() {
        viewModel.addNewIngredient()
    }
    
    private func removeIngredient(at index: Int) {
         viewModel.removeIngredient(at: index)
     }
     
     private func nameBinding(at index: Int) -> Binding<String> {
         switch editType {
         case .mainIngredients, .spicesSeasonings:
             return Binding(
                 get: { 
                     guard index >= 0 && index < viewModel.editedIngredients.count else { return "" }
                     return viewModel.editedIngredients[index].name 
                 },
                 set: { newValue in
                     guard index >= 0 && index < viewModel.editedIngredients.count else { return }
                     var ing = viewModel.editedIngredients[index]
                     ing = Ingredient(
                         name: newValue,
                         quantity: ing.quantity,
                         category: ing.category
                     )
                     viewModel.editedIngredients[index] = ing
                 }
             )
         case .sauce:
             return Binding(
                 get: { 
                     guard index >= 0 && index < viewModel.editedSauceIngredients.count else { return "" }
                     return viewModel.editedSauceIngredients[index].name 
                 },
                 set: { newValue in
                     guard index >= 0 && index < viewModel.editedSauceIngredients.count else { return }
                     var ing = viewModel.editedSauceIngredients[index]
                     ing = SauceIngredient(
                         name: newValue,
                         quantity: ing.quantity
                     )
                     viewModel.editedSauceIngredients[index] = ing
                 }
             )
         }
     }
     
     private func quantityBinding(at index: Int) -> Binding<String> {
         switch editType {
         case .mainIngredients, .spicesSeasonings:
             return Binding(
                 get: { 
                     guard index >= 0 && index < viewModel.editedIngredients.count else { return "" }
                     return viewModel.editedIngredients[index].quantity 
                 },
                 set: { newValue in
                     guard index >= 0 && index < viewModel.editedIngredients.count else { return }
                     var ing = viewModel.editedIngredients[index]
                     ing = Ingredient(
                         name: ing.name,
                         quantity: newValue,
                         category: ing.category
                     )
                     viewModel.editedIngredients[index] = ing
                 }
             )
         case .sauce:
             return Binding(
                 get: { 
                     guard index >= 0 && index < viewModel.editedSauceIngredients.count else { return "" }
                     return viewModel.editedSauceIngredients[index].quantity 
                 },
                 set: { newValue in
                     guard index >= 0 && index < viewModel.editedSauceIngredients.count else { return }
                     var ing = viewModel.editedSauceIngredients[index]
                     ing = SauceIngredient(
                         name: ing.name,
                         quantity: newValue
                     )
                     viewModel.editedSauceIngredients[index] = ing
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
            case .mainIngredients, .spicesSeasonings:
                onSave(viewModel.editedIngredients)
            case .sauce:
                onSave(viewModel.editedSauceIngredients)
            }
            
            dismiss()
        }
    }
}

#Preview {
    MainIngredientsEditView(
        formula: Formula.mock,
        editType: .mainIngredients
    ) { updatedIngredients in
        print("Updated ingredients: \(updatedIngredients)")
    }
//    .environmentObject(ToastManager.shared)
}
