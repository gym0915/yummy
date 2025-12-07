//
//  View.swift
//  yummy
//
//  Created by steve on 2025/1/21.
//

import SwiftUI
import UIKit

// MARK: - View 右滑返回扩展
extension View {
    /// 启用右滑返回手势（用于隐藏了原生导航栏的视图）
    func interactivePopGestureEnabled() -> some View {
        self.onAppear {
            // 确保右滑返回手势被启用
            Task { @MainActor in
                await Task.yield()
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    
                    func findNavigationController(from viewController: UIViewController) -> UINavigationController? {
                        if let navController = viewController as? UINavigationController {
                            return navController
                        }
                        
                        for child in viewController.children {
                            if let found = findNavigationController(from: child) {
                                return found
                            }
                        }
                        
                        if let presented = viewController.presentedViewController {
                            return findNavigationController(from: presented)
                        }
                        
                        return nil
                    }
                    
                    if let navigationController = findNavigationController(from: rootViewController) {
                        navigationController.interactivePopGestureRecognizer?.isEnabled = true
                        navigationController.interactivePopGestureRecognizer?.delegate = navigationController
                    }
                }
            }
        }
    }
    
    func progressiveBlur(
            radius: CGFloat,
            maxSampleCount: Int = 25,
            verticalPassFirst: Bool = false,
            mask: Image
        ) -> some View {
            self.visualEffect { content, _ in
                content.progressiveBlur(
                    radius: radius,
                    maxSampleCount: maxSampleCount,
                    verticalPassFirst: verticalPassFirst,
                    mask: mask
                )
            }
        }
        
        func progressiveBlur(
            radius: CGFloat,
            maxSampleCount: Int = 25,
            verticalPassFirst: Bool = false,
            maskRenderer: @escaping @Sendable (GeometryProxy, inout GraphicsContext) -> Void
        ) -> some View {
            self.visualEffect { content, geometryProxy in
                content.progressiveBlur(
                    radius: radius,
                    maxSampleCount: maxSampleCount,
                    verticalPassFirst: verticalPassFirst,
                    mask: Image(size: geometryProxy.size, renderer: { context in
                        maskRenderer(geometryProxy, &context)
                    })
                )
            }
        }
}


extension VisualEffect {
    func progressiveBlur(
        radius: CGFloat,
        maxSampleCount: Int = 25,
        verticalPassFirst: Bool = false,
        mask: Image,
        isEnabled: Bool = true
    ) -> some VisualEffect {
        self.layerEffect(
            ShaderLibrary.progressiveBlur(
                .boundingRect,
                .float(radius),
                .float(CGFloat(maxSampleCount)),
                .image(mask),
                .float(verticalPassFirst ? 1 : 0)
            ),
            maxSampleOffset: CGSize(width: radius , height: radius),
            isEnabled: isEnabled
        )
        .layerEffect(
            ShaderLibrary.progressiveBlur(
                .boundingRect,
                .float(radius),
                .float(CGFloat(maxSampleCount)),
                .image(mask),
                .float(verticalPassFirst ? 0 : 1)
            ),
            maxSampleOffset: CGSize(width: radius, height: radius),
            isEnabled: isEnabled
        )
    }
}
