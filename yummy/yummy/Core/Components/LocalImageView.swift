import SwiftUI
import UIKit

// MARK: - 本地图片显示组件
struct LocalImageView: View {
    let imagePath: String
    let placeholder: String?
    let onImageLoaded: ((UIImage) -> Void)?
    let enableZoomEffect: Bool // 新增：是否启用缩放效果
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    private let imageLoader = ImageLoader.shared
    
    init(imagePath: String, 
         placeholder: String? = nil, 
         onImageLoaded: ((UIImage) -> Void)? = nil,
         enableZoomEffect: Bool = false) {
        self.imagePath = imagePath
        self.placeholder = placeholder
        self.onImageLoaded = onImageLoaded
        self.enableZoomEffect = enableZoomEffect
    }
    
    var body: some View {
        if enableZoomEffect {
            // 启用缩放效果的版本
            ZoomableImageView(
                image: image,
                isLoading: isLoading,
                placeholder: placeholder
            )
            .onAppear {
                loadImage()
            }
            .onChange(of: imagePath) { _, _ in
                loadImage()
            }
        } else {
            // 原有的普通版本
            normalImageView
                .onAppear {
                    loadImage()
                }
                .onChange(of: imagePath) { _, _ in
                    loadImage()
                }
        }
    }
    
    // 原有的普通图片视图
    private var normalImageView: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
                    .background(Color.backgroundDefault)
            } else {
                placeholderView
            }
        }
    }
    
    // 占位符视图
    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundColor(.iconDisable)
            
            if let placeholder = placeholder {
                Text(placeholder)
                    .appStyle(.body)
                    .foregroundColor(.textLightGray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundDefault)
    }
    
    private func loadImage() {
        AppLog("🖼️ [LocalImageView] 开始加载图片: \(imagePath)", level: .debug, category: .image)
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            AppLog("🖼️ [LocalImageView] 在后台任务调用ImageLoader", level: .debug, category: .image)
            let loadedImage = imageLoader.loadImage(from: imagePath)
//            AppLog("🖼️ [LocalImageView] ImageLoader返回结果: \(loadedImage != nil ? \"成功\" : \"失败\")", level: .debug, category: .image)
            
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
//                AppLog("🖼️ [LocalImageView] 更新UI状态，图片: \(loadedImage != nil ? \"有\" : \"无\")", level: .debug, category: .ui)
                
                // 图片加载完成后回调
                if let loadedImage = loadedImage {
                    AppLog("🖼️ [LocalImageView] 调用onImageLoaded回调", level: .info, category: .ui)
                    self.onImageLoaded?(loadedImage)
                } else {
                    AppLog("🖼️ [LocalImageView] 图片加载失败，不调用回调", level: .warning, category: .image)
                }
            }
        }
    }
}

// MARK: - 拉伸头部图片的 ViewModifier
private struct StretchyImageModifier: ViewModifier {
    let startingHeight: CGFloat
    let coordinateSpace: CoordinateSpace = .named("scroll")
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .frame(width: geometry.size.width, height: stretchedHeight(geometry))
                .clipped()
                .offset(y: stretchedOffset(geometry))
        }
        .frame(height: startingHeight)
    }
    
    // 获取Y偏移量
    private func yOffset(_ geo: GeometryProxy) -> CGFloat {
        geo.frame(in: coordinateSpace).minY
    }
    
    // 计算拉伸后的高度
    private func stretchedHeight(_ geo: GeometryProxy) -> CGFloat {
        let offset = yOffset(geo)
        return offset > 0 ? (startingHeight + offset) : startingHeight
    }
    
    // 计算拉伸偏移量
    private func stretchedOffset(_ geo: GeometryProxy) -> CGFloat {
        let offset = yOffset(geo)
        return offset > 0 ? -offset : 0
    }
}

// MARK: - 支持缩放效果的图片视图
private struct ZoomableImageView: View {
    let image: UIImage?
    let isLoading: Bool
    let placeholder: String?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .modifier(StretchyImageModifier(startingHeight: ImageConstants.detailFinishImageHeight))
            } else if isLoading {
                ProgressView()
                    .frame(width: 50, height: 50)
                    .background(Color.backgroundDefault)
                    .frame(height: ImageConstants.detailFinishImageHeight)
            } else {
                // 加载失败的占位符
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.iconDisable)
                    
                    if let placeholder = placeholder {
                        Text(placeholder)
                            .appStyle(.body)
                            .foregroundColor(.textLightGray)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: ImageConstants.detailFinishImageHeight)
                .background(Color.backgroundDefault)
            }
        }
    }
}
