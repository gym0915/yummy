//
//  HomeCardView.swift
//  yummy
//
//  Created by steve on 2025/6/22.
//

import SwiftUI
import LucideIcons
import UIKit

struct HomeCardView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    let formula: Formula
    
    // 在 HomeCardView 顶部定义统一高度常量
    private let cardHeight: CGFloat = ImageConstants.homeCardImageHeight + 46
    // 第六步：不再在局部存储进度，也不再起 Task；由 VM 的 tick 驱动刷新
    @State private var displayProgress: Double = 0
    // 第七步：收尾与显隐控制
    @State private var isFinalizingProgress: Bool = false
    @State private var previousState: FormulaState? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            switch formula.state {
            case .loading:
                loadingDataView
            case .error:
                retryView
            case .upload:
                waitToUploadView(formula: formula)
            case .finish:
                imageCardView(formula: formula)
            }
        }
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .background(.backgroundWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .lineDefault, radius: 2, x: 1, y: 1)
        // 将进度边框绘制在外层卡片容器上，确保覆盖整张卡片
        .overlay(
            Group {
                if formula.state == .loading || isFinalizingProgress {
                    // 使用插值后的显示进度，保证每次刷新之间平滑过渡
                    ProgressBorderShape(progress: displayProgress)
                        .stroke(
                            .accent.opacity(0.5),
//                            .brandSecondary,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                        )
                        .allowsHitTesting(false)
                }
            }
        )
        // 删除覆盖层（由 VM 控制当前仅一个显示）
        .overlay(
            Group {
                if homeViewModel.deleteOverlayTargetId == formula.id {
                    ZStack {
                        Color.backgroundDefault.opacity(0.85)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        VStack(spacing: 12) {
                            ButtonContentView(
                                buttonConfig: NavigationBarButtonConfiguration(
                                    iconName: Lucide.trash2,
                                    text: nil,
                                    action: {
                                        // 第3步接入：点击后回调到 HomeView 弹出系统 Alert
                                        homeViewModel.requestDeleteConfirmation(for: formula.id)
                                    }
                                )
                            )
                            .background(
                                Circle()
                                    .frame(width: 48, height: 48)
                                    .foregroundStyle(.backgroundWhite)
                            )
                            
//                            Text("删除").appStyle(.body)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 点击覆盖层任意区域，也触发删除确认请求
                        homeViewModel.requestDeleteConfirmation(for: formula.id)
                    }
                }
            }
        )
        // 订阅 VM 的 tick 来推进 loading 慢速动画（不在非 loading 状态执行）
        .onChange(of: homeViewModel.tick) { _, _ in
            updateOnTick()
        }
        // 初始装载：loading 则推进一次，否则保持隐藏
        .onAppear { setupInitialState() }
        // 仅在状态变更时做收尾/重置，避免被 tick 反复触发
        .onChange(of: formula.state) { old, new in
            handleStateChange(old: old, new: new)
        }
        // 长按触发删除覆盖层（仅 upload/finish 可用）
        .onLongPressGesture(minimumDuration: 1.0) {
            if homeViewModel.canDelete(formula) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                homeViewModel.showDeleteOverlay(for: formula.id)
            }
        }

    }
    
    // MARK: - State machine helpers
    private func setupInitialState() {
        previousState = formula.state
        switch formula.state {
        case .loading:
            updateDisplayForLoading(animated: false)
        case .upload, .finish, .error:
            // 初始为非 loading，边框保持隐藏
            isFinalizingProgress = false
            displayProgress = 0
        }
    }
    
    private func updateOnTick() {
        guard !isFinalizingProgress else { return }
        guard formula.state == .loading else { return }
        updateDisplayForLoading(animated: true)
    }
    
    private func handleStateChange(old: FormulaState, new: FormulaState) {
        previousState = new
        switch new {
        case .loading:
            isFinalizingProgress = false
            // 从 error -> loading 的重试场景：先显示为 0，再平滑推进
            if old == .error {
                displayProgress = 0
                updateDisplayForLoading(animated: true)
            } else {
                // 其他场景：直接按 VM 进度显示
                updateDisplayForLoading(animated: false)
            }
        case .upload, .finish:
            // 仅当从 loading 切换过来时才做一次收尾
            if old == .loading { finalizeProgressAndHide() }
            else {
                isFinalizingProgress = false
                displayProgress = 0
            }
        case .error:
            resetProgress(animated: true)
        }
    }
    
    private func updateDisplayForLoading(animated: Bool) {
        let target: Double = homeViewModel.virtualProgress(for: formula)
        if animated {
            withAnimation(.linear(duration: 0.25)) {
                displayProgress = target
            }
        } else {
            displayProgress = target
        }
    }
    
    private func finalizeProgressAndHide() {
        guard !isFinalizingProgress else { return }
        isFinalizingProgress = true
        let finalizeDuration: Double = 0.25
        withAnimation(.linear(duration: finalizeDuration)) {
            displayProgress = 1.0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((finalizeDuration + 0.02) * 1_000_000_000))
            isFinalizingProgress = false
        }
    }
    
    private func resetProgress(animated: Bool) {
        isFinalizingProgress = false
        if animated {
            withAnimation(.easeOut(duration: 0.15)) { displayProgress = 0 }
        } else {
            displayProgress = 0
        }
    }
    
    private var loadingDataView: some View {
        VStack {
            VStack(spacing: 6) {
//                ProgressView()
//                    .frame(width: 24,height: 24)
//                    .tint(.iconDefault)
                
                Image("icon-write")
                    .resizable()
                    .frame(width: 96, height: 96)
                
                Text("正在整理")
                    .appStyle(.body)
//                Text("约 30 秒")
//                    .appStyle(.cardGray)
            }
        }
//        .frame(width: ImageConstants.homeCardImageWidth, height: cardHeight)
        // 宽度改由外层容器控制，避免 overlay 仅围绕内容尺寸绘制
        
//        .frame(minHeight: ImageConstants.homeCardImageHeight + 34)
//        .background(.backgroundWhite)
    }
    
    private var retryView: some View {
        VStack {
            VStack(alignment:.center, spacing: 6) {
                Image("icon-fail")
                    .resizable()
                    .frame(width: 96,height: 96)
                    .foregroundStyle(.iconDefault)
                Text("整理失败")
                    .appStyle(.body)
                Text("点击重试")
                    .appStyle(.body)
            }
        }
//        .frame(width: ImageConstants.homeCardImageWidth, height: cardHeight)
//        .frame(minHeight: ImageConstants.homeCardImageHeight + 34)
        .frame(maxWidth: .infinity)
//        .background(.white)
//        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func waitToUploadView(formula: Formula) -> some View {
        // 白色外层容器，圆角 8
        VStack(alignment: .leading, spacing: 0) {
            // 内容容器，有 4px padding
            VStack(alignment: .leading, spacing: 0) {
                // 图片上传区域
                ZStack(alignment: .topLeading) {
                    // 主要内容区域
                    VStack(spacing: 0) {
                        // Camera icon
                        Image("icon-photo")
                            .resizable()
                            .frame(width: 96,height: 96)
//                            .foregroundColor(.iconDefault)
                        
                        Text("选张美食图片吧")
                            .appStyle(.body)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding(16)
                    .frame(minHeight: ImageConstants.homeCardImageHeight)
                    .background(.backgroundDefault)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Tag 标签
                    if let firstTag = formula.tags.first {
                        TagView(text: firstTag)
                            .padding(8)
                    }
                }
                
                
                // 文字和 tag区域
                VStack(alignment: .leading, spacing: 10) {
                    Text(formula.name)
                        .appStyle(.cardTitle)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
//                        .padding(.vertical, 10)
                }
                .padding(.vertical,10)
            }
            .padding(4)
        }
//        .frame(width: ImageConstants.homeCardImageWidth, height: cardHeight)
//        .frame(minHeight: ImageConstants.homeCardImageHeight + 34)
//        .background(.backgroundWhite)
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//        .shadow(color: .lineDefault, radius: 2, x: 1, y: 1)
    }
    
    private func imageCardView(formula: Formula) -> some View {
        // 白色外层容器，圆角 8
        VStack(alignment: .leading, spacing: 0) {
            // 内容容器，有 4px padding
            VStack(alignment: .leading, spacing: 0) {
                // 图片区域
                ZStack(alignment: .topLeading) {
                    Group {
                        if let imagePath = formula.imgpath, !imagePath.isEmpty {
                            // 显示本地保存的照片
                            LocalImageView(imagePath: imagePath, placeholder: "图片加载失败")
                                .frame(maxWidth: .infinity, maxHeight: ImageConstants.homeCardImageHeight)
                                .clipped()
                        } else {
                            // 如果没有图片路径，显示占位符
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.iconDisable)
                                Text("暂无图片")
                                    .appStyle(.cardGray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: ImageConstants.homeCardImageHeight)
                            .background(.backgroundWhite)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding(16)
                    .frame(minWidth: 0, minHeight: ImageConstants.homeCardImageHeight)
//                    .frame(minHeight: ImageConstants.homeCardImageHeight)
                    .background(.backgroundDefault)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if let firstTag = formula.tags.first {
                        TagView(text: firstTag)
                            .padding(8)
                    }
                }
                
                // 文字区域
                VStack(alignment: .leading, spacing: 0) {
                    Text(formula.name)
                        .appStyle(.cardTitle)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 10)
                }
            }
            .padding(4)
        }
//        .background(.backgroundDefault)
//        .frame(width: ImageConstants.homeCardImageWidth, height: cardHeight)
//        .background(.backgroundWhite)
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//        .shadow(color: .lineDefault, radius: 2, x: 1, y: 1)
    }
}

#Preview {
    ZStack {
        Color.backgroundDefault.ignoresSafeArea()
        VStack(spacing: 32){
            // 第一步验证：显示loading状态的卡片，应该能看到完整的紫色进度边框
            HomeCardView(formula: Formula.mock) // Formula.mock 默认是 loading 状态
                .environmentObject(HomeViewModel())
            
            // 对比：其他状态的卡片
//            HomeCardView(formula: Formula.mock)
//                .environmentObject(HomeViewModel())
        }
        .padding()
    }
}
