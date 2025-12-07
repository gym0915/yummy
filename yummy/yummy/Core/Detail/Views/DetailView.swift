//
//  DetailView.swift
//  yummy
//
//  Created by steve on 2025/7/7.
//

import SwiftUI
import LucideIcons
import UIKit
import SwipeActions

struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    
    @Environment(\.dismiss) private var dismiss // 关闭视图用
    
    // 导航路径绑定
    @Binding var navigationPath: [NavigationPage]

    private let animationDelayNanoseconds: UInt64 = 200_000_000
    
    // 用于相机底部操作面板的动画与拖拽
    @State private var showImagePickerPanelAnimation: Bool = false
    @State private var imagePickerDragOffset: CGSize = .zero
    
    // 用于菜单底部操作面板的动画与拖拽
    @State private var showMenuPanelAnimation: Bool = false
    @State private var menuDragOffset: CGSize = .zero
    
    // 用于管理滑动卡片状态，确保只有一个卡片处于滑动状态
    @State private var activeSwipeCard: SwipeCardType? = nil
    
    // 编辑页面状态
    @State private var showNameAndTagsEdit = false
    @State private var showMainIngredientsEdit = false
    @State private var showSpicesSeasoningsEdit = false
    @State private var showSauceEdit = false
    @State private var showToolsEdit = false
    @State private var showPreparationEdit = false
    @State private var showCookingStepsEdit = false
    @State private var showTipsEdit = false
    
    // 初始化方法
    init(formulaId: String,
         navigationPath: Binding<[NavigationPage]>,
         repository: FormulaRepositoryProtocol? = nil
    ) {
        if let repository = repository {
            self._viewModel = StateObject(wrappedValue: DetailViewModel(formulaId: formulaId, formulaRepository: repository))
        } else {
            self._viewModel = StateObject(wrappedValue: DetailViewModel(formulaId: formulaId))
        }
        self._navigationPath = navigationPath
    }
    
    private let horizontalPadding: CGFloat = 16
    
    // MARK: - View Body
    
    var body: some View {
        mainContentView
            .onChange(of: viewModel.scrollOffset) { _, _ in
                // 滚动偏移量变化已在 ViewModel 中处理
            }
            .background(Color.backgroundDefault.ignoresSafeArea())
            .toolbarVisibility(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                joinCookingAndShareButton
                    .padding(.horizontal, 96)
            }
            .sheet(isPresented: $viewModel.isShareSheetPresented) {
                ActivityView(activityItems: [viewModel.formula?.name ?? "菜谱"])
            }
            .onChange(of: viewModel.shouldShowCamera) { _, shouldShow in
                if shouldShow, let formula = viewModel.formula {
                    navigationPath.append(.camera(formula))
                    viewModel.resetCameraState()
                }
            }
            .onChange(of: viewModel.shouldShowPhotoLibrary) { _, shouldShow in
                if shouldShow, let formula = viewModel.formula {
                    navigationPath.append(.photoLibrary(formula))
                    viewModel.resetPhotoLibraryState()
                }
            }
            .sheet(isPresented: $showNameAndTagsEdit) {
                nameAndTagsEditSheet
            }
            .sheet(isPresented: $showMainIngredientsEdit) {
                mainIngredientsEditSheet
            }
            .sheet(isPresented: $showSpicesSeasoningsEdit) {
                spicesSeasoningsEditSheet
            }
            .sheet(isPresented: $showSauceEdit) {
                sauceEditSheet
            }
            .sheet(isPresented: $showToolsEdit) {
                toolsEditSheet
            }
            .sheet(isPresented: $showPreparationEdit) {
                preparationEditSheet
            }
            .sheet(isPresented: $showCookingStepsEdit) {
                cookingStepsEditSheet
            }
            .sheet(isPresented: $showTipsEdit) {
                tipsEditSheet
            }
            .onChange(of: viewModel.showImagePickerSheet) { _, isPresented in
                handleImagePickerSheetChange(isPresented)
            }
            .overlay {
                overlayContent
            }
    }
    
    // MARK: - 主要内容视图
    private var mainContentView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                scrollableContent
                navigationBarOverlay
            }
        }
    }
    
    // MARK: - 可滚动内容
    private var scrollableContent: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical) {
                contentBody
                    .background(scrollOffsetReader)
            }
            .coordinateSpace(name: "scroll")
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .onAppear {
                // 页面出现时的处理
            }
        }
    }
    
    // MARK: - 内容主体
    private var contentBody: some View {
        Group {
            if let formula = viewModel.formula {
                VStack(alignment: .leading, spacing: 16) {
                    imageSection
                    
                    VStack(alignment: .leading, spacing: 8) {
                        SwipeViewGroup {
                            nameAndTagsSection
                            mainIngredientsSection
                            spicesSeasoningsSection
                            sauceSection
                            toolsSection
                            preparationSection
                            cookingStepsSection
                                .id("cookingSteps")
                            tipsSection
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            } else {
//                loadingView
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack {
            Spacer()
            Text("菜谱数据加载中...")
                .foregroundColor(.textLightGray)
            Spacer()
        }
    }
    
    // MARK: - 滚动偏移读取器
    private var scrollOffsetReader: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            Color.clear
                .onAppear {
                    viewModel.updateScrollOffset(0)
                }
                .onChange(of: offset) { _, newOffset in
                    viewModel.updateScrollOffset(newOffset)
                }
        }
    }
    
    // MARK: - 导航栏覆盖层
    private var navigationBarOverlay: some View {
        VStack(spacing: 0) {
            navigationBar
            Spacer()
        }
    }
    
    // MARK: - 名称和标签编辑表单
    private var nameAndTagsEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                NameAndTagsEditView(
                    formula: formula,
                    onSave: { newName, newTags in
                        // TODO: 实现保存逻辑
                        print("保存名字: \(newName), 标签: \(newTags)")
                    }
                )
            }
        }
    }
    
    private var mainIngredientsEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                MainIngredientsEditView(
                    formula: formula,
                    editType: .mainIngredients,
                    onSave: { updatedIngredients in
                        print("保存主料: \(updatedIngredients)")
                    }
                )
            }
        }
    }
    
    private var spicesSeasoningsEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                MainIngredientsEditView(
                    formula: formula,
                    editType: .spicesSeasonings,
                    onSave: { updatedIngredients in
                        print("保存配料: \(updatedIngredients)")
                    }
                )
            }
        }
    }
    
    private var sauceEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                MainIngredientsEditView(
                    formula: formula,
                    editType: .sauce,
                    onSave: { updatedIngredients in
                        print("保存蘸料: \(updatedIngredients)")
                    }
                )
            }
        }
    }
    
    private var toolsEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                ToolsEditView(
                    formula: formula,
                    onSave: { updatedTools in
                        AppLog("✅ [厨具编辑] 保存厨具成功: \(updatedTools.map { $0.name })", level: .info, category: .ui)
                    }
                )
            }
        }
    }
    
    private var preparationEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                StepsEditView(
                    formula: formula,
                    editType: .preparation,
                    onSave: { updatedSteps in
                        AppLog("✅ [备菜编辑] 保存备菜步骤成功", level: .info, category: .ui)
                    }
                )
            }
        }
    }
    
    private var cookingStepsEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                StepsEditView(
                    formula: formula,
                    editType: .cooking,
                    onSave: { updatedSteps in
                        AppLog("✅ [料理编辑] 保存料理步骤成功", level: .info, category: .ui)
                    }
                )
            }
        }
    }
    
    private var tipsEditSheet: some View {
        Group {
            if let formula = viewModel.formula {
                StepsEditView(
                    formula: formula,
                    editType: .tips,
                    onSave: { updatedTips in
                        AppLog("✅ [小窍门编辑] 保存小窍门成功", level: .info, category: .ui)
                    }
                )
            }
        }
    }
    
    // MARK: - 覆盖层内容
    private var overlayContent: some View {
        ZStack {
            imagePickerOverlay
            shareOverlay
        }
    }
    
    // MARK: - 图片选择器覆盖层
    private var imagePickerOverlay: some View {
        Group {
            if viewModel.showImagePickerSheet {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture { dismissImagePickerPanel() }
                
                imagePickerActionView
            }
        }
    }
    
    // MARK: - 图片选择器操作视图
    private var imagePickerActionView: some View {
        VStack {
            Spacer()
            let items: [BottomActionItem<ImagePickerAction>] = [
                .init(id: .takePhoto, icon: Lucide.camera, title: "拍照"),
                .init(id: .chooseFromLibrary, icon: Lucide.image, title: "从相册选取图片")
            ]
            BottomActionAreaView(items: items) { action in
                switch action {
                case .takePhoto:
                    viewModel.handleTakePhoto()
                    dismissImagePickerPanel()
                case .chooseFromLibrary:
                    viewModel.handleChooseFromLibrary()
                    dismissImagePickerPanel()
                }
            }
            .offset(y: imagePickerDragOffset.height > 0 ? imagePickerDragOffset.height : 0)
            .simultaneousGesture(imagePickerDragGesture)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .offset(y: showImagePickerPanelAnimation ? 0 : 200)
        .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0), value: showImagePickerPanelAnimation)
    }
    
    // MARK: - 图片选择器拖拽手势
    private var imagePickerDragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if value.translation.height > 0 {
                    imagePickerDragOffset = value.translation
                }
            }
            .onEnded { value in
                let dismissThreshold: CGFloat = 55
                if value.translation.height > dismissThreshold {
                    dismissImagePickerPanel()
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        imagePickerDragOffset = .zero
                    }
                }
            }
    }
    
    // MARK: - 分享覆盖层
    private var shareOverlay: some View {
        Group {
            if viewModel.showShareOverlay, let formula = viewModel.formula {
                ShareOverlayView(
                    formula: formula,
                    formulaImage: viewModel.formulaImage,
                    isPresented: $viewModel.showShareOverlay,
                    imageMaxWidth: UIScreen.main.bounds.width - 32
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(999)
            }
        }
    }
    
    // MARK: - 图片选择器表单变化处理
    private func handleImagePickerSheetChange(_ isPresented: Bool) {
        if isPresented {
            showImagePickerPanelAnimation = false
            imagePickerDragOffset = .zero
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: animationDelayNanoseconds)
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                    showImagePickerPanelAnimation = true
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showImagePickerPanelAnimation = false
            }
            imagePickerDragOffset = .zero
        }
    }
    
    // MARK: - 私有组件
    
    // 通用标题组件
    private func sectionTitle(iconString: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(iconString)
                .resizable()
//                .renderingMode(.template)
//                .foregroundColor(.accent)
                .frame(width: 24, height: 24)
            Text(title)
                .font(.headline)
                .appStyle(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
    
    // 卡片容器组件
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(8)
        .background(Color.backgroundWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .lineDefault.opacity(0.5), radius: 2, x: 1, y: 1)
    }
    
    // 列表项组件
    private func listItem(quantity: String, name: String) -> some View {
        HStack(spacing: 0) {
            Text(quantity)
                .appStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(name)
                .appStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - 自定义导航栏
    private var navigationBar: some View {
        CustomNavigationBar(
            title: AnyView(Text(viewModel.isNavigationBarTransparent ? "" : (viewModel.formula?.name ?? "")).appStyle(.title)),
            leadingButton: NavigationBarButtonConfiguration(
                iconName: Lucide.chevronLeft,
                text: nil,
                action: { dismiss() },
                isEnabled: true
            ),
            trailingButtonLeft:NavigationBarButtonConfiguration(
                iconName: Lucide.share2,
                text: nil,
                action: {
                    viewModel.handleShareButtonTap()
                }
            ),
            trailingButtonRight: NavigationBarButtonConfiguration(
                iconName: Lucide.chartPie,
                text: nil,
                action: nil),
            isTransparent: viewModel.isNavigationBarTransparent
        )
        .animation(.easeInOut, value: viewModel.isNavigationBarTransparent)
    }
    
    // MARK: - 图片区域
    private var imageSection: some View {
        Group {
            if viewModel.shouldShowUploadView {
                ImageUploadView(onTap: viewModel.handleImageUpload)
                    .padding(.horizontal, horizontalPadding)
            } else if let formula = viewModel.formula, let imagePath = formula.imgpath, !imagePath.isEmpty {
                LocalImageView(
                    imagePath: imagePath,
                    placeholder: "图片加载失败",
                    onImageLoaded: { image in
                        viewModel.setFormulaImage(image)
                    },
                    enableZoomEffect: true  // 启用缩放效果
                )
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    viewModel.handleImageUpload()
                }
            }
        }
    }
    
    // MARK: - 菜谱名称和标签区域
    private var nameAndTagsSection: some View {
        SwipeView {
            cardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    // 菜谱名称
                    HStack(spacing:8) {
                        Text(viewModel.formula?.name ?? "")
                            .appStyle(.navigationTitle)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical,8)
                    }
                    
                    // 标签区域
                    if let tags = viewModel.formula?.tags, !tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                TagView(text: tag)
                                    
                            }
                        }
                        .padding(.vertical,14)
                        
                    }
                }
            }
        } trailingActions: { context in
            ButtonContentView(
                buttonConfig: NavigationBarButtonConfiguration(
                    iconName: Lucide.pencilLine,
                    text: nil,
                    action: {
                        context.state.wrappedValue = .closed
                        handleEditNameAndTags()
                    }
                )
            )
            .background(
                Circle()
                    .fill(Color.brandSecondary)
//                    .frame(width: 48, height: 48)
            )
        }
        .swipeMinimumDistance(20)
        .swipeActionsStyle(.cascade)
      
    }
    
    // MARK: - 主料区域
    private var mainIngredientsSection: some View {
        SwipeView {
            cardContainer {
                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle(iconString: "icon-mainfood", title: "主料")
                    
                    if let formula = viewModel.formula {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(formula.ingredients.mainIngredients, id: \.name) { item in
                                listItem(quantity: item.quantity, name: item.name)
                            }
                        }
                    }
                }
            }
        } trailingActions: { context in
            ButtonContentView(
                buttonConfig: NavigationBarButtonConfiguration(
                    iconName: Lucide.pencilLine,
                    text: nil,
                    action: {
                        context.state.wrappedValue = .closed
                        handleEditMainIngredients()
                    }
                )
            )
            .background(
                Circle()
                    .fill(Color.brandSecondary)
//                    .frame(width: 48, height: 48)
            )
        }
        .swipeMinimumDistance(20)
        .swipeActionsStyle(.cascade)
    }
    
    // MARK: - 香料调味料区域
    private var spicesSeasoningsSection: some View {
        Group {
            if let formula = viewModel.formula, !formula.ingredients.spicesSeasonings.isEmpty {
                SwipeView {
                    cardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle(iconString: "icon-spices", title: "配料")
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(formula.ingredients.spicesSeasonings, id: \.name) { item in
                                    listItem(quantity: item.quantity, name: item.name)
                                }
                            }
                        }
                    }
                } trailingActions: { context in
                    ButtonContentView(
                        buttonConfig: NavigationBarButtonConfiguration(
                            iconName: Lucide.pencilLine,
                            text: nil,
                            action: {
                                context.state.wrappedValue = .closed
                                handleEditSpicesSeasonings()
                            }
                        )
                    )
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
//                            .frame(width: 48, height: 48)
                    )
                }
                .swipeMinimumDistance(20)
                .swipeActionsStyle(.cascade)
            }
        }
    }
    
    // MARK: - 调味汁区域
    private var sauceSection: some View {
        Group {
            if let formula = viewModel.formula, !formula.ingredients.sauce.isEmpty {
                SwipeView {
                    cardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle(iconString: "icon-sauce", title: "蘸料")
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(formula.ingredients.sauce, id: \.name) { item in
                                    listItem(quantity: item.quantity, name: item.name)
                                }
                            }
                        }
                    }
                } trailingActions: { context in
                    ButtonContentView(
                        buttonConfig: NavigationBarButtonConfiguration(
                            iconName: Lucide.pencilLine,
                            text: nil,
                            action: {
                                context.state.wrappedValue = .closed
                                handleEditSauce()
                            }
                        )
                    )
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
//                            .frame(width: 48, height: 48)
                    )
                }
                .swipeMinimumDistance(20)
                .swipeActionsStyle(.cascade)
            }
        }
    }
    
    // MARK: - 厨具
    private var toolsSection: some View {
        Group {
            if let formula = viewModel.formula, !formula.tools.isEmpty {
                SwipeView {
                    cardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle(iconString: "icon-tools", title: "厨具")
                            
                            HStack(spacing: 16) {
                                ForEach(formula.tools, id: \.name) { tool in
                                    Text(tool.name).appStyle(.body)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                } trailingActions: { context in
                    ButtonContentView(
                        buttonConfig: NavigationBarButtonConfiguration(
                            iconName: Lucide.pencilLine,
                            text: nil,
                            action: {
                                context.state.wrappedValue = .closed
                                handleEditTools()
                            }
                        )
                    )
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
//                            .frame(width: 48, height: 48)
                    )
                }
                .swipeMinimumDistance(20)
                .swipeActionsStyle(.cascade)
            }
        }
    }
    
    // MARK: - 准备工作
    private var preparationSection: some View {
        Group {
            if let formula = viewModel.formula, !formula.preparation.isEmpty {
                SwipeView {
                    cardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle(iconString: "icon-prepare", title: "备菜")
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(formula.preparation.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment:.center, spacing: 8) {
                                        CircularBadgeView(backgroundColor: .brandSecondary) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundColor(.accentColor)
                                        }
                                        Text(step.details)
                                            .appStyle(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                    }
                } trailingActions: { context in
                    ButtonContentView(
                        buttonConfig: NavigationBarButtonConfiguration(
                            iconName: Lucide.pencilLine,
                            text: nil,
                            action: {
                                context.state.wrappedValue = .closed
                                handleEditPreparation()
                            }
                        )
                    )
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
//                            .frame(width: 48, height: 48)
                    )
                }
                .swipeMinimumDistance(20)
                .swipeActionsStyle(.cascade)
            }
        }
    }
    
    // MARK: - 料理步骤
    private var cookingStepsSection: some View {
        SwipeView {
            cardContainer {
                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle(iconString: "icon-cook", title: "料理")
                    
                    if let formula = viewModel.formula {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(formula.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .center, spacing: 8) {
                                    CircularBadgeView(backgroundColor: .brandSecondary) {
                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .light))
                                            .foregroundColor(.accentColor)
                                    }
                                    Text(step.details)
                                        .appStyle(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.vertical, 16)
                            }
                        }
                    }
                }
            }
        } trailingActions: { context in
            ButtonContentView(
                buttonConfig: NavigationBarButtonConfiguration(
                    iconName: Lucide.pencilLine,
                    text: nil,
                    action: {
                        context.state.wrappedValue = .closed
                        handleEditCookingSteps()
                    }
                )
            )
            .background(
                Circle()
                    .fill(Color.brandSecondary)
//                    .frame(width: 48, height: 48)
            )
        }
        .swipeMinimumDistance(20)
        .swipeActionsStyle(.cascade)
    }
    
    // MARK: - 小窍门区域
    private var tipsSection: some View {
        Group {
            if let formula = viewModel.formula, !formula.tips.isEmpty {
                SwipeView {
                    cardContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            sectionTitle(iconString: "icon-tips", title: "小窍门")
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(formula.tips.enumerated()), id: \.offset) { index, tip in
                                    HStack(alignment: .center, spacing: 8) {
                                        CircularBadgeView(backgroundColor: .brandSecondary) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundColor(.accentColor)
                                        }
                                        Text(tip)
                                            .appStyle(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                    }
                } trailingActions: { context in
                    ButtonContentView(
                        buttonConfig: NavigationBarButtonConfiguration(
                            iconName: Lucide.pencilLine,
                            text: nil,
                            action: {
                                context.state.wrappedValue = .closed
                                handleEditTips()
                            }
                        )
                    )
                    .background(
                        Circle()
                            .fill(Color.brandSecondary)
//                            .frame(width: 48, height: 48)
                    )
                }
                .swipeMinimumDistance(20)
                .swipeActionsStyle(.cascade)
            }
        }
    }
    
    // MARK: - 底部加入料理清单按钮
    private var joinCookingAndShareButton: some View {
        
        Button {
            viewModel.toggleCuisineStatus {
                // 导航到料理清单页面，并聚焦到当前菜谱
                withAnimation(.spring()) {
                    if let formulaId = viewModel.formula?.id {
                        navigationPath = [.cuisine(focusId: formulaId)]
                    }
                }
            }
        } label: {
            Text(viewModel.cuisineButtonText)
                .foregroundColor(.textWhite)
                .appStyle(.subtitle)
                .padding()
        }
        .frame(height: 42)
//        .foregroundColor(.clear)
//        .buttonStyle(.glass)
        .background(
            Capsule()
                .fill(viewModel.cuisineButtonColor)
                .glassEffect(.clear.interactive(), in: .capsule)
        )
        .glassEffect(.clear.interactive(), in: .capsule)
        .clipShape(Capsule())

        
//        HStack(alignment: .center, spacing: 16) {
//            Rectangle()
//                .fill(viewModel.cuisineButtonColor)
//                .frame(height: 46)
//                .clipShape(RoundedRectangle(cornerRadius: 24))
//                .overlay(
//                    Text(viewModel.cuisineButtonText)
//                        .foregroundColor(.textWhite)
//                        .appStyle(.subtitle)
//                )
//                .onTapGesture {
//                    viewModel.toggleCuisineStatus {
//                        // 导航到料理清单页面，并聚焦到当前菜谱
//                        withAnimation(.spring()) {
//                            if let formulaId = viewModel.formula?.id {
//                                navigationPath = [.cuisine(focusId: formulaId)]
//                            }
//                        }
//                    }
//                }
//        }
    }

    // MARK: - 辅助方法
    private func dismissImagePickerPanel(animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                showImagePickerPanelAnimation = false
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 220_000_000)
                viewModel.showImagePickerSheet = false
                imagePickerDragOffset = .zero
            }
        } else {
            showImagePickerPanelAnimation = false
            viewModel.showImagePickerSheet = false
            imagePickerDragOffset = .zero
        }
    }
    
//    private func dismissMenuPanel(animated: Bool = true) {
//        if animated {
//            withAnimation(.easeInOut(duration: 0.2)) {
//                showMenuPanelAnimation = false
//            }
//            Task { @MainActor in
//                try? await Task.sleep(nanoseconds: animationDelayNanoseconds)
//                viewModel.showMenuActionSheet = false
//                menuDragOffset = .zero
//            }
//        } else {
//            showMenuPanelAnimation = false
//            viewModel.showMenuActionSheet = false
//            menuDragOffset = .zero
//        }
//    }
    
    // MARK: - SwipeActions 处理方法
    
    /// 处理滑动状态变化，确保只有一个卡片处于滑动状态
    private func handleSwipeStateChange(cardType: SwipeCardType, isOpen: Bool) {
        if isOpen {
            // 如果当前卡片被打开，关闭其他所有卡片
            if activeSwipeCard != cardType {
                activeSwipeCard = cardType
                AppLog("📱 [DetailView] 卡片 \(cardType.rawValue) 左滑打开", level: .debug, category: .ui)
            }
        } else {
            // 如果当前卡片被关闭
            if activeSwipeCard == cardType {
                activeSwipeCard = nil
                AppLog("📱 [DetailView] 卡片 \(cardType.rawValue) 左滑关闭", level: .debug, category: .ui)
            }
        }
    }
    
    private func handleEditNameAndTags() {
        AppLog("🏷️ [DetailView] 编辑菜谱名称和标签", level: .info, category: .ui)
        showNameAndTagsEdit = true
    }
    
    private func handleEditMainIngredients() {
        AppLog("🥬 [DetailView] 编辑主料", level: .info, category: .ui)
        showMainIngredientsEdit = true
    }
    
    private func handleEditSpicesSeasonings() {
        AppLog("🧂 [DetailView] 编辑配料", level: .info, category: .ui)
        showSpicesSeasoningsEdit = true
    }
    
    private func handleEditSauce() {
        AppLog("🥄 [DetailView] 编辑蘸料", level: .info, category: .ui)
        showSauceEdit = true
    }
    
    private func handleEditTools() {
        AppLog("🔧 [DetailView] 编辑厨具", level: .info, category: .ui)
        showToolsEdit = true
    }
    
    private func handleEditPreparation() {
        AppLog("📋 [DetailView] 编辑备菜", level: .info, category: .ui)
        showPreparationEdit = true
    }
    
    private func handleEditCookingSteps() {
        AppLog("👨‍🍳 [DetailView] 编辑料理步骤", level: .info, category: .ui)
        showCookingStepsEdit = true
    }
    
    private func handleEditTips() {
        AppLog("💡 [DetailView] 编辑小窍门", level: .info, category: .ui)
        showTipsEdit = true
    }
}

// MARK: - RecipeStepCard
private struct RecipeStepCard: View {
    let index: Int
    let total: Int
    let step: CookingStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 步骤标题部分（有背景色）
            HStack(spacing: 8) {
                Text("\(index + 1).")
                    .appStyle(.cardTitle)
                    .foregroundColor(.iconSecondary)
                Text(step.step)
                    .appStyle(.cardTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading,8)
//            .padding(16)
            .padding(.vertical,16)
            .background(Color.brandSecondary)
            
            // 步骤内容部分
            Text(step.details)
                .appStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .padding(.vertical,8)
                .padding(.leading,13)
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ScrollOffsetPreferenceKey
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

fileprivate enum ImagePickerAction: Hashable { case takePhoto, chooseFromLibrary }
fileprivate enum MenuAction: Hashable { case share, edit }

// 滑动卡片类型枚举
fileprivate enum SwipeCardType: String, CaseIterable {
    case nameAndTags = "nameAndTags"
    case mainIngredients = "mainIngredients"
    case spicesSeasonings = "spicesSeasonings"
    case sauce = "sauce"
    case tools = "tools"
    case preparation = "preparation"
    case cookingSteps = "cookingSteps"
    case tips = "tips"
}


// Mock repository for preview
import Combine

class MockFormulaRepository: FormulaRepositoryProtocol {
    private let subject = CurrentValueSubject<[Formula], Never>([Formula.mockFinish])
    var formulasPublisher: AnyPublisher<[Formula], Never> { subject.eraseToAnyPublisher() }
    
    func all() -> [Formula] {
        let formulas = [Formula.mockFinish]
        AppLog("MockFormulaRepository all(): \(formulas.count) formulas, first ID: \(formulas.first?.id ?? "none")", level: .debug, category: .service)
        return formulas
    }
    
    func save(_ formula: Formula) async throws {}
    func update(_ formula: Formula) async throws {}
    func delete(id: String) async throws {}
}

#Preview {
    @Previewable @State var navigationPath: [NavigationPage] = []
    
    let mockRepository = MockFormulaRepository()
    
    DetailView(formulaId: Formula.mockFinish.id, navigationPath: $navigationPath, repository: mockRepository)
}
//
//#Preview("Finish State") {
//    @State var navigationPath: [NavigationPage] = []
//    return DetailView(formula: Formula.mockFinish, navigationPath: $navigationPath)
//}
