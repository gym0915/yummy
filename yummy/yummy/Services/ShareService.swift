import SwiftUI
import UIKit
import Photos
import LucideIcons

// MARK: - 分享服务协议
protocol ShareServiceProtocol {
    /// 生成配方分享图片
    @MainActor
    func generateShareImage(from formula: Formula, image: UIImage?) async -> UIImage?
    /// 保存图片到相册
    func saveImageToPhotoLibrary(_ image: UIImage) async throws
    /// 检查相册权限
    func requestPhotoLibraryPermission() async -> Bool
}

// MARK: - 分享服务实现
final class ShareService: ShareServiceProtocol {
    
    static let shared = ShareService()
    
    private init() {}
    
    // MARK: - 图片生成
    @MainActor
    func generateShareImage(from formula: Formula, image: UIImage?) async -> UIImage? {
        AppLog("🖼️ [ShareService] 开始生成分享图片", category: .share)
        AppLog("📋 [ShareService] Formula信息: name=\(formula.name), imgpath=\(formula.imgpath ?? "nil"), state=\(formula.state)", level: .debug, category: .share)
        
        // 如果有图片路径，先预加载图片
        var finalImage = image
        AppLog("🖼️ [ShareService] 初始传入的图片: \(finalImage != nil ? "有图片" : "无图片")", level: .debug, category: .share)
        
        if finalImage == nil, let imagePath = formula.imgpath, !imagePath.isEmpty {
            AppLog("🖼️ [ShareService] 尝试从路径加载图片: \(imagePath)", level: .debug, category: .share)
            finalImage = await loadImageSynchronously(from: imagePath)
            AppLog("🖼️ [ShareService] 从路径加载图片结果: \(finalImage != nil ? "成功" : "失败")", level: .debug, category: .share)
        } else if finalImage == nil {
            AppLog("🖼️ [ShareService] 没有图片路径，将使用占位图", level: .debug, category: .share)
        }
        
        // 压缩/缩放逻辑已前置到 CameraService.saveImageToDocuments，此处仅记录当前像素信息
        if let img = finalImage {
            let pixelWidth = img.size.width * img.scale
            let pixelHeight = img.size.height * img.scale
            AppLog("ℹ️ [ShareService] 当前图片像素: \(Int(pixelWidth))x\(Int(pixelHeight)) (scale=\(img.scale))", level: .debug, category: .share)
        }
        
        AppLog("🖼️ [ShareService] 最终使用的图片: \(finalImage != nil ? "有图片" : "无图片")", level: .debug, category: .share)
        
        // 创建分享内容视图
        AppLog("🎨 [ShareService] 开始创建分享内容视图", level: .info, category: .share)
        let shareContentView = ShareContentView(formula: formula, formulaImage: finalImage)
        
        // 创建图片渲染器
        AppLog("🎨 [ShareService] 创建ImageRenderer", level: .debug, category: .share)
        let renderer = ImageRenderer(content: shareContentView)
        
        // 设置图片大小和质量（避免过高scale导致内存暴涨）
        let scale = UIScreen.main.scale
        renderer.scale = scale
        AppLog("🎨 [ShareService] 设置渲染器scale: \(scale)", level: .debug, category: .share)
        
        // 渲染图片
        AppLog("🎨 [ShareService] 开始渲染图片...", level: .info, category: .share)
        let renderedImage = renderer.uiImage
        
        if let renderedImage = renderedImage {
            AppLog("✅ [ShareService] 图片渲染成功，尺寸: \(renderedImage.size), scale: \(renderedImage.scale)", level: .info, category: .share)
        } else {
            AppLog("❌ [ShareService] 图片渲染失败", level: .error, category: .share)
        }
        
        return renderedImage
    }
    
    // MARK: - 同步加载图片
    private func loadImageSynchronously(from imagePath: String) async -> UIImage? {
        AppLog("📂 [ShareService] 开始同步加载图片: \(imagePath)", level: .debug, category: .share)
        
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                AppLog("📂 [ShareService] 在后台任务开始加载图片", level: .debug, category: .share)
                let imageLoader = ImageLoader.shared
                let loadedImage = imageLoader.loadImage(from: imagePath)
                
                AppLog("📂 [ShareService] ImageLoader加载结果: \(loadedImage != nil ? "成功" : "失败")", level: .debug, category: .share)
                if let loadedImage = loadedImage {
                    AppLog("📂 [ShareService] 加载的图片尺寸: \(loadedImage.size), scale: \(loadedImage.scale)", level: .debug, category: .share)
                }
                
                continuation.resume(returning: loadedImage)
            }
        }
    }
    
    // MARK: - 预加载图片
    private func preloadImage(from imagePath: String) async {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let imageLoader = ImageLoader.shared
                _ = imageLoader.loadImage(from: imagePath)
                continuation.resume()
            }
        }
    }
    
    // MARK: - 相册权限和保存
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return newStatus == .authorized || newStatus == .limited
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    func saveImageToPhotoLibrary(_ image: UIImage) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? ShareError.saveToPhotoLibraryFailed)
                }
            }
        }
    }
}

// MARK: - 分享错误类型
enum ShareError: LocalizedError {
    case imageGenerationFailed
    case saveToPhotoLibraryFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed:
            return "图片生成失败"
        case .saveToPhotoLibraryFailed:
            return "保存到相册失败"
        case .permissionDenied:
            return "没有相册访问权限"
        }
    }
}

// MARK: - 分享内容视图
private struct ShareContentView: View {
    let formula: Formula
    let formulaImage: UIImage?
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // 图片区域 - 不受水平padding控制
            if let formulaImage = formulaImage {
                Image(uiImage: formulaImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill) // 根据设计图使用 FILL 模式，图片撑满容器
                    .frame(height: 444) // 根据设计图设置固定尺寸
                    .frame(width: ImageConstants.screenWidth) // 使用完整屏幕宽度
                    .clipped()
            } else {
                // 无图片时的占位区域
                Rectangle()
                    .fill(Color(.iconDisable))
                    .frame(height: 300)
                    .frame(width: ImageConstants.screenWidth) // 使用完整屏幕宽度
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("暂无图片")
                                .appStyle(.body)
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // 标题 + 标签（合并为一个白底卡片）
                sectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formula.name)
                            .appStyle(.navigationTitle)
                            .lineLimit(1)
                            .padding(.vertical,8)
                        
                        if !formula.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(formula.tags, id: \.self) { tag in
                                    TagView(text: tag)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .frame(maxWidth: .infinity,alignment: .leading)
                }
                
                // 主料
                ingredientSection(
                    title: "主料",
                    iconString: "icon-mainfood",
                    items: formula.ingredients.mainIngredients
                )
                
                // 香料调味料
                if !formula.ingredients.spicesSeasonings.isEmpty {
                    ingredientSection(
                        title: "配料",
                        iconString: "icon-spices",
                        items: formula.ingredients.spicesSeasonings
                    )
                }
                
                // 调味汁
                if !formula.ingredients.sauce.isEmpty {
                    sauceSection(
                        title: "蘸料",
                        iconString: "icon-sauce",
                        items: formula.ingredients.sauce
                    )
                }
                
                // 厨具
                if !formula.tools.isEmpty {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(iconString: "icon-tools", title: "厨具")
                            
                            // 简单横排展示
                            HStack(spacing: 16) {
                                ForEach(formula.tools, id: \.name) { tool in
                                    Text(tool.name)
                                        .appStyle(.body)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .frame(maxWidth: .infinity,alignment: .leading)
                    }
                }
                
                // 准备工作（紫色圆形序号，仅展示 details）
                if !formula.preparation.isEmpty {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(iconString: "icon-prepare", title: "备菜")
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(formula.preparation.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: 10) {
                                        CircularBadgeView(backgroundColor: .brandSecondary) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundColor(.textPrimary)
                                        }
                                        Text(step.details)
                                            .appStyle(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                    }
                }
                
                sectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(iconString: "icon-cook", title: "料理")
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(formula.steps.enumerated()), id: \.offset) { index, step in
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(spacing: 8) {
                                        Text("\(index + 1).")
                                            .appStyle(.cardTitle)
                                            .foregroundColor(.iconSecondary)
                                        Text(step.step)
                                            .font(.headline)
                                            .appStyle(.cardTitle)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.leading, 8)
                                    .padding(.vertical, 16)
                                    .background(Color.brandSecondary)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(step.details)
                                            .appStyle(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(16)
                                    .padding(.vertical,8)
                                    .padding(.leading,13)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray6), lineWidth: 0)
                                )
                            }
                        }
                    }
                }
                
                if !formula.tips.isEmpty {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(iconString: "icon-tips",title: "小窍门")
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(formula.tips.enumerated()), id: \.offset) { index, tip in
                                    HStack(alignment: .top, spacing: 8) {
                                        CircularBadgeView(backgroundColor: .brandSecondary) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 12, weight: .light))
                                                .foregroundColor(.textPrimary)
                                        }
                                        Text(tip)
                                            .appStyle(.body)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
            }
            // 底部 logo + 应用名
            HStack(spacing: 4) {
                Image("logo")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("食记")
                    .appStyle(.cardTitle)
                    .foregroundColor(.textLightGray)
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal,8)
        .background(.backgroundDefault)
        // .clipShape(RoundedRectangle(cornerRadius: 8)) // 页面四周圆角
        .frame(width: ImageConstants.screenWidth) // 使用完整设备宽度
    }
    
    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(8)
        .background(Color.backgroundWhite)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray6), lineWidth: 0)
        )
    }
    
    @ViewBuilder
    private func sectionHeader(iconString: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(iconString)
                .resizable()
//                .renderingMode(.template)
//                .foregroundColor(.iconDefault)
                .frame(width: 24, height: 24)
            Text(title)
                .appStyle(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func ingredientSection(title: String, iconString: String, items: [Ingredient]) -> some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(iconString: iconString, title: title)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items, id: \.name) { item in
                        HStack(spacing: 0) {
                            Text(item.quantity)
                                .appStyle(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(item.name)
                                .appStyle(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func sauceSection(title: String, iconString: String, items: [SauceIngredient]) -> some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(iconString: iconString, title: title)
                
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items, id: \.name) { item in
                        HStack(spacing: 0) {
                            Text(item.quantity)
                                .appStyle(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(item.name)
                                .appStyle(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        ScrollView(.vertical){
            ShareContentView(formula: Formula.mock, formulaImage: nil)
                .padding()
        }
        .scrollIndicators(.hidden)
    }
}

