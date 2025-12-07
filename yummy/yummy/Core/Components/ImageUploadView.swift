//
//  ImageUploadView.swift
//  yummy
//
//  Created by steve on 2025/1/20.
//

import SwiftUI
import LucideIcons

struct ImageUploadView: View {
    let onTap: () -> Void
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.backgroundDefault)
            .frame(maxWidth: .infinity)
            .frame(height: ImageConstants.uploadViewHeight) // 3:4 比例
            .overlay(
                VStack(spacing: 16) {
                    // 相机图标
//                    Image(uiImage: Lucide.camera)
//                        .renderingMode(.template)
//                        .foregroundColor(.iconDefault)
//                        .frame(width: 24, height: 24)
                    
                    Image("icon-photo")
                        .resizable()
                        .frame(width: 96, height: 96)
                    
                    // 提示文字
                    Text("点击这里，添加美食照片")
                        .appStyle(.body)
                        .foregroundColor(.textPrimary)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.lineDefault,
                        style: StrokeStyle(
                            lineWidth: 1,
                            dash: [5, 5]
                        )
                    )
            )
            .onTapGesture {
                onTap()
            }
    }
}

#Preview {
    ImageUploadView(onTap: {
        AppLog("Upload tapped", level: .debug, category: .ui)
    })
    .padding()
}
