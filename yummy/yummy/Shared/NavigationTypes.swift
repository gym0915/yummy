//
//  NavigationTypes.swift
//  yummy
//
//  Created by steve on 2025/1/27.
//

import Foundation

// 定义页面类型枚举
enum NavigationPage: Hashable {
    case detail(Formula)
    case cuisine(focusId: String?)
    case camera(Formula) // 新增相机页面
    case photoLibrary(Formula) // 新增相册页面
}