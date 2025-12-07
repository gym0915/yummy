//
//  CuisineView.swift
//  yummy
//
//  Created by steve on 2025/6/29.
//

import SwiftUI
import LucideIcons

struct CuisineView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CuisineViewModel()
    
    @Binding var navigationPath: [NavigationPage]
    let focusId: String?
    @State private var showClearConfirmation = false
    // 新增：第三个 Tab 的左滑展开状态（只允许单个卡片处于左滑打开）
    @State private var swipedFormulaId: String? = nil
    // 控制仅滚动一次（按 Tab 维度）
    @State private var didScrollToFocusByTab: [CuisineTab: Bool] = [:]
    // 控制初次进入时只执行一次默认 Tab 与聚焦逻辑
    @State private var didRunInitialSetup = false
    
    var body: some View {
        ZStack {
            Color.backgroundDefault.ignoresSafeArea()
                
            VStack(spacing: 0) {
                navigationBar
                
                if !viewModel.isEmpty {
                    cuisineTabPicker
                }
                
                // 主要内容区域
                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    ScrollViewReader { proxy in
                        Group {
                            if viewModel.selectedTab == .cuisine {
                                cuisineStepsList
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 8) {
                                        ingredientsAndPreparationList
                                            .padding(.horizontal,8)
                                    }
                                    .padding(.top,16)
                                    .animation(.snappy(duration: 0.35), value: viewModel.tabStatuses)
                                }
                                .scrollIndicators(.hidden)
                                .animation(.easeInOut(duration: 0.25), value: viewModel.expandedFormulaIdsByTab[viewModel.selectedTab] ?? "")
                            }
                        }
                        .onChange(of: viewModel.expandedFormulaIdsByTab[viewModel.selectedTab] ?? nil) { newId in
                            let hasScrolled = didScrollToFocusByTab[viewModel.selectedTab] ?? false
                            guard let target = newId, hasScrolled == false else { return }
                            withAnimation(.spring()) {
                                proxy.scrollTo(target, anchor: .top)
                            }
                            didScrollToFocusByTab[viewModel.selectedTab] = true
                        }
                        .onChange(of: viewModel.cuisineFormulas) { _ in
                            // 数据到达后尝试再次应用聚焦
                            viewModel.applyFocusIfNeeded(focusId)
                        }
                        .onChange(of: viewModel.tabStatuses) { _ in
                            // 状态到达后尝试再次应用聚焦
                            viewModel.applyFocusIfNeeded(focusId)
                        }
                        .onChange(of: viewModel.selectedTab) { newTab in
                            // 切换 Tab 时：重置该 Tab 的滚动标记，并应用聚焦与滚动
                            didScrollToFocusByTab[newTab] = false
                            viewModel.applyFocusIfNeeded(focusId)
                            if let target = viewModel.expandedFormulaIdsByTab[newTab] ?? nil {
                                Task { @MainActor in
                                    withAnimation(.spring()) {
                                        proxy.scrollTo(target, anchor: .top)
                                    }
                                    didScrollToFocusByTab[newTab] = true
                                }
                            }
                        }
                        .onAppear {
                            guard didRunInitialSetup == false else { return }
                            didRunInitialSetup = true
                            // 移除：不再强制设置默认 Tab 为 .procurement，避免后续点击被重置
                            // viewModel.selectedTab = .procurement
                            // 应用聚焦展开
                            viewModel.applyFocusIfNeeded(focusId)
                            // 如果 ViewModel 已经设置展开，则尝试滚动（考虑首次渲染阶段）
                            if let target = viewModel.expandedFormulaIdsByTab[viewModel.selectedTab] ?? nil, (didScrollToFocusByTab[viewModel.selectedTab] ?? false) == false {
                                Task { @MainActor in
                                    try? await Task.sleep(nanoseconds: 50_000_000)
                                    withAnimation(.spring()) {
                                        proxy.scrollTo(target, anchor: .top)
                                    }
                                    didScrollToFocusByTab[viewModel.selectedTab] = true
                                }
                            }
                        }
                    }
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
        .alert("你确定？", isPresented: $showClearConfirmation) {
            Button("取消", role: .cancel) {
                AppLog("❌ [CuisineView] 用户取消清空操作", level: .debug, category: .ui)
            }
            Button("是的", role: .destructive) {
                AppLog("✅ [CuisineView] 用户确认清空操作", level: .debug, category: .ui)
                Task {
                    await viewModel.clearAllCuisineFormulas()
                }
            }
        } message: {
            Text("清除料理清单中的内容？")
        }
        // 移除 navigationDestination 相关代码
    }
    
    // MARK: - Tab选择器
    private var cuisineTabPicker: some View {
        CuisineFilterView(selectedTab: $viewModel.selectedTab)
            .background(Divider(), alignment: .bottom)
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image("icon-question")
                .resizable()
                .frame(width: 96, height: 96)
            
            Text("还没有料理清单")
                .appStyle(.title)
            Text("当你添加料理到清单中就可以在这里看到")
                .appStyle(.body)
                .foregroundColor(.textLightGray)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - 料理清单视图
    private var cuisineListView: some View {
        Group {
            // 根据选中的tab显示不同内容
            if viewModel.selectedTab == .cuisine {
                // 第三个tab：使用List显示菜谱列表，支持左滑删除
                cuisineStepsList
                    
//                    .padding(.top, 16)
            } else {
                // 前两个tab：使用ScrollView显示分组的项目列表（方案B：ScrollView + ForEach + 自定义分隔线）
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ingredientsAndPreparationList
                            .padding(.horizontal,8)
                    }
                    .padding(.top,16)
                }
                .scrollIndicators(.hidden)
                .animation(.easeInOut(duration: 0.25), value: viewModel.expandedFormulaIdsByTab[viewModel.selectedTab] ?? "")
            }
        }
    }

    // MARK: - 食材和备菜列表（前两个tab）
    private var ingredientsAndPreparationList: some View {
        let groups = viewModel.getGroupedTabItems()
        return ForEach(Array(groups.enumerated()), id: \.element.formula.id) { index, group in
            VStack(spacing: 8) {
                CardContainerView {
                    VStack(spacing: 0) {
                        // 卡片头部
                        CuisineCardHeaderView(
                            formula: group.formula,
                            enableSwipeToDelete: false,
                            onTapImage: {
                                AppLog("🖱️ [CuisineView] 用户点击菜谱图片 - \(group.formula.name)", level: .debug, category: .ui)
                                navigationPath.append(.detail(group.formula))
                            },
                            onToggleExpand: {
                                AppLog("🖱️ [CuisineView] 用户切换菜谱展开 - \(group.formula.name)", level: .debug, category: .ui)
                                viewModel.toggleExpand(for: group.formula.id)
                            }
                        )
                        
                        // 展开内容（移除 transition，使用视图级隐式动画）
                        if viewModel.isExpanded(formulaId: group.formula.id) {
                            expandedContent(for: group)
                        }
                    }
                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        print("🖱️ [CuisineView] 用户点击卡片区域切换展开 - \(group.formula.name)")
//                        viewModel.toggleExpand(for: group.formula.id)
//                    }
                }
                .id(group.formula.id)
            }
        }
    }
    
    // MARK: - 料理步骤列表（第三个tab）
    private var cuisineStepsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.cuisineFormulas, id: \.id) { formula in
                    CuisineFormulaRowView(
                        formula: formula,
                        isExpanded: viewModel.isExpanded(formulaId: formula.id),
                        onTapImage: {
                            swipedFormulaId = nil
                            AppLog("🖱️ [CuisineView] 用户点击菜谱图片 - \(formula.name)", level: .debug, category: .ui)
                            navigationPath.append(.detail(formula))
                        },
                        onToggleExpand: {
                            swipedFormulaId = nil
                            AppLog("🖱️ [CuisineView] 用户切换菜谱展开 - \(formula.name)", level: .debug, category: .ui)
                            viewModel.toggleExpand(for: formula.id)
                        },
                        isSwipedOpen: swipedFormulaId == formula.id,
                        onSwipe: { offset in
                            if offset < -50 {
                                swipedFormulaId = formula.id
                            } else if offset > -20 {
                                if swipedFormulaId == formula.id {
                                    swipedFormulaId = nil
                                }
                            }
                        },
                        onDelete: {
                            AppLog("🗑️ [CuisineView] 用户左滑删除菜谱 - \(formula.name)", level: .debug, category: .ui)
                            swipedFormulaId = nil
                            Task {
                                await viewModel.removeFromCuisine(formula: formula)
                            }
                        }
                    )
                    .id(formula.id)
                }
            }
            .padding(.horizontal,8)
            .padding(.vertical,16)
        }
        .scrollIndicators(.hidden)
        .animation(.easeInOut(duration: 0.25), value: (viewModel.expandedFormulaIdsByTab[viewModel.selectedTab] ?? nil) ?? "")
        .background(Color.backgroundDefault)
    }
    
    // MARK: - 展开内容
    @ViewBuilder
    private func expandedContent(for group: (formula: Formula, items: [CuisineListItem])) -> some View {
        VStack(spacing: 0) {
            // 分隔线
//            Divider()
//                .background(.lineDefault)
            
            // 根据不同的tab使用不同的内容
            if viewModel.selectedTab == .prepare {
                // 备菜页面使用特殊布局
                preparationGroupContent(for: group)
            } else {
                // 采购页面使用默认布局
                ForEach(group.items) { item in
                    CuisineListItemView(item: item) {
                        AppLog("🖱️ [CuisineView] 用户点击复选框 - itemId: \(item.id), title: \(item.title), 当前状态: \(item.isCompleted)", level: .debug, category: .ui)
                        withAnimation(.snappy(duration: 0.35)) {
                            Task {
                                await viewModel.toggleItemCompletion(
                                    itemId: item.id,
                                    formulaId: item.formulaId
                                )
                            }
                        }
                    }
                    .contentTransition(.opacity)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)),
                                             removal: .opacity))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
    
    // MARK: - 备菜页面特殊布局
    @ViewBuilder
    private func preparationGroupContent(for group: (formula: Formula, items: [CuisineListItem])) -> some View {
        let preparationSteps = group.items.filter { $0.type == .preparationStep }
        let sauceItems = group.items.filter { $0.type == .saucePreparation }
        
        // 备菜步骤
        ForEach(Array(preparationSteps.enumerated()), id: \.element.id) { index, item in
            CuisineStepItemView(
                item: item,
                stepIndex: index + 1
            ) {
                AppLog("🖱️ [CuisineView] 用户点击备菜复选框 - itemId: \(item.id), title: \(item.title), 当前状态: \(item.isCompleted)", level: .debug, category: .ui)
                withAnimation(.snappy(duration: 0.35)) {
                    Task {
                        await viewModel.toggleItemCompletion(
                            itemId: item.id,
                            formulaId: item.formulaId
                        )
                    }
                }
            }
            .contentTransition(.opacity)
            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)),
                                     removal: .opacity))
        }
        
        // 料汁部分（如果有）
        if let sauceItem = sauceItems.first, !group.formula.ingredients.sauce.isEmpty {
            SauceItemView(
                formulaId: group.formula.id,
                sauceIngredients: group.formula.ingredients.sauce,
                isCompleted: sauceItem.isCompleted
            ) {
                AppLog("🖱️ [CuisineView] 用户点击料汁复选框 - itemId: \(sauceItem.id), 当前状态: \(sauceItem.isCompleted)", level: .debug, category: .ui)
                withAnimation(.snappy(duration: 0.35)) {
                    Task {
                        await viewModel.toggleItemCompletion(
                            itemId: sauceItem.id,
                            formulaId: sauceItem.formulaId
                        )
                    }
                }
            }
            .contentTransition(.opacity)
            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .trailing)),
                                     removal: .opacity))
        }
    }
    
    // MARK: - 自定义导航栏
    private var navigationBar: some View {
        CustomNavigationBar(
            title: AnyView(
                Text("开始料理").appStyle(.title)
            ),
            leadingButton: NavigationBarButtonConfiguration(
                iconName: Lucide.chevronLeft,
                text: nil,
                action: { dismiss() },
                isEnabled: true
            ),

            trailingButtonRight: NavigationBarButtonConfiguration(
                iconName: Lucide.trash2,
                text: nil,
                action: {
                    AppLog("🗑️ [CuisineView] 用户点击清空按钮", level: .debug, category: .ui)
                    showClearConfirmation = true
                },
                isEnabled: !viewModel.cuisineFormulas.isEmpty
            ),
        )
    }
}



#Preview {
    @Previewable @State var navigationPath: [NavigationPage] = []
    return CuisineView(navigationPath: $navigationPath, focusId: nil)
}
