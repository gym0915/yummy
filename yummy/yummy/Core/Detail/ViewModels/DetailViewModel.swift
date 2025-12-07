//
//  DetailViewModel.swift
//  yummy
//
//  Created by steve on 2025/7/31.
//

import Foundation
import SwiftUI
import Combine

/// DetailView 的 ViewModel，负责管理详情页面的所有业务逻辑和状态
@MainActor
class DetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前显示的菜谱数据（基于 ID 从 Repository 获取）
    @Published var formula: Formula?
    
    /// 菜谱 ID
    private let formulaId: String
    
    // MARK: - UI State
    
    /// 滚动偏移量，用于控制导航栏透明度
    @Published var scrollOffset: CGFloat = 0
    
    /// 导航栏是否透明
    @Published var isNavigationBarTransparent: Bool = true
    
    /// 是否显示分享 sheet
    @Published var isShareSheetPresented: Bool = false
    
    /// 是否显示分享覆盖层
    @Published var showShareOverlay: Bool = false
    
    /// 菜谱图片，用于分享功能
    @Published var formulaImage: UIImage?
    
    /// 是否显示提示覆盖层
    @Published var showTips: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    


    // MARK: - Camera State
    
    /// 是否应该显示相机界面（用于触发导航）
    @Published var shouldShowCamera: Bool = false
    
    /// 是否应该显示相册界面（用于触发导航）
    @Published var shouldShowPhotoLibrary: Bool = false
    
    /// 是否显示图片选择 sheet
    @Published var showImagePickerSheet: Bool = false
    
    /// 是否显示菜单操作面板
    @Published var showMenuActionSheet: Bool = false
    
    // MARK: - Dependencies
    
    private let formulaRepository: FormulaRepositoryProtocol
    private let cameraService: CameraServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// 初始化 ViewModel
    /// - Parameters:
    ///   - formulaId: 要显示的菜谱 ID
    ///   - formulaRepository: 菜谱数据仓库
    ///   - cameraService: 相机服务
    init(formulaId: String, 
         formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared,
         cameraService: CameraServiceProtocol = CameraService.shared) {
        self.formulaId = formulaId
        self.formulaRepository = formulaRepository
        self.cameraService = cameraService
        
        AppLog("🔄 [DetailViewModel] 开始初始化 - ID: \(formulaId)", level: .debug, category: .viewmodel)
        
        // 从 Repository 获取初始数据
        let allFormulas = formulaRepository.all()
        AppLog("🔄 [DetailViewModel] Repository 中共有 \(allFormulas.count) 个菜谱", level: .debug, category: .viewmodel)
        
        if let initialFormula = allFormulas.first(where: { $0.id == formulaId }) {
            self.formula = initialFormula
            AppLog("🔄 [DetailViewModel] 找到匹配的菜谱: \(initialFormula.name)", level: .debug, category: .viewmodel)
        } else {
            self.formula = nil
            AppLog("⚠️ [DetailViewModel] 未找到 ID 为 \(formulaId) 的菜谱", level: .warning, category: .viewmodel)
            AppLog("🔄 [DetailViewModel] 可用的菜谱 ID: \(allFormulas.map { $0.id })", level: .debug, category: .viewmodel)
        }
        
        // 订阅 FormulaRepository 的数据变化
        setupFormulaSubscription()
        
        AppLog("🔄 [DetailViewModel] 初始化完成 - ID: \(formulaId), 找到数据: \(formula != nil)", level: .info, category: .viewmodel)
    }
    
    // MARK: - Computed Properties
    
    /// 判断是否显示上传组件
    var shouldShowUploadView: Bool {
        guard let formula = formula else { return false }
        return formula.imgpath?.isEmpty != false || formula.state == .upload
    }
    
    /// 料理清单按钮文字
    var cuisineButtonText: String {
        guard let formula = formula else { return "加入料理清单" }
        return formula.isCuisine ? "查看料理清单" : "加入料理清单"
    }
    
    /// 料理清单按钮颜色
    var cuisineButtonColor: Color {
        guard let formula = formula else { return .accentColor }
        return formula.isCuisine ? .iconDisable : .accentColor
    }
    
    // MARK: - Public Methods
    

    
    /// 更新滚动偏移量并触发导航栏透明度更新
    /// - Parameter offset: 新的滚动偏移量
    func updateScrollOffset(_ offset: CGFloat) {
        scrollOffset = offset
        updateNavigationBarTransparency()
    }
    
    /// 处理分享按钮点击
    func handleShareButtonTap() {
        AppLog("🖼️ [DetailView] 用户点击分享按钮", level: .debug, category: .ui)
        showShareOverlay = true
    }
    
    /// 设置菜谱图片
    /// - Parameter image: 要设置的图片
    func setFormulaImage(_ image: UIImage) {
        AppLog("🖼️ [DetailView] LocalImageView图片加载成功，设置formulaImage", level: .debug, category: .ui)
        AppLog("🖼️ [DetailView] 加载的图片尺寸: \(image.size), scale: \(image.scale)", level: .debug, category: .ui)
        formulaImage = image
    }
    
    /// 处理提示按钮点击
    func handleTipsButtonTap() {
        showTips.toggle()
    }
    
    /// 设置错误信息
    /// - Parameter message: 错误信息
    func setError(_ message: String) {
        errorMessage = message
    }
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    
    /// 切换料理清单状态
    /// - Parameter onNavigateToCuisine: 导航到料理清单页面的回调
    func toggleCuisineStatus(onNavigateToCuisine: @escaping () -> Void) {
        guard let currentFormula = formula else {
            setError("菜谱数据不存在")
            return
        }
        
        if currentFormula.isCuisine {
            AppLog("🖱️ [DetailView] 用户点击查看料理清单按钮，关闭当前页面并跳转到料理清单页面", level: .debug, category: .ui)
            onNavigateToCuisine()
            return
        }
        
        Task {
            var updatedFormula = currentFormula
            updatedFormula.isCuisine.toggle()
            
            do {
                try await formulaRepository.update(updatedFormula)
                AppLog("✅ [料理清单] 状态更新成功 - \(currentFormula.name): isCuisine = \(updatedFormula.isCuisine)", level: .info, category: .viewmodel)
            } catch {
                setError("更新料理清单状态失败：\(error.localizedDescription)")
                AppLog("❌ [料理清单] 状态更新失败 - \(currentFormula.name): \(error)", level: .error, category: .viewmodel)
            }
        }
    }
    
    /// 处理图片上传
    func handleImageUpload() {
        // 显示底部 sheet 选择拍照或相册
        showImagePickerSheet = true
    }
    
    /// 处理拍照选择
    func handleTakePhoto() {
        // 先隐藏底部 sheet
        showImagePickerSheet = false
        
        Task {
            await requestCameraPermissionAndShowCamera()
        }
    }
    
    /// 请求相机权限并显示相机
    private func requestCameraPermissionAndShowCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            setError("设备不支持相机功能")
            return
        }
        
        let hasPermission = await cameraService.requestCameraPermission()
        
        if hasPermission {
            shouldShowCamera = true
        } else {
            setError("需要相机权限才能拍摄照片")
        }
    }
    
    /// 处理从相册选择
    func handleChooseFromLibrary() {
        // 先隐藏底部 sheet
        showImagePickerSheet = false
        
        Task {
            await requestPhotoLibraryPermissionAndShowPhotoLibrary()
        }
    }
    
    /// 请求相册权限并显示相册
    private func requestPhotoLibraryPermissionAndShowPhotoLibrary() async {
        let hasPermission = await cameraService.requestPhotoLibraryPermission()
        
        if hasPermission {
            shouldShowPhotoLibrary = true
        } else {
            setError("需要相册权限才能选择照片")
        }
    }
    
    /// 重置相机状态
    func resetCameraState() {
        shouldShowCamera = false
    }
    
    /// 重置相册状态
    func resetPhotoLibraryState() {
        shouldShowPhotoLibrary = false
    }
    

    
    // MARK: - Private Methods
    
    /// 更新导航栏透明度
    private func updateNavigationBarTransparency() {
        let shouldBeTransparent = scrollOffset > -430
        
        if isNavigationBarTransparent != shouldBeTransparent {
            withAnimation(.easeInOut) {
                isNavigationBarTransparent = shouldBeTransparent
            }
//            AppLog("导航栏透明度变化: \(shouldBeTransparent ? \"透明\" : \"不透明\"), 滚动偏移量: \(scrollOffset)", level: .debug, category: .ui)
        }
    }
    
    /// 设置 Formula 数据订阅
    private func setupFormulaSubscription() {
        AppLog("🔄 [DetailViewModel] 开始设置数据订阅 - ID: \(formulaId)", level: .debug, category: .viewmodel)
        
        formulaRepository.formulasPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] formulas in
                guard let self = self else { return }
                
                AppLog("🔄 [DetailViewModel] 收到数据更新通知 - 总数: \(formulas.count)", level: .debug, category: .viewmodel)
                
                // 查找当前 formulaId 对应的最新数据
                let updatedFormula = formulas.first(where: { $0.id == self.formulaId })
                
                // 只有当数据真正发生变化时才更新
                if updatedFormula != self.formula {
                    if let updatedFormula = updatedFormula {
                        AppLog("🔄 [DetailViewModel] 检测到 formula 数据变化 - ID: \(updatedFormula.id), 状态: \(updatedFormula.state)", level: .info, category: .viewmodel)
                    } else {
                        AppLog("⚠️ [DetailViewModel] formula 数据被删除 - ID: \(self.formulaId)", level: .warning, category: .viewmodel)
                    }
                    self.formula = updatedFormula
                } else {
                    AppLog("🔄 [DetailViewModel] 数据无变化，跳过更新 - ID: \(self.formulaId)", level: .debug, category: .viewmodel)
                }
            }
            .store(in: &cancellables)
    }
    

    

}
