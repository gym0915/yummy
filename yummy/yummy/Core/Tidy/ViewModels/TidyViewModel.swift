//
//  TideViewModel.swift
//  yummy
//
//  Created by steve on 2025/6/22.
//

import Foundation
//import Combine
import LucideIcons
import SwiftUI
import Security
import Combine


@MainActor
class TidyViewModel : ObservableObject {
//    @EnvironmentObject var homeViewModel: HomeViewModel
    
    @Published var navigationTitle: AnyView = AnyView(Text("整理").appStyle(.navigationTitle))
    @Published var leadingNavigationButton: NavigationBarButtonConfiguration?
    @Published var trailingNavigationButtonLeft: NavigationBarButtonConfiguration?
    @Published var trailingNavigationButtonRight: NavigationBarButtonConfiguration?
    @Published var isTrailingButtonRightEnabled: Bool = false {
        didSet {
            setupNavigationButtons()
        }
    }
    @Published var inputtedText: String = ""

    /// 关闭视图的回调
    private var dismissAction: (() -> Void)?

    /// 初始化
    init() {
        setupNavigationButtons()
    }
    
    /// 设置关闭视图的回调函数
    func setDismissAction(_ action: @escaping () -> Void) {
        self.dismissAction = action
    }

    private func setupNavigationButtons() {
        
        let checkButton = NavigationBarButtonConfiguration(
            iconName: Lucide.check,
            text: nil,
            action: { [weak self] in
                guard let self = self else { return }
                let prompt = self.inputtedText
                // 调用服务生成菜谱（任务脱离视图生命周期），需 await 调用 actor 方法
                Task {
                    await FormulaGenerationService.shared.generateAndSave(prompt: prompt)
                }

                // 立即关闭视图
                self.dismissAction?()
            },
            isEnabled: isTrailingButtonRightEnabled
        )
        trailingNavigationButtonRight = checkButton
    }
}
