import XCTest
import UIKit
import Photos
@testable import yummy

/// ShareService 测试类
/// 测试分享服务的图片生成、相册权限和保存功能
final class ShareServiceTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var shareService: ShareService!
    private var testFormula: Formula!
    private var testImage: UIImage!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        AppLog("=== ShareServiceTests setUp 开始 ===", level: .debug, category: .ui)
        
        // 创建测试实例
        shareService = ShareService.shared
        
        // 创建测试用的Formula
        testFormula = createTestFormula()
        
        // 创建测试用的图片
        testImage = createTestImage()
        
        AppLog("ShareServiceTests setUp 完成", level: .debug, category: .ui)
    }
    
    override func tearDown() {
        AppLog("=== ShareServiceTests tearDown 开始 ===", level: .debug, category: .ui)
        
        shareService = nil
        testFormula = nil
        testImage = nil
        
        AppLog("ShareServiceTests tearDown 完成", level: .debug, category: .ui)
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// 创建测试用的Formula
    private func createTestFormula() -> Formula {
        let testId = "test-formula-\(UUID().uuidString)"
        
        return Formula(
            name: "测试菜谱",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "主料1", quantity: "100g", category: nil),
                    Ingredient(name: "主料2", quantity: "200g", category: nil)
                ],
                spicesSeasonings: [
                    Ingredient(name: "配料1", quantity: "适量", category: nil),
                    Ingredient(name: "配料2", quantity: "少许", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "蛸料1", quantity: "2勺"),
                    SauceIngredient(name: "蛸料2", quantity: "1勺")
                ]
            ),
            tools: [
                Tool(name: "平底锅"),
                Tool(name: "锅铲")
            ],
            preparation: [
                PreparationStep(step: "准备步骤1", details: "准备步骤1"),
                PreparationStep(step: "准备步骤2", details: "准备步骤2")
            ],
            steps: [
                CookingStep(step: "料理步骤1", details: "详细描述1"),
                CookingStep(step: "料理步骤2", details: "详细描述2")
            ],
            tips: ["小窍门1", "小窍门2"],
            tags: ["测试", "简单"],
            date: Date(),
            prompt: nil,
            state: .finish,
            imgpath: nil,
            isCuisine: false
        )
    }
    
    /// 创建测试用的图片
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    // MARK: - Basic Tests
    
    /// 测试 ShareService 单例
    func testShareService_单例模式() {
        AppLog("开始测试 ShareService 单例模式", level: .debug, category: .ui)
        
        XCTAssertNotNil(shareService, "ShareService 应该被正确初始化")
        XCTAssertTrue(shareService === ShareService.shared, "应该返回同一个单例实例")
        
        AppLog("ShareService 单例模式测试完成", level: .debug, category: .ui)
    }
    
    /// 测试 ShareService 协议实现
    func testShareService_协议实现() {
        AppLog("开始测试 ShareService 协议实现", level: .debug, category: .ui)
        
        XCTAssertNotNil(shareService as? ShareServiceProtocol, "ShareService 应该实现 ShareServiceProtocol")
        
        AppLog("ShareService 协议实现测试完成", level: .debug, category: .ui)
    }
    
    // MARK: - Image Generation Tests
    
    /// 测试图片生成 - 有图片
    func testGenerateShareImage_有图片() async {
        AppLog("开始测试 generateShareImage - 有图片", level: .debug, category: .ui)
        
        let shareImage = await shareService.generateShareImage(from: testFormula, image: testImage)
        
        XCTAssertNotNil(shareImage, "应该成功生成分享图片")
        if let shareImage = shareImage {
            XCTAssertGreaterThan(shareImage.size.width, 0, "图片宽度应该大于0")
            XCTAssertGreaterThan(shareImage.size.height, 0, "图片高度应该大于0")
            AppLog("生成的分享图片尺寸: \(shareImage.size)", level: .debug, category: .ui)
        }
        
        AppLog("generateShareImage - 有图片测试完成", level: .debug, category: .ui)
    }
    
    /// 测试图片生成 - 无图片
    func testGenerateShareImage_无图片() async {
        AppLog("开始测试 generateShareImage - 无图片", level: .debug, category: .ui)
        
        let shareImage = await shareService.generateShareImage(from: testFormula, image: nil)
        
        XCTAssertNotNil(shareImage, "即使没有图片也应该生成分享图片")
        if let shareImage = shareImage {
            XCTAssertGreaterThan(shareImage.size.width, 0, "图片宽度应该大于0")
            XCTAssertGreaterThan(shareImage.size.height, 0, "图片高度应该大于0")
            AppLog("生成的分享图片尺寸: \(shareImage.size)", level: .debug, category: .ui)
        }
        
        AppLog("generateShareImage - 无图片测试完成", level: .debug, category: .ui)
    }
    
    /// 测试图片生成 - 带图片路径
    func testGenerateShareImage_带图片路径() async {
        AppLog("开始测试 generateShareImage - 带图片路径", level: .debug, category: .ui)
        
        // 创建带图片路径的Formula
        var formulaWithPath = testFormula!
        formulaWithPath.imgpath = "test-image-path"
        
        let shareImage = await shareService.generateShareImage(from: formulaWithPath, image: nil)
        
        // 即使图片路径不存在，也应该能生成分享图片（使用占位图）
        XCTAssertNotNil(shareImage, "应该能生成分享图片")
        if let shareImage = shareImage {
            XCTAssertGreaterThan(shareImage.size.width, 0, "图片宽度应该大于0")
            XCTAssertGreaterThan(shareImage.size.height, 0, "图片高度应该大于0")
        }
        
        AppLog("generateShareImage - 带图片路径测试完成", level: .debug, category: .ui)
    }
    
    /// 测试图片生成 - 复杂菜谱内容
    func testGenerateShareImage_复杂菜谱内容() async {
        AppLog("开始测试 generateShareImage - 复杂菜谱内容", level: .debug, category: .ui)
        
        let complexFormula = Formula(
            name: "复杂测试菜谱名称很长的那种",
            ingredients: Ingredients(
                mainIngredients: Array(1...5).map { Ingredient(name: "主料\($0)", quantity: "\($0 * 10)g", category: nil) },
                spicesSeasonings: Array(1...3).map { Ingredient(name: "配料\($0)", quantity: "适量", category: nil) },
                sauce: Array(1...2).map { SauceIngredient(name: "蛸料\($0)", quantity: "\($0)勺") }
            ),
            tools: Array(1...4).map { Tool(name: "厨具\($0)") },
            preparation: Array(1...3).map { PreparationStep(step: "准备步骤\($0)", details: "这是一个比较长的准备步骤描述，用来测试长文本的显示效果\($0)") },
            steps: Array(1...5).map { CookingStep(step: "料理步骤\($0)", details: "这是一个详细的料理步骤描述，包含了很多细节和注意事项\($0)") },
            tips: Array(1...3).map { "这是一个详细的小窍门，帮助大家更好地完成这道菜\($0)" },
            tags: ["复杂", "测试", "标签1", "标签2", "标签3"],
            date: Date(),
            prompt: nil,
            state: .finish,
            imgpath: nil,
            isCuisine: false
        )
        
        let shareImage = await shareService.generateShareImage(from: complexFormula, image: testImage)
        
        XCTAssertNotNil(shareImage, "应该成功生成复杂菜谱的分享图片")
        if let shareImage = shareImage {
            XCTAssertGreaterThan(shareImage.size.width, 0, "图片宽度应该大于0")
            XCTAssertGreaterThan(shareImage.size.height, 0, "图片高度应该大于0")
            AppLog("复杂菜谱分享图片尺寸: \(shareImage.size)", level: .debug, category: .ui)
        }
        
        AppLog("generateShareImage - 复杂菜谱内容测试完成", level: .debug, category: .ui)
    }
    
    /// 测试图片生成 - 空内容菜谱
    func testGenerateShareImage_空内容菜谱() async {
        AppLog("开始测试 generateShareImage - 空内容菜谱", level: .debug, category: .ui)
        
        let minimalFormula = Formula(
            name: "简单菜谱",
            ingredients: Ingredients(
                mainIngredients: [],
                spicesSeasonings: [],
                sauce: []
            ),
            tools: [],
            preparation: [],
            steps: [CookingStep(step: "简单步骤", details: "简单描述")],
            tips: [],
            tags: [],
            date: Date(),
            prompt: nil,
            state: .finish,
            imgpath: nil,
            isCuisine: false
        )
        
        let shareImage = await shareService.generateShareImage(from: minimalFormula, image: nil)
        
        XCTAssertNotNil(shareImage, "即使内容很少也应该生成分享图片")
        if let shareImage = shareImage {
            XCTAssertGreaterThan(shareImage.size.width, 0, "图片宽度应该大于0")
            XCTAssertGreaterThan(shareImage.size.height, 0, "图片高度应该大于0")
        }
        
        AppLog("generateShareImage - 空内容菜谱测试完成", level: .debug, category: .ui)
    }
    
    // MARK: - Photo Library Permission Tests
    
    /// 测试相册权限请求
    func testRequestPhotoLibraryPermission() async {
        AppLog("开始测试 requestPhotoLibraryPermission", level: .debug, category: .ui)
        
        let hasPermission = await shareService.requestPhotoLibraryPermission()
        
        // 权限结果可能是true或false，取决于用户授权状态
        AppLog("相册权限状态: \(hasPermission)", level: .debug, category: .ui)
        
        // 只验证方法能正常执行，不验证具体结果
        // 因为权限状态取决于系统设置
        
        AppLog("requestPhotoLibraryPermission 测试完成", level: .debug, category: .ui)
    }
    
    // MARK: - Photo Library Save Tests
    
    /// 测试保存图片到相册 - 有权限的情况
    func testSaveImageToPhotoLibrary_有权限() async {
        AppLog("开始测试 saveImageToPhotoLibrary - 有权限", level: .debug, category: .ui)
        
        // 先请求权限
        let hasPermission = await shareService.requestPhotoLibraryPermission()
        
        if hasPermission {
            do {
                try await shareService.saveImageToPhotoLibrary(testImage)
                AppLog("成功保存图片到相册", level: .debug, category: .ui)
                // 如果没有抛出异常，说明保存成功
            } catch {
                AppLog("保存图片到相册失败: \(error)", level: .error, category: .ui)
                XCTFail("在有权限的情况下保存图片失败: \(error)")
            }
        } else {
            AppLog("没有相册权限，跳过保存测试", level: .warning, category: .ui)
            // 没有权限时，跳过这个测试
        }
        
        AppLog("saveImageToPhotoLibrary - 有权限测试完成", level: .debug, category: .ui)
    }
    
    // MARK: - ShareError Tests
    
    /// 测试 ShareError 错误类型
    func testShareError_错误类型() {
        AppLog("开始测试 ShareError 错误类型", level: .debug, category: .ui)
        
        let imageGenerationError = ShareError.imageGenerationFailed
        let saveError = ShareError.saveToPhotoLibraryFailed
        let permissionError = ShareError.permissionDenied
        
        XCTAssertEqual(imageGenerationError.errorDescription, "图片生成失败")
        XCTAssertEqual(saveError.errorDescription, "保存到相册失败")
        XCTAssertEqual(permissionError.errorDescription, "没有相册访问权限")
        
        AppLog("ShareError 错误类型测试完成", level: .debug, category: .ui)
    }
    
    // MARK: - Integration Tests
    
    /// 测试完整的分享流程
    func testCompleteShareFlow() async {
        AppLog("开始测试完整的分享流程", level: .debug, category: .ui)
        
        // 1. 生成分享图片
        let shareImage = await shareService.generateShareImage(from: testFormula, image: testImage)
        XCTAssertNotNil(shareImage, "应该成功生成分享图片")
        
        guard let shareImage = shareImage else {
            XCTFail("分享图片生成失败")
            return
        }
        
        // 2. 请求相册权限
        let hasPermission = await shareService.requestPhotoLibraryPermission()
        AppLog("相册权限状态: \(hasPermission)", level: .debug, category: .ui)
        
        // 3. 如果有权限，尝试保存图片
        if hasPermission {
            do {
                try await shareService.saveImageToPhotoLibrary(shareImage)
                AppLog("完整分享流程测试成功", level: .debug, category: .ui)
            } catch {
                AppLog("保存分享图片失败: \(error)", level: .error, category: .ui)
                XCTFail("保存分享图片失败: \(error)")
            }
        } else {
            AppLog("没有相册权限，完整流程测试部分完成", level: .warning, category: .ui)
        }
        
        AppLog("完整的分享流程测试完成", level: .debug, category: .ui)
    }
    
    // MARK: - Performance Tests
    
    /// 测试图片生成性能
    func testGenerateShareImage_性能测试() {
            AppLog("开始测试 generateShareImage 性能", level: .debug, category: .ui)
        
        measure {
            let expectation = XCTestExpectation(description: "图片生成性能测试")
            
            Task {
                let shareImage = await shareService.generateShareImage(from: testFormula, image: testImage)
                XCTAssertNotNil(shareImage, "应该成功生成分享图片")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
        
            AppLog("generateShareImage 性能测试完成", level: .debug, category: .ui)
    }
    
    /// 测试批量图片生成
    func testBatchImageGeneration() async {
        AppLog("开始测试批量图片生成", level: .debug, category: .ui)
        
        let batchSize = 3
        var generatedImages: [UIImage] = []
        
        for i in 0..<batchSize {
            var batchFormula = testFormula!
            batchFormula.name = "批量测试菜谱 \(i + 1)"
            
            if let shareImage = await shareService.generateShareImage(from: batchFormula, image: testImage) {
                generatedImages.append(shareImage)
            }
        }
        
        XCTAssertEqual(generatedImages.count, batchSize, "应该成功生成所有批量图片")
        AppLog("成功生成 \(generatedImages.count) 个分享图片", level: .debug, category: .ui)
        
        AppLog("批量图片生成测试完成", level: .debug, category: .ui)
    }
}