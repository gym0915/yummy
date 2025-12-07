//
//  CustomNavigationBar.swift
//  yummy
//
//  Created by steve on 2025/6/20.
//

import SwiftUI
import LucideIcons

struct CustomNavigationBar: View {
    let title: AnyView
    let titleIcon: Image?
    let leadingButton: NavigationBarButtonConfiguration?
    let trailingButtonLeft: NavigationBarButtonConfiguration?
    let trailingButtonRight: NavigationBarButtonConfiguration?
    let isTransparent: Bool // 新增透明背景参数
    
    @State private var dynamicNavBarHeight: CGFloat = 44.0 // 默认值，实际会在运行时更新
    
    // 新增初始化方法，保持向后兼容
    init(title: AnyView,
         titleIcon: Image? = nil,
         leadingButton: NavigationBarButtonConfiguration? = nil,
         trailingButtonLeft: NavigationBarButtonConfiguration? = nil,
         trailingButtonRight: NavigationBarButtonConfiguration? = nil,
         isTransparent: Bool = false) {
        self.title = title
        self.titleIcon = titleIcon
        self.leadingButton = leadingButton
        self.trailingButtonLeft = trailingButtonLeft
        self.trailingButtonRight = trailingButtonRight
        self.isTransparent = isTransparent
    }
    
    var body: some View {
        ZStack {
            HStack(alignment:.center,spacing: 0) {
                HStack(spacing: 6) {
                    if let buttonConfig = leadingButton {
                        ButtonContentView(buttonConfig: buttonConfig)
                            .offset(x: -1)
                            .background(
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 36, height: 36)
                            )
                    }
                    
                    if let icon = titleIcon {
                        icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                    
                    title
                }
                .frame(maxWidth: .infinity,alignment: .leading)
        
                HStack(spacing: 12) {
                    if let buttonConfig = trailingButtonRight {
                        ButtonContentView(buttonConfig: buttonConfig)
                            .offset(x: -1)
                            .background(
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 36, height: 36)
                            )
                    }
                    if let buttonConfig = trailingButtonLeft {
                        ButtonContentView(buttonConfig: buttonConfig)
                            .offset(x: -1)
                            .background(
                                Circle()
                                    .fill(.clear)
                                    .frame(width: 36, height: 36)
                            )
                    }
                }
            }
            .frame(height: dynamicNavBarHeight) // 使用动态获取的导航栏高度
            .padding(.horizontal,16)
            .background(
                NavigationBarHeightReader(navigationBarHeight: $dynamicNavBarHeight)
            )
        }
        .frame(maxWidth: .infinity)
        // 使用闭包形式的背景以避免三元运算中 ShapeStyle 类型不匹配
        .background {
            if isTransparent {
                Color.clear
            } else {
                BlurView()
                    .blur(radius: 2)
                    .padding(.horizontal, -45)
                    .padding(.bottom, -25)
                    .frame(height: 90)
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
}

#Preview {
    ZStack {
        // 添加背景以展示模糊效果
//        LinearGradient(
//            gradient: Gradient(colors: [.blue, .purple, .pink]),
//            startPoint: .topLeading,
//            endPoint: .bottomTrailing
//        )
//        .ignoresSafeArea()
        
        VStack(spacing: 32) {
            
            CustomNavigationBar(
                title: AnyView(Text("Yummy").appStyle(.navigationTitle)),
                titleIcon: Image("icon-logo2"),
                leadingButton: NavigationBarButtonConfiguration(
                    iconName: Lucide.trash2,
                    text: nil,
                    action: { AppLog("左侧按钮点击", level: .debug, category: .ui) },
                    isEnabled: true
                ),
                trailingButtonLeft: NavigationBarButtonConfiguration(
                    
                    iconName: Lucide.chevronLeft,
                    text: nil,
                    action: { AppLog("右侧按钮1点击", level: .debug, category: .ui) },
                    isEnabled: true
                ),
                trailingButtonRight: nil,
                isTransparent: false
            )
            .toolbarVisibility(.hidden, for: .navigationBar)
            
            CustomNavigationBar(
                title: AnyView(Text("Yummy").appStyle(.navigationTitle)),
                leadingButton: nil,
                trailingButtonLeft: NavigationBarButtonConfiguration(
                    iconName: Lucide.trash2,
                    text: nil,
                    action: { AppLog("右侧按钮1点击", level: .debug, category: .ui) },
                    isEnabled: false
                ),
                trailingButtonRight: NavigationBarButtonConfiguration(
                    iconName: Lucide.ellipsisVertical,
                    text: nil,
                    action: { AppLog("右侧按钮2点击", level: .debug, category: .ui) },
                    isEnabled: true
                )
            )
            .toolbarVisibility(.hidden, for: .navigationBar)
            
            CustomNavigationBar(
                title: AnyView(Text("首页标题").appStyle(.navigationTitle)),
                leadingButton: NavigationBarButtonConfiguration(
                    iconName: Lucide.chevronLeft,
                    text: nil,
                    action: { AppLog("左侧按钮点击", level: .debug, category: .ui) },
                    isEnabled: true
                ),
                trailingButtonLeft: nil,
                trailingButtonRight: nil
            )
            .toolbarVisibility(.hidden, for: .navigationBar)
            
            CustomNavigationBar(
                title: AnyView(Text("首页标题").appStyle(.navigationTitle)),
                leadingButton: nil,
                trailingButtonLeft: nil,
                trailingButtonRight: nil
            )
            .toolbarVisibility(.hidden, for: .navigationBar)
            
            CustomNavigationBar(
                title: AnyView(Text("").appStyle(.navigationTitle)),
                leadingButton: NavigationBarButtonConfiguration(
                    iconName: Lucide.chevronLeft,
                    text: nil,
                    action: nil,
                    isEnabled: true
                ),
                trailingButtonLeft: nil,
                trailingButtonRight: nil,
                isTransparent: true
            )
            .toolbarVisibility(.hidden, for: .navigationBar)
            
            Spacer() // 添加 Spacer 将内容推到顶部，以便更好地观察导航栏
        }
    }
}

