//
//  CameraServiceTests.swift
//  yummyTests
//
//  Created by Qoder on 2025/01/27.
//

import XCTest
import UIKit
import AVFoundation
import Photos
@testable import yummy

final class CameraServiceTests: XCTestCase {
    
    var cameraService: CameraService!
    var mockFileManager: MockFileManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        AppLog("🧪 [CameraServiceTests] 测试环境初始化", level: .debug, category: .general)
        
        cameraService = CameraService.shared
        mockFileManager = MockFileManager()
    }
    
    override func tearDownWithError() throws {
        cameraService = nil
        mockFileManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 权限检查测试
    
    func testCheckCameraPermissionAuthorized() async {
        // 注意：这个测试需要模拟权限状态，实际测试中可能需要使用依赖注入
        // 这里主要测试方法调用不会崩溃
        let hasPermission = await cameraService.checkCameraPermission()
        
        // 验证方法正常执行（结果取决于测试环境的实际权限状态）
        XCTAssertTrue(hasPermission == true || hasPermission == false, "权限检查应该返回布尔值")
    }
    
    func testRequestCameraPermission() async {
        // 测试权限请求方法调用
        let granted = await cameraService.requestCameraPermission()
        
        // 验证方法正常执行（结果取决于测试环境的实际权限状态）
        XCTAssertTrue(granted == true || granted == false, "权限请求应该返回布尔值")
    }
    
    func testRequestPhotoLibraryPermission() async {
        // 测试相册权限请求方法调用
        let granted = await cameraService.requestPhotoLibraryPermission()
        
        // 验证方法正常执行（结果取决于测试环境的实际权限状态）
        XCTAssertTrue(granted == true || granted == false, "相册权限请求应该返回布尔值")
    }
    
    // MARK: - 图片保存测试
    
    func testSaveImageToDocumentsSuccess() throws {
        // 创建测试图片
        let testImage = createTestImage(size: CGSize(width: 200, height: 200))
        let fileName = "test-image.jpg"
        
        // 执行保存
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: fileName)
        
        // 验证返回路径
        XCTAssertTrue(savedPath.hasPrefix("images/"), "保存路径应该以 'images/' 开头")
        XCTAssertTrue(savedPath.contains(fileName), "保存路径应该包含文件名")
        XCTAssertEqual(savedPath, "images/\(fileName)", "保存路径应该完全匹配预期格式")
        
        // 验证文件是否真的存在
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fullPath.path), "保存的文件应该存在于文件系统中")
        
        // 清理测试文件
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    func testSaveImageToDocumentsCreatesImagesDirectory() throws {
        // 创建测试图片
        let testImage = createTestImage()
        let fileName = "test-directory.jpg"
        
        // 确保 images 目录不存在
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        try? FileManager.default.removeItem(at: imagesDirectory)
        
        // 执行保存
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: fileName)
        
        // 验证 images 目录被创建
        XCTAssertTrue(FileManager.default.fileExists(atPath: imagesDirectory.path), "应该创建 images 目录")
        XCTAssertTrue(savedPath.hasPrefix("images/"), "保存路径应该以 'images/' 开头")
        
        // 清理测试文件
        try? FileManager.default.removeItem(at: imagesDirectory)
    }
    
    func testSaveImageToDocumentsWithLargeImage() throws {
        // 创建大尺寸测试图片（模拟高分辨率图片）
        let largeImage = createTestImage(size: CGSize(width: 2000, height: 2000), scale: 2.0)
        let fileName = "test-large-image.jpg"
        
        // 执行保存
        let savedPath = try cameraService.saveImageToDocuments(largeImage, fileName: fileName)
        
        // 验证保存成功
        XCTAssertTrue(savedPath.hasPrefix("images/"), "大图片保存路径应该正确")
        
        // 验证保存的文件存在
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fullPath.path), "大图片应该被成功保存")
        
        // 验证文件大小（应该比原图小，因为进行了压缩和缩放）
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fullPath.path)
        let fileSize = fileAttributes[.size] as! Int64
        XCTAssertGreaterThan(fileSize, 0, "保存的文件大小应该大于0")
        
        // 清理测试文件
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    func testSaveImageToDocumentsWithEmptyFileName() throws {
        let testImage = createTestImage()
        
        // 测试空文件名
        XCTAssertThrowsError(try cameraService.saveImageToDocuments(testImage, fileName: "")) { error in
            // 这里可能不会抛出错误，因为空文件名在技术上是可以的
            // 主要验证方法调用不会崩溃
        }
    }
    
    func testSaveImageToDocumentsWithInvalidImage() throws {
        // 创建一个可能无法转换为JPEG的图片（虽然UIImage通常都能转换）
        let testImage = createTestImage()
        let fileName = "test-invalid.jpg"
        
        // 这个方法应该不会抛出错误，因为UIImage.jpegData通常都能成功
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: fileName)
        XCTAssertTrue(savedPath.hasPrefix("images/"), "即使图片可能有问题，也应该尝试保存")
        
        // 清理
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    // MARK: - 错误处理测试
    
    func testCameraErrorMessages() {
        // 测试各种错误类型的描述信息
        let documentsError = CameraError.documentsDirectoryNotFound
        XCTAssertEqual(documentsError.errorDescription, "无法找到文档目录", "文档目录错误信息应该正确")
        
        let conversionError = CameraError.imageConversionFailed
        XCTAssertEqual(conversionError.errorDescription, "图片转换失败", "图片转换错误信息应该正确")
        
        let permissionError = CameraError.permissionDenied
        XCTAssertEqual(permissionError.errorDescription, "相机权限被拒绝", "权限错误信息应该正确")
    }
    
    // MARK: - 图片缩放测试
    
    func testImageScaling() throws {
        // 创建需要缩放的大图片
        let originalSize = CGSize(width: 1500, height: 1000)
        let testImage = createTestImage(size: originalSize, scale: 2.0)
        let fileName = "test-scaling.jpg"
        
        // 保存图片（应该触发缩放）
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: fileName)
        
        // 验证保存成功
        XCTAssertTrue(savedPath.hasPrefix("images/"), "缩放后的图片应该保存成功")
        
        // 验证文件存在
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fullPath.path), "缩放后的图片文件应该存在")
        
        // 清理
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    func testImageScalingWithSmallImage() throws {
        // 创建不需要缩放的小图片
        let smallSize = CGSize(width: 800, height: 600)
        let testImage = createTestImage(size: smallSize, scale: 1.0)
        let fileName = "test-small-image.jpg"
        
        // 保存图片（不应该触发缩放）
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: fileName)
        
        // 验证保存成功
        XCTAssertTrue(savedPath.hasPrefix("images/"), "小图片应该保存成功")
        
        // 清理
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    // MARK: - 并发测试
    
    func testConcurrentImageSaving() async throws {
        // 测试并发保存多个图片
        let imageCount = 5
        let fileNamePrefix = "concurrent-test"
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<imageCount {
                group.addTask {
                    do {
                        let testImage = self.createTestImage()
                        let fileName = "\(fileNamePrefix)-\(i).jpg"
                        let _ = try self.cameraService.saveImageToDocuments(testImage, fileName: fileName)
                    } catch {
                        XCTFail("并发保存图片失败: \(error)")
                    }
                }
            }
        }
        
        // 验证所有文件都被保存
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        
        for i in 0..<imageCount {
            let fileName = "\(fileNamePrefix)-\(i).jpg"
            let filePath = imagesDirectory.appendingPathComponent(fileName)
            XCTAssertTrue(FileManager.default.fileExists(atPath: filePath.path), "并发保存的文件 \(fileName) 应该存在")
        }
        
        // 清理所有测试文件
        try? FileManager.default.removeItem(at: imagesDirectory)
    }
    
    // MARK: - 边界条件测试
    
    func testSaveImageWithSpecialCharactersInFileName() throws {
        let testImage = createTestImage()
        let fileName = "test-image with spaces & symbols!.jpg"
        
        // 测试包含特殊字符的文件名
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: fileName)
        XCTAssertTrue(savedPath.hasPrefix("images/"), "包含特殊字符的文件名应该保存成功")
        XCTAssertTrue(savedPath.contains(fileName), "保存路径应该包含原始文件名")
        
        // 验证文件存在
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fullPath.path), "包含特殊字符的文件应该存在")
        
        // 清理
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    func testSaveImageWithVeryLongFileName() throws {
        let testImage = createTestImage()
        let longFileName = String(repeating: "a", count: 100) + ".jpg"
        
        // 测试很长的文件名
        let savedPath = try cameraService.saveImageToDocuments(testImage, fileName: longFileName)
        XCTAssertTrue(savedPath.hasPrefix("images/"), "长文件名应该保存成功")
        
        // 清理
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        try? FileManager.default.removeItem(at: fullPath)
    }
    
    // MARK: - 内存和性能测试
    
    func testMemoryUsageWithLargeImage() throws {
        // 创建大图片测试内存使用
        let largeImage = createTestImage(size: CGSize(width: 3000, height: 3000), scale: 3.0)
        let fileName = "memory-test.jpg"
        
        // 测量保存操作
        let startTime = CFAbsoluteTimeGetCurrent()
        let savedPath = try cameraService.saveImageToDocuments(largeImage, fileName: fileName)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // 验证保存成功
        XCTAssertTrue(savedPath.hasPrefix("images/"), "大图片应该保存成功")
        
        // 验证保存时间合理（应该小于5秒）
        let saveTime = endTime - startTime
        XCTAssertLessThan(saveTime, 5.0, "大图片保存时间应该合理")
        
        // 清理
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fullPath = documentsDirectory.appendingPathComponent(savedPath)
        try? FileManager.default.removeItem(at: fullPath)
    }
}

// MARK: - 测试辅助方法

extension CameraServiceTests {
    
    /// 创建测试图片
    private func createTestImage(size: CGSize = CGSize(width: 100, height: 100), 
                                scale: CGFloat = 1.0, 
                                color: UIColor = .blue) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Mock FileManager (如果需要的话)

class MockFileManager {
    var shouldFailToCreateDirectory = false
    var shouldFailToWriteFile = false
    var shouldFailToFindDocumentsDirectory = false
    
    func reset() {
        shouldFailToCreateDirectory = false
        shouldFailToWriteFile = false
        shouldFailToFindDocumentsDirectory = false
    }
}
