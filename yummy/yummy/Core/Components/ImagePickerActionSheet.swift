//
//  ImagePickerActionSheet.swift
//  yummy
//
//  Created by steve on 2025/1/27.
//

import SwiftUI
import LucideIcons

struct ImagePickerActionSheet: View {
    let onTakePhoto: () -> Void
    let onChooseFromLibrary: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
//            Text("选择图片")
//                .appStyle(.title)
//                .foregroundColor(.textPrimary)
//                .padding(.top, 20)
//                .padding(.bottom, 24)
            
            // 选项按钮
            VStack(spacing: 0) {
                // 拍照选项
                Button(action: onTakePhoto) {
                    HStack(spacing: 0) {
//                        Image(uiImage: Lucide.camera)
//                            .renderingMode(.template)
//                            .foregroundColor(.iconDefault)
//                            .frame(width: 24, height: 24)
                        
                        Text("拍照")
                            .appStyle(.body)
                        
//                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.backgroundDefault)
                
                // 分割线
                Divider()
                
                // 从相册选择选项
                Button(action: onChooseFromLibrary) {
                    HStack(spacing: 0) {
//                        Image(uiImage: Lucide.image)
//                            .renderingMode(.template)
//                            .foregroundColor(.iconDefault)
//                            .frame(width: 24, height: 24)
                        
                        Text("从相册选择")
                            .appStyle(.body)
                        
//                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color.backgroundDefault)
                
                // 分割线
//                Divider()
                
            }
            .background(Color.backgroundDefault)
            .cornerRadius(12)
            
            Spacer()
        }
        .background(Color.backgroundDefault)
    }
}

#Preview {
    ImagePickerActionSheet(
        onTakePhoto: { AppLog("拍照", level: .debug, category: .ui) },
        onChooseFromLibrary: { AppLog("从相册选择", level: .debug, category: .ui) }
    )
}
