//
//  UINavigationController.swift
//  yummy
//
//  Created by steve on 2025/6/19.
//

import UIKit

// MARK: - UINavigationController 右滑返回扩展
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
} 