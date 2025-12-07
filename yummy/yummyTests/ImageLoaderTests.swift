import XCTest
import UIKit
@testable import yummy

final class ImageLoaderTests: XCTestCase {
    
    var imageLoader: ImageLoader!
    
    override func setUp() {
        super.setUp()
        imageLoader = ImageLoader.shared
        // 清理缓存确保测试环境干净
        imageLoader.clearCache()
    }
    
    override func tearDown() {
        imageLoader.clearCache()
        super.tearDown()
    }
    
    // MARK: - 单例模式测试
    func testSingleton() {
        // 测试单例模式
        let instance1 = ImageLoader.shared
        let instance2 = ImageLoader.shared
        
        XCTAssertIdentical(instance1, instance2, "ImageLoader 应该是单例模式")
    }
    
    // MARK: - 调试测试
    func testDebugImageLoading() {
        // 创建一个简单的测试图片
        let testImage = createTestImage(size: CGSize(width: 50, height: 50))
        let testPath = "debug/test.png"
        
        // 保存图片
        saveImageToDocuments(testImage, at: testPath)
        
        // 验证文件存在
        let fileExists = fileExists(at: testPath)
        XCTAssertTrue(fileExists, "调试：文件应该存在")
        
        if fileExists {
            // 尝试加载图片
            let loadedImage = imageLoader.loadImage(from: testPath)
            XCTAssertNotNil(loadedImage, "调试：应该能够加载图片")
            
            if let loadedImage = loadedImage {
                XCTAssertEqual(loadedImage.size, testImage.size, "调试：图片尺寸应该正确")
            }
        }
        
        // 清理
        deleteFile(at: testPath)
    }
    
    // MARK: - 缓存功能测试
    func testCacheFunctionality() {
        // 创建测试图片
        let testImage = createTestImage(size: CGSize(width: 100, height: 100))
        let testPath = "test/cache/image.png"
        
        // 将图片保存到测试路径
        saveImageToDocuments(testImage, at: testPath)
        
        // 验证文件确实存在
        XCTAssertTrue(fileExists(at: testPath), "测试文件应该存在")
        
        // 第一次加载应该从文件系统加载
        let loadedImage1 = imageLoader.loadImage(from: testPath)
        XCTAssertNotNil(loadedImage1, "应该能够加载图片")
        XCTAssertEqual(loadedImage1?.size, testImage.size, "加载的图片尺寸应该正确")
        
        // 删除文件
        deleteFile(at: testPath)
        
        // 验证文件已被删除
        XCTAssertFalse(fileExists(at: testPath), "测试文件应该已被删除")
        
        // 第二次加载应该从缓存获取（即使文件已删除）
        let loadedImage2 = imageLoader.loadImage(from: testPath)
        XCTAssertNotNil(loadedImage2, "应该能够从缓存获取图片")
        XCTAssertEqual(loadedImage2?.size, testImage.size, "缓存的图片尺寸应该正确")
        
        // 清理测试文件
        deleteFile(at: testPath)
    }
    
    func testCacheClear() {
        // 创建测试图片并保存
        let testImage = createTestImage(size: CGSize(width: 50, height: 50))
        let testPath = "test/cache/clear_test.png"
        
        saveImageToDocuments(testImage, at: testPath)
        
        // 加载图片到缓存
        let loadedImage1 = imageLoader.loadImage(from: testPath)
        XCTAssertNotNil(loadedImage1, "应该能够加载图片")
        
        // 删除文件
        deleteFile(at: testPath)
        
        // 验证缓存中有图片
        let cachedImage = imageLoader.loadImage(from: testPath)
        XCTAssertNotNil(cachedImage, "缓存中应该有图片")
        
        // 清理缓存
        imageLoader.clearCache()
        
        // 验证缓存已清空
        let clearedImage = imageLoader.loadImage(from: testPath)
        XCTAssertNil(clearedImage, "清理缓存后应该无法获取图片")
    }
    
    // MARK: - 文件系统加载测试
    func testLoadImageFromFileSystem() {
        // 创建测试图片
        let testImage = createTestImage(size: CGSize(width: 200, height: 150))
        let testPath = "test/load/valid_image.png"
        
        // 保存图片到文件系统
        saveImageToDocuments(testImage, at: testPath)
        
        // 验证文件确实存在
        XCTAssertTrue(fileExists(at: testPath), "测试文件应该存在")
        
        // 测试加载图片
        let loadedImage = imageLoader.loadImage(from: testPath)
        
        XCTAssertNotNil(loadedImage, "应该能够从文件系统加载图片")
        XCTAssertEqual(loadedImage?.size, testImage.size, "加载的图片尺寸应该正确")
        
        // 清理测试文件
        deleteFile(at: testPath)
    }
    
    func testLoadImageWithInvalidPath() {
        // 测试不存在的文件路径
        let invalidPath = "nonexistent/image.png"
        let loadedImage = imageLoader.loadImage(from: invalidPath)
        
        XCTAssertNil(loadedImage, "不存在的文件路径应该返回 nil")
    }
    
    func testLoadImageWithInvalidData() {
        // 创建一个无效的图片文件
        let invalidPath = "test/invalid/data.txt"
        let invalidData = "这不是图片数据".data(using: .utf8)!
        
        // 保存无效数据到文件
        saveDataToDocuments(invalidData, at: invalidPath)
        
        // 尝试加载
        let loadedImage = imageLoader.loadImage(from: invalidPath)
        
        XCTAssertNil(loadedImage, "无效的图片数据应该返回 nil")
        
        // 清理测试文件
        deleteFile(at: invalidPath)
    }
    
    func testLoadImageWithEmptyData() {
        // 创建空数据文件
        let emptyPath = "test/empty/empty.dat"
        let emptyData = Data()
        
        saveDataToDocuments(emptyData, at: emptyPath)
        
        // 尝试加载
        let loadedImage = imageLoader.loadImage(from: emptyPath)
        
        XCTAssertNil(loadedImage, "空数据文件应该返回 nil")
        
        // 清理测试文件
        deleteFile(at: emptyPath)
    }
    
    func testLoadImageWithDifferentFormats() {
        // 测试不同格式的图片
        let formats = ["png"] // 暂时只测试 PNG 格式，因为我们的保存方法只支持 PNG
        let testSize = CGSize(width: 100, height: 100)
        
        for format in formats {
            let testPath = "test/formats/test_image.\(format)"
            let testImage = createTestImage(size: testSize)
            
            saveImageToDocuments(testImage, at: testPath)
            
            // 验证文件确实存在
            XCTAssertTrue(fileExists(at: testPath), "\(format) 格式的测试文件应该存在")
            
            let loadedImage = imageLoader.loadImage(from: testPath)
            XCTAssertNotNil(loadedImage, "应该能够加载 \(format) 格式的图片")
            XCTAssertEqual(loadedImage?.size, testSize, "\(format) 格式图片的尺寸应该正确")
            
            // 清理测试文件
            deleteFile(at: testPath)
        }
    }
    
    // MARK: - 错误处理测试
    func testDocumentsDirectoryAccess() {
        // 这个测试验证我们能够访问 Documents 目录
        // 如果无法访问，loadImage 方法会返回 nil
        let testPath = "test/access/test.png"
        
        // 创建一个临时文件来测试目录访问
        let testImage = createTestImage(size: CGSize(width: 10, height: 10))
        saveImageToDocuments(testImage, at: testPath)
        
        let loadedImage = imageLoader.loadImage(from: testPath)
        XCTAssertNotNil(loadedImage, "应该能够访问 Documents 目录")
        
        // 清理测试文件
        deleteFile(at: testPath)
    }
    
    // MARK: - 性能测试
    func testLoadImagePerformance() {
        // 创建测试图片
        let testImage = createTestImage(size: CGSize(width: 1000, height: 1000))
        let testPath = "test/performance/large_image.png"
        
        saveImageToDocuments(testImage, at: testPath)
        
        // 测试加载性能
        measure {
            for _ in 0..<10 {
                _ = imageLoader.loadImage(from: testPath)
            }
        }
        
        // 清理测试文件
        deleteFile(at: testPath)
    }
    
    // MARK: - 辅助方法
    private func createTestImage(size: CGSize) -> UIImage {
        // 使用 scale = 1.0 确保图片尺寸与预期一致
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        
        // 绘制一个简单的彩色矩形
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func saveImageToDocuments(_ image: UIImage, at relativePath: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("无法获取 Documents 目录")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        
        // 创建目录
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        
        // 保存图片
        if let imageData = image.pngData() {
            try? imageData.write(to: fileURL)
        } else {
            XCTFail("无法将图片转换为数据")
        }
    }
    
    private func saveDataToDocuments(_ data: Data, at relativePath: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("无法获取 Documents 目录")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        
        // 创建目录
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        
        // 保存数据
        try? data.write(to: fileURL)
    }
    
    private func deleteFile(at relativePath: String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func fileExists(at relativePath: String) -> Bool {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}
