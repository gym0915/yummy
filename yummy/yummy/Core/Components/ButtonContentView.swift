//
//  ButtonContentView.swift
//  yummy
//
//  Created by steve on 2025/6/20.
//

import SwiftUI
import LucideIcons

struct ButtonContentView: View {
    let buttonConfig: NavigationBarButtonConfiguration
    
    
    var body: AnyView {
        if let iconName = buttonConfig.iconName {
            return AnyView(
                Button(action: {
                    if let action = buttonConfig.action, buttonConfig.isEnabled {
                        action()
                    }
                }) {
                    Image(uiImage: iconName.withRenderingMode(.alwaysTemplate))
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(buttonConfig.isEnabled ? .iconDefault : .iconDisable)
                        .contentShape(.circle)
                }
                    .frame(width: 44, height: 44)
                    .disabled(!buttonConfig.isEnabled || buttonConfig.action == nil)
//                    .buttonStyle(.glass)
//                    .foregroundColor(.clear)
//                    .background(.clear)
                    .background(
                        Circle()
                            .fill(.clear)
                            .glassEffect(.regular.interactive(), in: .circle)
                    )
                    .clipShape(Circle())
                    .font(.headline)
//                    .glassEffect(.clear.interactive(), in: .circle)
                    .overlay(alignment: .topTrailing) {
                        // 徽标显示
                        if let badgeCount = buttonConfig.badgeCount, badgeCount > 0 {
                            Text("\(badgeCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.textWhite)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Color.red)
                                .clipShape(Circle())
//                                .offset(x: 0, y: 0)
                        }
                    }
            )
        }
        else {
            return AnyView(EmptyView())
        }
    }
}

#Preview {
    HStack(spacing: 50) {
        // 普通按钮
        ButtonContentView(
            buttonConfig: NavigationBarButtonConfiguration(
                iconName: Lucide.messageCircle,
                text: nil,
                action: { AppLog("Home tapped", level: .debug, category: .ui) }
            )
        )
        
        // 带徽标的按钮
        ButtonContentView(
            buttonConfig: NavigationBarButtonConfiguration(
                iconName: Lucide.messageCircle,
                text: nil,
                action: { AppLog("Bell tapped", level: .debug, category: .ui) },
                badgeCount: 5
            )
        )
        
        // 禁用状态的按钮
        ButtonContentView(
            buttonConfig: NavigationBarButtonConfiguration(
                iconName: Lucide.messageCircle,
                text: nil,
                action: { AppLog("Settings tapped", level: .debug, category: .ui) },
                isEnabled: false
            )
        )
        
        // 带徽标的禁用按钮
        ButtonContentView(
            buttonConfig: NavigationBarButtonConfiguration(
                iconName: Lucide.messageCircle,
                text: nil,
                action: { AppLog("Message tapped", level: .debug, category: .ui) },
                isEnabled: false,
                badgeCount: 12,
            )
        )
    }
    .padding()
    .background(Color.gray)
}
