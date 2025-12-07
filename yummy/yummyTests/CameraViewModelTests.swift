//
//  CameraViewModelTests.swift
//  yummyTests
//
//  Created by Qoder on 2025/09/17.
//

import XCTest
import SwiftUI
@testable import yummy

@MainActor
final class CameraViewModelTests: XCTestCase {
    
    var viewModel: CameraViewModel!
    var mockCameraService: MockCameraService!
    var mockImageUploadService: MockImageUploadService!
    var mockFormulaRepository: MockFormulaRepository!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        AppLog("🧪 [CameraViewModelTests] 测试环境初始化", level: .debug, category: .general)
        
        mockCameraService = MockCameraService()
        mockImageUploadService = MockImageUploadService()
        mockFormulaRepository = MockFormulaRepository()
        
        viewModel = CameraViewModel(
            cameraService: mockCameraService,
            imageUploadService: mockImageUploadService,
            formulaRepository: mockFormulaRepository
        )
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        mockCameraService = nil
        mockImageUploadService = nil
        mockFormulaRepository = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 初始化测试
    
    func testInitialization() throws {
        XCTAssertFalse(viewModel.showPermissionAlert, "初始状态权限弹窗应该为false")
        XCTAssertNil(viewModel.errorMessage, "初始状态错误信息应该为nil")
        XCTAssertFalse(viewModel.isUploading, "初始状态上传状态应该为false")
    }
    
    // MARK: - 图片处理测试
    
    func testHandleImagePickedSuccess() async throws {
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        let expectedUpdatedFormula = createTestFormula(id: testFormula.id, name: "Updated Formula")
        
        mockImageUploadService.shouldReturnSuccess = true
        mockImageUploadService.mockUpdatedFormula = expectedUpdatedFormula
        mockFormulaRepository.shouldReturnSuccess = true
        
        var completionCalled = false
        viewModel.handleImagePicked(testImage, formula: testFormula) {
            completionCalled = true
        }
        
        // 等待异步操作完成
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        XCTAssertTrue(mockImageUploadService.uploadImageCalled, "应该调用图片上传服务")
        XCTAssertTrue(mockFormulaRepository.saveCalled, "应该调用Repository保存方法")
        XCTAssertFalse(viewModel.isUploading, "上传完成后状态应该为false")
        XCTAssertNil(viewModel.errorMessage, "成功情况下不应该有错误信息")
        XCTAssertTrue(completionCalled, "完成回调应该被调用")
    }
    
    func testHandleImagePickedUploadFailure() async throws {
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        
        mockImageUploadService.shouldReturnSuccess = false
        mockImageUploadService.mockError = MockError.uploadFailed
        
        var completionCalled = false
        viewModel.handleImagePicked(testImage, formula: testFormula) {
            completionCalled = true
        }
        
        // 等待异步操作完成
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        XCTAssertTrue(mockImageUploadService.uploadImageCalled, "应该调用图片上传服务")
        XCTAssertFalse(mockFormulaRepository.saveCalled, "上传失败时不应该调用保存")
        XCTAssertFalse(viewModel.isUploading, "失败后状态应该为false")
        XCTAssertNotNil(viewModel.errorMessage, "失败情况下应该有错误信息")
        XCTAssertTrue(viewModel.errorMessage!.contains("图片保存失败"), "错误信息应该包含预期文本")
        XCTAssertFalse(completionCalled, "失败时完成回调不应该被调用")
    }
    
    func testHandleImagePickedRepositoryFailure() async throws {
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        let expectedUpdatedFormula = createTestFormula(id: testFormula.id, name: "Updated Formula")
        
        mockImageUploadService.shouldReturnSuccess = true
        mockImageUploadService.mockUpdatedFormula = expectedUpdatedFormula
        mockFormulaRepository.shouldReturnSuccess = false
        mockFormulaRepository.mockError = MockError.saveFailed
        
        var completionCalled = false
        viewModel.handleImagePicked(testImage, formula: testFormula) {
            completionCalled = true
        }
        
        // 等待异步操作完成
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        XCTAssertTrue(mockImageUploadService.uploadImageCalled, "应该调用图片上传服务")
        XCTAssertTrue(mockFormulaRepository.saveCalled, "应该调用Repository保存方法")
        XCTAssertFalse(viewModel.isUploading, "失败后状态应该为false")
        XCTAssertNotNil(viewModel.errorMessage, "失败情况下应该有错误信息")
        XCTAssertTrue(viewModel.errorMessage!.contains("图片保存失败"), "错误信息应该包含预期文本")
        XCTAssertFalse(completionCalled, "失败时完成回调不应该被调用")
    }
    
    // MARK: - 状态管理测试
    
    func testUploadingStateManagement() async throws {
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        
        mockImageUploadService.shouldReturnSuccess = true
        mockImageUploadService.mockUpdatedFormula = testFormula
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 开始上传
        viewModel.handleImagePicked(testImage, formula: testFormula) {}
        
        // 立即检查状态
        await Task.yield()
        XCTAssertTrue(viewModel.isUploading, "上传过程中状态应该为true")
        
        // 等待完成
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(viewModel.isUploading, "上传完成后状态应该为false")
    }
    
    func testClearError() {
        viewModel.errorMessage = "测试错误信息"
        XCTAssertNotNil(viewModel.errorMessage, "设置错误信息后应该不为nil")
        
        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage, "清除错误后应该为nil")
    }
    
    func testErrorMessageSetting() async throws {
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        
        mockImageUploadService.shouldReturnSuccess = false
        mockImageUploadService.mockError = MockError.networkError
        
        viewModel.handleImagePicked(testImage, formula: testFormula) {}
        
        // 等待异步操作完成
        try await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertNotNil(viewModel.errorMessage, "应该设置错误信息")
        XCTAssertTrue(viewModel.errorMessage!.contains("图片保存失败"), "错误信息应该包含预期前缀")
    }
    
    // MARK: - 权限测试
    
    func testPermissionAlertState() {
        XCTAssertFalse(viewModel.showPermissionAlert, "初始权限弹窗状态应该为false")
        
        viewModel.showPermissionAlert = true
        XCTAssertTrue(viewModel.showPermissionAlert, "设置后权限弹窗状态应该为true")
    }
    
    // MARK: - 依赖注入测试
    
    func testDependencyInjection() {
        // 验证依赖是否正确注入 - 由于使用了协议，无法直接比较实例
        // 这里测试功能行为来验证依赖注入是否正确
        XCTAssertNotNil(viewModel, "ViewModel应该被正确初始化")
        
        // 通过功能测试来验证依赖注入
        mockImageUploadService.uploadImageCalled = false
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        
        viewModel.handleImagePicked(testImage, formula: testFormula) {}
        
        // 异步等待
        let expectation = XCTestExpectation(description: "依赖注入验证")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockImageUploadService.uploadImageCalled, "Mock服务应该被调用，证明依赖注入正确")
    }
    
    func testMultipleImageUploads() async throws {
        let testFormula = createTestFormula()
        let testImage = createTestImage()
        
        mockImageUploadService.shouldReturnSuccess = true
        mockImageUploadService.mockUpdatedFormula = testFormula
        mockFormulaRepository.shouldReturnSuccess = true
        
        // 第一次上传
        viewModel.handleImagePicked(testImage, formula: testFormula) {}
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // 重置mock状态
        mockImageUploadService.uploadImageCalled = false
        mockFormulaRepository.saveCalled = false
        
        // 第二次上传
        viewModel.handleImagePicked(testImage, formula: testFormula) {}
        try await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(mockImageUploadService.uploadImageCalled, "第二次上传应该被调用")
        XCTAssertTrue(mockFormulaRepository.saveCalled, "第二次保存应该被调用")
    }
}

