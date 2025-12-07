import SwiftUI
import UIKit

// 用于将 UIKit 导航栏高度暴露给 SwiftUI 的视图
struct NavigationBarHeightReader: UIViewControllerRepresentable {
    @Binding var navigationBarHeight: CGFloat

    func makeUIViewController(context: Context) -> UIViewController {
        // 创建一个透明的 UIViewController
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 在视图加载后，尝试获取导航栏的高度
        if let navigationController = uiViewController.navigationController {
            Task { @MainActor in
                await Task.yield()
                let height = navigationController.navigationBar.frame.height
                AppLog("导航栏高度: \(height)", level: .debug, category: .ui)
                if self.navigationBarHeight != height {
                    self.navigationBarHeight = height
                }
            }
        }
    }
}
