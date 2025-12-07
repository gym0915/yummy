import XCTest
import UIKit
@testable import yummy

// 仅用于本测试文件：一个会在保存图片时抛错的相机服务 Mock，避免与共享 Mock 冲突
final class FailingCameraServiceMock: CameraServiceProtocol {
    func checkCameraPermission() async -> Bool { true }
    func requestCameraPermission() async -> Bool { true }
    func requestPhotoLibraryPermission() async -> Bool { true }
    func saveImageToDocuments(_ image: UIImage, fileName: String) throws -> String {
        throw MockError.uploadFailed
    }
}

// MARK: - 测试类
final class ImageUploadServiceTests: XCTestCase {
    var mockCameraService: MockCameraService!
    var mockFormulaRepository: MockFormulaRepository!
    var service: ImageUploadService!
    var testFormula: Formula!
    var testImage: UIImage!

    override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService()
        mockFormulaRepository = MockFormulaRepository()
        service = ImageUploadService(cameraService: mockCameraService, formulaRepository: mockFormulaRepository)
        testFormula = createTestFormula(name: "测试菜谱")
        testImage = createTestImage()
    }

    override func tearDown() {
        mockCameraService = nil
        mockFormulaRepository = nil
        service = nil
        testFormula = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - 正常流程
    func testUploadImageForFormula_success() async throws {
        let result = try await service.uploadImageForFormula(testFormula, image: testImage)
        XCTAssertNotNil(result.imgpath)
        XCTAssertTrue(result.imgpath?.hasPrefix("test-images/") == true)
        XCTAssertEqual(result.state, .finish)
        XCTAssertTrue(mockFormulaRepository.saveCalled, "应保存更新后的 Formula 到仓库")
    }

    // MARK: - 图片保存失败（相机服务抛错）
    func testUploadImageForFormula_imageSaveFail() async {
        let failingCamera = FailingCameraServiceMock()
        let service = ImageUploadService(cameraService: failingCamera, formulaRepository: mockFormulaRepository)
        do {
            _ = try await service.uploadImageForFormula(testFormula, image: testImage)
            XCTFail("应当抛出图片保存异常")
        } catch {
            // 服务在失败时会尝试保存 error 状态（try? save）
            XCTAssertTrue(mockFormulaRepository.saveCalled, "失败时应尝试持久化 error 状态")
        }
    }

    // MARK: - 数据库保存失败（仓库 save 抛错）
    func testUploadImageForFormula_dbSaveFail() async {
        mockFormulaRepository.shouldReturnSuccess = false
        do {
            _ = try await service.uploadImageForFormula(testFormula, image: testImage)
            XCTFail("应当抛出数据库保存异常")
        } catch {
            // 首次 save 抛错后，服务会将状态置为 error 并 try? 再次保存
            XCTAssertTrue(mockFormulaRepository.saveCalled, "数据库保存失败时应调用过 save")
        }
    }
}
