//
//  CardContainerView.swift
//  yummy
//
//  Created by steve on 2025/8/14.
//

import SwiftUI

struct CardContainerView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(8)
        .background(Color.backgroundWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .lineDefault.opacity(0.5), radius: 2, x: 1, y: 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        CardContainerView {
            VStack(alignment: .leading, spacing: 8) {
                Text("卡片标题")
                    .appStyle(.title)
                Text("卡片内容示例")
                    .appStyle(.body)
            }
        }
        
        CardContainerView {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading) {
                    Text("示例菜谱")
                        .appStyle(.cardTitle)
                    Text("示例描述")
                        .appStyle(.body)
                        .foregroundColor(.textLightGray)
                }
                Spacer()
            }
        }
    }
    .padding()
    .background(Color.backgroundDefault)
}
