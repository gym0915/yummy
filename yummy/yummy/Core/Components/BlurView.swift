//
//  BlurView.swift
//  yummy
//
//  Created by steve on 2025/6/19.
//

import SwiftUI
import UIKit

/// 自定义模糊视图组件，提供无滤镜的毛玻璃效果
struct BlurView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> CustomBlurView {
        let view = CustomBlurView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: CustomBlurView, context: Context) {
        // 无需更新操作
    }
}

/// 自定义毛玻璃视图实现类
class CustomBlurView: UIVisualEffectView {
    
    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        
        removeFilters()
        
        // 注册主题变化监听
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            DispatchQueue.main.async {
                self.removeFilters()
            }
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 移除所有滤镜效果，实现纯净的毛玻璃效果
    private func removeFilters() {
        if let filterLayer = layer.sublayers?.first {
            filterLayer.filters = []
        }
    }
}

/// 模糊视图协调器（备用实现，当前未使用）
class BlurViewCoordinator: NSObject {
    weak var uiView: UIVisualEffectView?
    let style: UIBlurEffect.Style
    let removeAllFilter: Bool
    
    init(style: UIBlurEffect.Style, removeAllFilter: Bool) {
        self.style = style
        self.removeAllFilter = removeAllFilter
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshEffect),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc func refreshEffect() {
        guard let uiView = uiView else { return }
        uiView.effect = UIBlurEffect(style: style)
        
        // 需要延迟一点点，确保 layer 结构已重建
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            if let backdropLayer = uiView.layer.sublayers?.first {
                if self.removeAllFilter {
                    backdropLayer.filters = []
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        
        BlurView()
            .frame(width: 200, height: 100)
            .cornerRadius(12)
    }
}