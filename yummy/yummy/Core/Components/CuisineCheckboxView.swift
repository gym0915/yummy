//
//  CuisineCheckboxView.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import SwiftUI
import LucideIcons

struct CuisineCheckboxView: View {
    let isCompleted: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(
                uiImage: isCompleted ? Lucide.circleCheckBig
                    .withRenderingMode(
                        .alwaysTemplate
                    ) : Lucide.circle
                    .withRenderingMode(
                        .alwaysTemplate
                    )
            )
                .resizable()
                .frame(
                    width: 24,
                    height: 24
                )
                .foregroundColor(
                    isCompleted ? .iconDisable : .accent
                )
                .font(
                    .title2
                )
        }
//        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            CuisineCheckboxView(isCompleted: false, action: {})
            Text("未勾选状态")
        }
        
        HStack {
            CuisineCheckboxView(isCompleted: true, action: {})
            Text("已勾选状态")
        }
    }
    .padding()
} 
