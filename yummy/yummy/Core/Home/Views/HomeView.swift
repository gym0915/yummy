//
//  HomeView.swift
//  yummy
//
//  Created by steve on 2025/6/19.
//

import SwiftUI
import LucideIcons
import Foundation
import SafariServices

struct HomeView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @Binding var navigationPath: [NavigationPage]
    let zoomNamespace: Namespace.ID
    
    // 跳转状态管理
    @State private var selectedFormula: Formula?
    
    // 删除确认 Alert 状态
    @State private var showDeleteAlert: Bool = false
    @State private var formulaToDelete: Formula?
    @State private var showHowToSheet: Bool = false
    @State private var howToURLForSheet: URL?
    
    private let columns:[GridItem] = [
        GridItem(
            .flexible(),
            spacing: 16
        ),
        GridItem(
            .flexible(),
            spacing: 16
        )
    ]
    
    var body: some View {
        mainContentView
    }
    
    private var NavigationBarSection: some View {
        CustomNavigationBar(
            title: homeViewModel.navigationTitle,
            titleIcon: Image("icon-logo2"),
            leadingButton: nil,
            trailingButtonLeft: nil,
            trailingButtonRight: NavigationBarButtonConfiguration(
                iconName: Lucide.cookingPot,
                text: nil,
                action: {
                    navigationPath.append(.cuisine(focusId: nil))
                },
                isEnabled: true,
                badgeCount: homeViewModel.cuisineCount > 0 ? homeViewModel.cuisineCount : nil
            )
        )
    }
    
    // MARK: - Background Gradient
    private var backgroundGradientLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .brandSecondary,
                    .white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
//            LinearGradient(
//                colors: [
//                    .backgroundWhite.opacity(0.3),
//                    .backgroundWhite.opacity(1)
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .ignoresSafeArea()
        }
        .frame(maxHeight: .infinity)
    }
    
    private var mainContentView: some View {
        contentWithBackground
            .onChange(of: homeViewModel.selectedFormulaFromNotification) { _, newFormula in
                handleNotificationSelection(newFormula)
            }
            .onChange(of: homeViewModel.deleteConfirmationRequestId) { _, targetId in
                handleDeleteConfirmationRequest(targetId)
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                deleteConfirmationAlertButtons
            } message: {
                deleteConfirmationAlertMessage
            }
            .sheet(isPresented: $showHowToSheet) {
                if let url = howToURLForSheet {
                    InAppBrowserView(url: url)
                        .ignoresSafeArea()
                }
            }
    }
    
    // MARK: - Content with Background
    private var contentWithBackground: some View {
        ZStack {
            backgroundGradientLayer
            
            VStack(spacing: 0) {
                NavigationBarSection
                Spacer()
                contentSection
            }
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        Group {
            if !homeViewModel.formulaList.isEmpty {
                formulaGridView
            } else {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Formula Grid View
    private var formulaGridView: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(homeViewModel.formulaList) { formula in
                    formulaCardView(for: formula)
                }
            }
            .animation(.spring(), value: homeViewModel.formulaList)
            .padding(.init(top: 16, leading: 16, bottom: 100, trailing: 16))
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Formula Card View
    private func formulaCardView(for formula: Formula) -> some View {
        HomeCardView(formula: formula)
            .matchedTransitionSource(id: formula.id, in: zoomNamespace)
            .transition(.scale.combined(with: .opacity))
            .onTapGesture {
                handleCardTap(for: formula)
            }
            .onLongPressGesture {
                handleCardLongPress(for: formula)
            }
    }

    // MARK: - Notification and Alert Handlers
    private func handleNotificationSelection(_ newFormula: Formula?) {
        if let formula = newFormula {
            // 直接添加到导航路径
            navigationPath.append(.detail(formula))
            // 清除通知选中状态，避免重复触发
            homeViewModel.clearNotificationSelection()
        }
    }
    
    private func handleDeleteConfirmationRequest(_ targetId: String?) {
        guard let targetId = targetId else { return }
        if let formula = homeViewModel.formulaList.first(where: { $0.id == targetId }) {
            triggerDeleteConfirmation(for: formula)
        }
        // 消费后清空
        homeViewModel.deleteConfirmationRequestId = nil
    }
    
    // MARK: - Alert Components
    @ViewBuilder
    private var deleteConfirmationAlertButtons: some View {
        Button("取消", role: .cancel) {
            // 取消时隐藏覆盖层
            homeViewModel.hideDeleteOverlay()
        }
        Button("删除", role: .destructive) {
            if let formula = formulaToDelete {
                deleteFormula(formula)
            }
        }
    }
    
    @ViewBuilder
    private var deleteConfirmationAlertMessage: some View {
        if let formula = formulaToDelete {
            if formula.isCuisine {
                Text("\(formula.name) 在料理清单中，是否删除？")
            } else {
                Text("是否删除 \(formula.name)？")
            }
        }
    }

    // MARK: - Event Handlers
    private func handleCardTap(for formula: Formula) {
        // 如果当前正在显示删除覆盖层且为当前卡片，则触发删除确认
        if homeViewModel.deleteOverlayTargetId == formula.id {
            triggerDeleteConfirmation(for: formula)
            return
        }
        
        switch formula.state {
        case .error:
            // 离线拦截：无网络则提示，不触发重试
            if !NetworkMonitor.shared.isConnected {
                ToastManager.shared.show("当前网络连接不可用", style: .warning)
                return
            }
            // 重试前标记重置锚点，使进度从 0 开始
            homeViewModel.markRetryStart(for: formula.id)
            Task {
                await FormulaGenerationService.shared.retry(formula: formula)
            }
        case .upload, .finish:
            // 直接添加到导航路径
            navigationPath.append(.detail(formula))
        default:
            break
        }
    }
    
    private func handleCardLongPress(for formula: Formula) {
        if formula.state != .loading {
            formulaToDelete = formula
            homeViewModel.showDeleteOverlay(for: formula.id)
            homeViewModel.markDeletingStart(formula.id)
        }
    }

    // MARK: - 删除逻辑
    private func triggerDeleteConfirmation(for formula: Formula) {
        formulaToDelete = formula
        homeViewModel.suspendOverlayAutoHide()
        showDeleteAlert = true
    }
    
    private func deleteFormula(_ formula: Formula) {
        // 防重复：如果该条正在删除，直接返回
        if homeViewModel.isDeleting(formula.id) {
            return
        }
        homeViewModel.markDeletingStart(formula.id)
        Task {
            do {
                try await FormulaRepository.shared.delete(id: formula.id)
                // 删除成功后隐藏覆盖层
                await MainActor.run {
                    homeViewModel.hideDeleteOverlay()
                    formulaToDelete = nil
                    homeViewModel.markDeletingEnd(formula.id)
                }
            } catch {
                // 删除失败，显示错误提示
                await MainActor.run {
                    ToastManager.shared.show("删除失败", style: .error)
                    homeViewModel.hideDeleteOverlay()
                    formulaToDelete = nil
                    homeViewModel.markDeletingEnd(formula.id)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(alignment:.center,spacing: 0) {
            
            VStack(spacing: 8) {
                Image("icon-flowers")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 145, height: 145)
                
                Text("终于等到你！\n点击下方按钮开始")
                    .appStyle(.title)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                Button("如何使用") {
                    openHowToLink()
                }
                //.appStyle(.subtitle)
            }
            .frame(maxWidth: .infinity,alignment:.center)
        }
    }

    private var howToURL: URL? {
        guard let urlString = Bundle.main.infoDictionary?["HOW_TO_URL"] as? String else { return nil }
        return URL(string: urlString)
    }

    private func openHowToLink() {
        guard let url = howToURL else { return }
        howToURLForSheet = url
        showHowToSheet = true
    }

}

#Preview {
    struct HomeViewPreviewContainer: View {
        @Namespace var ns
        var body: some View {
            HomeView(navigationPath: .constant([]), zoomNamespace: ns)
                .environmentObject(HomeViewModel())
        }
    }
    return HomeViewPreviewContainer()
}
