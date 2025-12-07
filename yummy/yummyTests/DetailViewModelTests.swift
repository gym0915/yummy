import XCTest
import UIKit
import Combine
@testable import yummy

/// DetailViewModel 测试类
/// 测试详情页面的所有业务逻辑和状态管理
@MainActor
final class DetailViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var viewModel: DetailViewModel!
    private var mockFormulaRepository: MockFormulaRepository!
    private var mockCameraService: MockCameraService!
    private var cancellables: Set<AnyCancellable>!
    
    // 测试用的 Formula 数据
    private var testFormula: Formula!
    private let testFormulaId = "test-detail-formula-id"
    
    // MARK: - Test Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        AppLog("=== DetailViewModelTests setUp 开始 ===", level: .debug, category: .viewmodel)
        
        cancellables = Set<AnyCancellable>()
        
        // 创建测试用的 Formula
        testFormula = createDetailTestFormula(id: testFormulaId)
        
        // 创建 Mock 对象
        mockFormulaRepository = MockFormulaRepository()
        mockCameraService = MockCameraService()
        
        // 设置初始数据
        mockFormulaRepository.mockFormulas = [testFormula]
        
        // 发送初始数据到 Publisher
        mockFormulaRepository.sendFormulasUpdate()
        
        // 创建 ViewModel
        viewModel = DetailViewModel(
            formulaId: testFormulaId,
            formulaRepository: mockFormulaRepository,
            cameraService: mockCameraService
        )
        
        // 等待数据初始化
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05秒
        
        AppLog("DetailViewModelTests setUp 完成", level: .debug, category: .viewmodel)
    }
    
    override func tearDown() async throws {
        AppLog("=== DetailViewModelTests tearDown 开始 ===", level: .debug, category: .viewmodel)
        
        cancellables = nil
        viewModel = nil
        mockFormulaRepository = nil
        mockCameraService = nil
        testFormula = nil
        
        AppLog("DetailViewModelTests tearDown 完成", level: .debug, category: .viewmodel)
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    

    
    // MARK: - Initialization Tests
    
    /// 测试 ViewModel 初始化 - 找到匹配的 Formula
    func testInitialization_WithValidFormula() {
        AppLog("开始测试 ViewModel 初始化 - 有效 Formula", level: .debug, category: .viewmodel)
        
        XCTAssertNotNil(viewModel.formula, "应该找到匹配的 Formula")
        XCTAssertEqual(viewModel.formula?.id, testFormulaId, "Formula ID 应该匹配")
        XCTAssertEqual(viewModel.formula?.name, "测试详情菜谱", "Formula 名称应该匹配")
        
        AppLog("ViewModel 初始化 - 有效 Formula 测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试 ViewModel 初始化 - 未找到匹配的 Formula
    func testInitialization_WithInvalidFormula() {
        AppLog("开始测试 ViewModel 初始化 - 无效 Formula", level: .debug, category: .viewmodel)
        
        // 创建一个没有匹配 Formula 的 ViewModel
        let invalidViewModel = DetailViewModel(
            formulaId: "non-existent-id",
            formulaRepository: mockFormulaRepository,
            cameraService: mockCameraService
        )
        
        XCTAssertNil(invalidViewModel.formula, "不应该找到匹配的 Formula")
        
        AppLog("ViewModel 初始化 - 无效 Formula 测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - UI State Tests
    
    /// 测试滚动偏移量更新
    func testScrollOffsetUpdate() {
        AppLog("开始测试滚动偏移量更新", level: .debug, category: .viewmodel)
        
        // 初始状态
        XCTAssertEqual(viewModel.scrollOffset, 0, "初始滚动偏移量应该为 0")
        XCTAssertTrue(viewModel.isNavigationBarTransparent, "初始导航栏应该是透明的")
        
        // 更新滚动偏移量 - 触发导航栏变化
        viewModel.updateScrollOffset(-500)
        XCTAssertEqual(viewModel.scrollOffset, -500, "滚动偏移量应该更新")
        XCTAssertFalse(viewModel.isNavigationBarTransparent, "导航栏应该变为不透明")
        
        // 更新滚动偏移量 - 导航栏恢复透明
        viewModel.updateScrollOffset(-400)
        XCTAssertEqual(viewModel.scrollOffset, -400, "滚动偏移量应该更新")
        XCTAssertTrue(viewModel.isNavigationBarTransparent, "导航栏应该恢复透明")
        
        AppLog("滚动偏移量更新测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试分享相关状态
    func testShareStates() {
        AppLog("开始测试分享相关状态", level: .debug, category: .viewmodel)
        
        // 初始状态
        XCTAssertFalse(viewModel.isShareSheetPresented, "初始状态不应该显示分享 sheet")
        XCTAssertFalse(viewModel.showShareOverlay, "初始状态不应该显示分享覆盖层")
        XCTAssertNil(viewModel.formulaImage, "初始状态没有菜谱图片")
        
        // 处理分享按钮点击
        viewModel.handleShareButtonTap()
        XCTAssertTrue(viewModel.showShareOverlay, "点击分享按钮后应该显示分享覆盖层")
        
        // 设置菜谱图片
        let testImage = createTestImage()
        viewModel.setFormulaImage(testImage)
        XCTAssertNotNil(viewModel.formulaImage, "设置菜谱图片后应该有图片")
        
        AppLog("分享相关状态测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试提示相关状态
    func testTipsState() {
        AppLog("开始测试提示相关状态", level: .debug, category: .viewmodel)
        
        // 初始状态
        XCTAssertFalse(viewModel.showTips, "初始状态不应该显示提示")
        
        // 切换提示状态
        viewModel.handleTipsButtonTap()
        XCTAssertTrue(viewModel.showTips, "点击提示按钮后应该显示提示")
        
        viewModel.handleTipsButtonTap()
        XCTAssertFalse(viewModel.showTips, "再次点击提示按钮后应该隐藏提示")
        
        AppLog("提示相关状态测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Error Handling Tests
    
    /// 测试错误处理
    func testErrorHandling() {
        AppLog("开始测试错误处理", level: .debug, category: .viewmodel)
        
        // 初始状态
        XCTAssertNil(viewModel.errorMessage, "初始状态不应该有错误信息")
        
        // 设置错误信息
        let testError = "测试错误信息"
        viewModel.setError(testError)
        XCTAssertEqual(viewModel.errorMessage, testError, "错误信息应该被设置")
        
        // 清除错误信息
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage, "错误信息应该被清除")
        
        AppLog("错误处理测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Computed Properties Tests
    
    /// 测试计算属性 - shouldShowUploadView
    func testShouldShowUploadView() {
        AppLog("开始测试 shouldShowUploadView 计算属性", level: .debug, category: .viewmodel)
        
        // 测试状态为 .upload 的情况
        var uploadFormula = testFormula!
        uploadFormula.state = .upload
        mockFormulaRepository.updateFormula(uploadFormula)
        
        // 等待数据更新
        let expectation = XCTestExpectation(description: "数据更新")
        viewModel.$formula
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(viewModel.shouldShowUploadView, "状态为 upload 时应该显示上传视图")
        
        // 测试有图片路径且状态为 finish 的情况
        var finishFormula = testFormula!
        finishFormula.state = .finish
        finishFormula.imgpath = "valid-image-path.jpg"
        mockFormulaRepository.updateFormula(finishFormula)
        
        let expectation2 = XCTestExpectation(description: "数据更新2")
        viewModel.$formula
            .dropFirst()
            .sink { _ in
                expectation2.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation2], timeout: 1.0)
        
        XCTAssertFalse(viewModel.shouldShowUploadView, "有图片路径且状态为 finish 时不应该显示上传视图")
        
        AppLog("shouldShowUploadView 计算属性测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试计算属性 - 料理清单按钮
    func testCuisineButtonProperties() {
        AppLog("开始测试料理清单按钮计算属性", level: .debug, category: .viewmodel)
        
        // 测试未加入料理清单的情况
        XCTAssertEqual(viewModel.cuisineButtonText, "加入料理清单", "未加入料理清单时按钮文字应该正确")
        XCTAssertEqual(viewModel.cuisineButtonColor, .accentColor, "未加入料理清单时按钮颜色应该正确")
        
        // 测试已加入料理清单的情况
        var cuisineFormula = testFormula!
        cuisineFormula.isCuisine = true
        mockFormulaRepository.updateFormula(cuisineFormula)
        
        let expectation = XCTestExpectation(description: "数据更新")
        viewModel.$formula
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(viewModel.cuisineButtonText, "查看料理清单", "已加入料理清单时按钮文字应该正确")
        XCTAssertEqual(viewModel.cuisineButtonColor, .iconDisable, "已加入料理清单时按钮颜色应该正确")
        
        AppLog("料理清单按钮计算属性测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Business Logic Tests
    
    /// 测试切换料理清单状态 - 加入料理清单
    func testToggleCuisineStatus_AddToCuisine() async {
        AppLog("开始测试切换料理清单状态 - 加入", level: .debug, category: .viewmodel)
        
        var navigationCalled = false
        let onNavigate = { navigationCalled = true }
        
        // 验证初始状态
        AppLog("检查初始状态: viewModel.formula = \(viewModel.formula?.name ?? "nil")", level: .debug, category: .viewmodel)
        AppLog("检查 mockFormulas: \(mockFormulaRepository.mockFormulas.count) 个公式", level: .debug, category: .viewmodel)
        
        // 确保数据存在
        if viewModel.formula == nil {
            // 如果初始化失败，重新设置
            AppLog("初始 formula 为 nil，重新设置", level: .warning, category: .viewmodel)
            mockFormulaRepository.sendFormulasUpdate()
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        }
        
        XCTAssertNotNil(viewModel.formula, "应该有有效的 Formula 数据")
        XCTAssertFalse(viewModel.formula?.isCuisine == true, "初始状态不应该在料理清单中")
        
        // 重置 Mock 状态
        mockFormulaRepository.updateCalled = false
        
        // 切换状态（加入料理清单）
        AppLog("开始执行 toggleCuisineStatus", level: .debug, category: .viewmodel)
        viewModel.toggleCuisineStatus(onNavigateToCuisine: onNavigate)
        
        // 等待异步操作完成
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
        
        AppLog("异步操作完成，updateCalled: \(mockFormulaRepository.updateCalled)", level: .debug, category: .viewmodel)
        
        XCTAssertFalse(navigationCalled, "加入料理清单时不应该触发导航")
        XCTAssertTrue(mockFormulaRepository.updateCalled, "应该调用 Repository 的 update 方法")
        
        AppLog("切换料理清单状态 - 加入测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试切换料理清单状态 - 查看料理清单
    func testToggleCuisineStatus_ViewCuisine() {
        AppLog("开始测试切换料理清单状态 - 查看", level: .debug, category: .viewmodel)
        
        // 设置为已在料理清单中
        var cuisineFormula = testFormula!
        cuisineFormula.isCuisine = true
        mockFormulaRepository.updateFormula(cuisineFormula)
        
        let expectation = XCTestExpectation(description: "数据更新")
        viewModel.$formula
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
        
        var navigationCalled = false
        let onNavigate = { navigationCalled = true }
        
        // 切换状态（查看料理清单）
        viewModel.toggleCuisineStatus(onNavigateToCuisine: onNavigate)
        
        XCTAssertTrue(navigationCalled, "查看料理清单时应该触发导航")
        
        AppLog("切换料理清单状态 - 查看测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试切换料理清单状态 - 无数据错误
    func testToggleCuisineStatus_NoFormula() {
        AppLog("开始测试切换料理清单状态 - 无数据", level: .debug, category: .viewmodel)
        
        // 创建没有数据的 ViewModel
        let emptyViewModel = DetailViewModel(
            formulaId: "non-existent",
            formulaRepository: mockFormulaRepository,
            cameraService: mockCameraService
        )
        
        var navigationCalled = false
        let onNavigate = { navigationCalled = true }
        
        // 尝试切换状态
        emptyViewModel.toggleCuisineStatus(onNavigateToCuisine: onNavigate)
        
        XCTAssertFalse(navigationCalled, "无数据时不应该触发导航")
        XCTAssertNotNil(emptyViewModel.errorMessage, "无数据时应该设置错误信息")
        
        AppLog("切换料理清单状态 - 无数据测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Camera & Photo Library Tests
    
    /// 测试图片上传流程
    func testImageUploadFlow() {
        AppLog("开始测试图片上传流程", level: .debug, category: .viewmodel)
        
        // 初始状态
        XCTAssertFalse(viewModel.showImagePickerSheet, "初始状态不应该显示图片选择 sheet")
        
        // 处理图片上传
        viewModel.handleImageUpload()
        XCTAssertTrue(viewModel.showImagePickerSheet, "处理图片上传后应该显示图片选择 sheet")
        
        AppLog("图片上传流程测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试拍照流程 - 有权限
    func testTakePhotoFlow_WithPermission() async {
        AppLog("开始测试拍照流程 - 有权限", level: .debug, category: .viewmodel)
        
        // 设置相机权限为 true
        mockCameraService.cameraPermissionResult = true
        
        // 初始状态
        XCTAssertFalse(viewModel.shouldShowCamera, "初始状态不应该显示相机")
        
        // 处理拍照
        viewModel.handleTakePhoto()
        
        // 等待异步操作
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.showImagePickerSheet, "拍照时应该隐藏图片选择 sheet")
        XCTAssertTrue(viewModel.shouldShowCamera, "有权限时应该显示相机")
        XCTAssertTrue(mockCameraService.requestCameraPermissionCalled, "应该请求相机权限")
        
        // 重置相机状态
        viewModel.resetCameraState()
        XCTAssertFalse(viewModel.shouldShowCamera, "重置后不应该显示相机")
        
        AppLog("拍照流程 - 有权限测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试拍照流程 - 无权限
    func testTakePhotoFlow_WithoutPermission() async {
        AppLog("开始测试拍照流程 - 无权限", level: .debug, category: .viewmodel)
        
        // 设置相机权限为 false
        mockCameraService.cameraPermissionResult = false
        
        // 清除之前的错误信息
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage, "清除错误信息后应该为 nil")
        
        // 处理拍照
        viewModel.handleTakePhoto()
        
        // 等待异步操作完成
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        XCTAssertFalse(viewModel.shouldShowCamera, "无权限时不应该显示相机")
        XCTAssertNotNil(viewModel.errorMessage, "无权限时应该显示错误信息")
        XCTAssertEqual(viewModel.errorMessage, "需要相机权限才能拍摄照片", "错误信息应该正确")
        
        AppLog("拍照流程 - 无权限测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试相册流程 - 有权限
    func testPhotoLibraryFlow_WithPermission() async {
        AppLog("开始测试相册流程 - 有权限", level: .debug, category: .viewmodel)
        
        // 设置相册权限为 true
        mockCameraService.photoLibraryPermissionResult = true
        
        // 初始状态
        XCTAssertFalse(viewModel.shouldShowPhotoLibrary, "初始状态不应该显示相册")
        
        // 处理相册选择
        viewModel.handleChooseFromLibrary()
        
        // 等待异步操作
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertFalse(viewModel.showImagePickerSheet, "选择相册时应该隐藏图片选择 sheet")
        XCTAssertTrue(viewModel.shouldShowPhotoLibrary, "有权限时应该显示相册")
        XCTAssertTrue(mockCameraService.requestPhotoLibraryPermissionCalled, "应该请求相册权限")
        
        // 重置相册状态
        viewModel.resetPhotoLibraryState()
        XCTAssertFalse(viewModel.shouldShowPhotoLibrary, "重置后不应该显示相册")
        
        AppLog("相册流程 - 有权限测试完成", level: .debug, category: .viewmodel)
    }
    
    /// 测试相册流程 - 无权限
    func testPhotoLibraryFlow_WithoutPermission() async {
        AppLog("开始测试相册流程 - 无权限", level: .debug, category: .viewmodel)
        
        // 设置相册权限为 false
        mockCameraService.photoLibraryPermissionResult = false
        
        // 清除之前的错误信息
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage, "清除错误信息后应该为 nil")
        
        // 处理相册选择
        viewModel.handleChooseFromLibrary()
        
        // 等待异步操作
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        XCTAssertFalse(viewModel.shouldShowPhotoLibrary, "无权限时不应该显示相册")
        XCTAssertNotNil(viewModel.errorMessage, "无权限时应该显示错误信息")
        XCTAssertEqual(viewModel.errorMessage, "需要相册权限才能选择照片", "错误信息应该正确")
        
        AppLog("相册流程 - 无权限测试完成", level: .debug, category: .viewmodel)
    }
    
    // MARK: - Data Subscription Tests
    
    /// 测试数据订阅更新
    func testDataSubscription() {
        AppLog("开始测试数据订阅更新", level: .debug, category: .viewmodel)
        
        let expectation = XCTestExpectation(description: "数据订阅更新")
        var updateCount = 0
        
        // 监听数据变化
        viewModel.$formula
            .sink { _ in
                updateCount += 1
                if updateCount >= 2 { // 初始值 + 更新值
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // 更新 Repository 中的数据
        var updatedFormula = testFormula!
        updatedFormula.name = "更新后的菜谱名称"
        mockFormulaRepository.updateFormula(updatedFormula)
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(viewModel.formula?.name, "更新后的菜谱名称", "数据应该通过订阅更新")
        
        AppLog("数据订阅更新测试完成", level: .debug, category: .viewmodel)
    }
    

}