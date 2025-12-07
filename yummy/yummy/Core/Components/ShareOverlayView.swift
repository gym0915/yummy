import SwiftUI
import LucideIcons

struct ShareOverlayView: View {
    let formula: Formula
    let formulaImage: UIImage?
    @Binding var isPresented: Bool
    @State private var shareImage: UIImage?
    @State private var isGeneratingImage: Bool = false
    @State private var showSaveSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var showPermissionAlert: Bool = false
    @State private var dragOffset: CGSize = .zero
    @State private var imageScale: CGFloat = 1.0
    @State private var showImageAnimation: Bool = false // 添加图片显示动画状态
    @State private var showBottomSheetAnimation: Bool = false // 添加底部sheet动画状态
    @State private var showShareSheet: Bool = false // 添加系统分享sheet状态
    
    private let shareService: ShareServiceProtocol
    private let imageMaxWidth: CGFloat
    
    init(formula: Formula, 
         formulaImage: UIImage?,
         isPresented: Binding<Bool>,
         imageMaxWidth: CGFloat = UIScreen.main.bounds.width - 32, // 默认留出16像素两边留白
         shareService: ShareServiceProtocol = ShareService.shared) {
        AppLog("🖼️ [ShareOverlayView] 初始化ShareOverlayView", level: .debug, category: .ui)
        AppLog("📋 [ShareOverlayView] Formula: name=\(formula.name), imgpath=\(formula.imgpath ?? "nil")", level: .debug, category: .ui)
        AppLog("🖼️ [ShareOverlayView] formulaImage: \(formulaImage != nil ? "有图片" : "无图片")", level: .debug, category: .ui)
        if let formulaImage = formulaImage {
            AppLog("🖼️ [ShareOverlayView] formulaImage尺寸: \(formulaImage.size), scale: \(formulaImage.scale)", level: .debug, category: .ui)
        }
        
        self.formula = formula
        self.formulaImage = formulaImage
        self._isPresented = isPresented
        self.imageMaxWidth = imageMaxWidth
        self.shareService = shareService
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // 分享内容区域 - 占据整个屏幕高度
            if let shareImage = shareImage {
                ScrollView(.vertical, showsIndicators: false) {
                    Image(uiImage: shareImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: imageMaxWidth)
                        .id("shareImage") // 添加ID用于滚动定位
                        .onTapGesture {
                            dismissWithAnimation()
                        }
                        .padding(.vertical, 60)
                        .padding(.bottom,120)
                        .onAppear {
                            AppLog("🖼️ [ShareOverlayView] 图片视图onAppear - showImageAnimation: \(showImageAnimation)", level: .debug, category: .ui)
                        }
                }
                .frame(maxWidth: imageMaxWidth)
                .frame(maxHeight: .infinity)
                .ignoresSafeArea(.container, edges: .vertical)
                .padding(.top,44)
                .offset(y: showImageAnimation ? 0 : UIScreen.main.bounds.height) // 添加底部升起动画
                .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0), value: showImageAnimation)
                .onAppear {
                    AppLog("🖼️ [ShareOverlayView] ScrollView onAppear - showImageAnimation: \(showImageAnimation), offset: \(showImageAnimation ? 0 : UIScreen.main.bounds.height)", level: .debug, category: .ui)
                }
            } else {
                // 生成失败
//                VStack(spacing: 20) {
//                    Image(uiImage: Lucide.x)
//                        .renderingMode(.template)
//                        .foregroundColor(.white)
//                        .font(.largeTitle)
//                    
//                    Text("图片生成失败")
//                        .foregroundColor(.white)
//                        .appStyle(.title)
//                    
//                    Button("重新生成") {
//                        generateShareImage()
//                    }
//                    .foregroundColor(.accentColor)
//                }
//                .frame(maxWidth: imageMaxWidth)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            AppLog("🚀 [ShareOverlayView] onAppear - 开始初始化状态", level: .debug, category: .ui)
            AppLog("🎯 [ShareOverlayView] 重置动画状态 - showImageAnimation: \(showImageAnimation), showBottomSheetAnimation: \(showBottomSheetAnimation)", level: .debug, category: .ui)
            
            // 确保所有动画状态都重置为初始状态
            showImageAnimation = false
            showBottomSheetAnimation = false
            
            AppLog("🎯 [ShareOverlayView] 状态重置完成 - showImageAnimation: \(showImageAnimation), showBottomSheetAnimation: \(showBottomSheetAnimation)", level: .debug, category: .ui)
            
            generateShareImage()
            
            // 延迟一点时间后开始底部sheet动画，确保视图已经渲染完成
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                AppLog("🎬 [ShareOverlayView] 开始底部sheet动画", level: .debug, category: .ui)
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                    showBottomSheetAnimation = true
                }
                AppLog("🎬 [ShareOverlayView] 底部sheet动画状态: \(showBottomSheetAnimation)", level: .debug, category: .ui)
            }
        }
        .overlay(
            VStack {
                Spacer()
                bottomActionArea
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .offset(y: showBottomSheetAnimation ? 0 : 200) // 添加底部升起动画
            .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0), value: showBottomSheetAnimation)
        )
        .alert("保存成功", isPresented: $showSaveSuccess) {
            Button("确定") { }
        } message: {
            Text("图片已保存到相册")
        }
        .alert("权限提醒", isPresented: $showPermissionAlert) {
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要相册访问权限才能保存图片，请在设置中开启相册权限")
        }
        .alert("错误", isPresented: .constant(errorMessage != nil)) {
            Button("确定") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage = shareImage {
                ActivityView(activityItems: [shareImage])
            }
        }
    }
    
    // MARK: - 底部操作区域
    private var bottomActionArea: some View {
        BottomActionAreaView(items: [
            BottomActionItem(id: ShareBottomAction.share, icon: Lucide.share, title: "分享给朋友")
        ]) { action in
            switch action {
            case .share:
                shareImageWithSystem()
            }
        }
        .offset(y: dragOffset.height > 0 ? dragOffset.height : 0) // 只允许向下拖拽
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // 打印拖拽坐标数值
                    AppLog("🖐️ [ShareOverlay] 拖拽中 - Y坐标: \(value.translation.height)", level: .debug, category: .ui)
                    // 只允许向下拖拽
                    if value.translation.height > 0 {
                        dragOffset = value.translation
                        AppLog("🖐️ [ShareOverlay] 更新dragOffset: \(dragOffset)", level: .debug, category: .ui)
                    }
                }
                .onEnded { value in
                    let dismissThreshold: CGFloat = 55 // 拖拽阈值
                    AppLog("🖐️ [ShareOverlay] 拖拽结束 - Y坐标: \(value.translation.height), 阈值: \(dismissThreshold)", level: .debug, category: .ui)
                    if value.translation.height > dismissThreshold {
                        AppLog("🖐️ [ShareOverlay] 超过阈值，准备退出分享界面", level: .debug, category: .ui)
                        dismissWithAnimation()
                    } else {
                        AppLog("🖐️ [ShareOverlay] 未超过阈值，回弹到原位置", level: .debug, category: .ui)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
    
    // MARK: - 私有方法
    private func generateShareImage() {
        AppLog("🖼️ [ShareOverlayView] 开始生成分享图片", level: .debug, category: .ui)
        AppLog("📋 [ShareOverlayView] Formula信息: name=\(formula.name), imgpath=\(formula.imgpath ?? "nil")", level: .debug, category: .ui)
        AppLog("🖼️ [ShareOverlayView] 传入的formulaImage: \(formulaImage != nil ? "有图片" : "无图片")", level: .debug, category: .ui)
        
        Task { @MainActor in
            AppLog("🖼️ [ShareOverlayView] 设置生成状态为true", level: .debug, category: .ui)
            isGeneratingImage = true
            
            AppLog("🖼️ [ShareOverlayView] 调用ShareService生成图片", level: .debug, category: .ui)
            shareImage = await shareService.generateShareImage(from: formula, image: formulaImage)
            
            AppLog("🖼️ [ShareOverlayView] ShareService返回结果: \(shareImage != nil ? "成功" : "失败")", level: .debug, category: .ui)
            
            if let shareImage = shareImage {
                AppLog("🖼️ [ShareOverlayView] 生成的分享图片尺寸: \(shareImage.size), scale: \(shareImage.scale)", level: .debug, category: .ui)
            }
            
            AppLog("🖼️ [ShareOverlayView] 设置生成状态为false", level: .debug, category: .ui)
            isGeneratingImage = false
            
            if shareImage == nil {
                AppLog("❌ [ShareOverlayView] 图片生成失败，设置错误信息", level: .debug, category: .ui)
                errorMessage = "图片生成失败，请重试"
            } else {
                AppLog("✅ [ShareOverlayView] 图片生成成功", level: .debug, category: .ui)
                AppLog("🧭 [ShareOverlayView] 状态检查 - isGeneratingImage: \(isGeneratingImage), showImageAnimation: \(showImageAnimation), showBottomSheetAnimation: \(showBottomSheetAnimation)", level: .debug, category: .ui)
                
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    AppLog("🎬 [ShareOverlayView] 准备开始图片显示动画 - 当前showImageAnimation: \(showImageAnimation)", level: .debug, category: .ui)
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)) {
                        showImageAnimation = true
                    }
                    AppLog("🎬 [ShareOverlayView] 图片显示动画已触发 - showImageAnimation: \(showImageAnimation)", level: .debug, category: .ui)
                }
            }
        }
    }
    
    private func saveToPhotoLibrary() {
        guard let shareImage = shareImage else {
            errorMessage = "没有可保存的图片"
            return
        }
        
        Task {
            do {
                let hasPermission = await shareService.requestPhotoLibraryPermission()
                
                if hasPermission {
                    try await shareService.saveImageToPhotoLibrary(shareImage)
                    await MainActor.run {
                        showSaveSuccess = true
                    }
                } else {
                    await MainActor.run {
                        showPermissionAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func shareImageWithSystem() {
        guard let shareImage = shareImage else {
            errorMessage = "没有可分享的图片"
            return
        }
        
        showShareSheet = true
    }
    
    private func dismissWithAnimation() {
        AppLog("🚪 [ShareOverlay] 开始执行退出动画", level: .debug, category: .ui)
        AppLog("🧭 [ShareOverlay] 退出前状态 - showImageAnimation: \(showImageAnimation), showBottomSheetAnimation: \(showBottomSheetAnimation), isPresented: \(isPresented)", level: .debug, category: .ui)
        // 先隐藏底部操作区域
        withAnimation(.easeInOut(duration: 0.2)) {
            showBottomSheetAnimation = false
        }
        AppLog("🚪 [ShareOverlay] 设置 showBottomSheetAnimation = false", level: .debug, category: .ui)
        
        // 再隐藏分享图片
        withAnimation(.easeInOut(duration: 0.2)) {
            showImageAnimation = false
        }
        AppLog("🚪 [ShareOverlay] 设置 showImageAnimation = false", level: .debug, category: .ui)
        
        // 重置拖拽偏移量
        dragOffset = .zero
        AppLog("🚪 [ShareOverlay] 重置 dragOffset = .zero", level: .debug, category: .ui)
        
        // 动画结束后关闭视图
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            isPresented = false
            AppLog("🚪 [ShareOverlay] 设置 isPresented = false，关闭视图", level: .debug, category: .ui)
            AppLog("🧭 [ShareOverlay] 退出后状态 - showImageAnimation: \(showImageAnimation), showBottomSheetAnimation: \(showBottomSheetAnimation), isPresented: \(isPresented)", level: .debug, category: .ui)
        }
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    @Previewable @State var isPresented = true
    ShareOverlayView(formula: Formula.mock, formulaImage: nil, isPresented: $isPresented)
}

// MARK: - ActivityView
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

fileprivate enum ShareBottomAction: Hashable { case share }
