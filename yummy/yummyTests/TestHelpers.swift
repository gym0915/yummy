//
//  TestHelpers.swift
//  yummyTests
//
//  Created by Qoder on 2025/09/17.
//

import XCTest
import UIKit
import Combine
@testable import yummy

// MARK: - 共享Mock类

/// 模拟FormulaRepository
class MockFormulaRepository: FormulaRepositoryProtocol {
    var mockFormulas: [Formula] = []
    private let formulasSubject = PassthroughSubject<[Formula], Never>()
    
    var updateCalled = false
    var saveCalled = false
    var shouldReturnSuccess = true
    var shouldThrowError = false
    var updateError: Error?
    var mockError: Error?
    
    var formulasPublisher: AnyPublisher<[Formula], Never> {
        formulasSubject.eraseToAnyPublisher()
    }
    
    func all() -> [Formula] {
        return mockFormulas
    }
    
    func formula(withId id: String) -> Formula? {
        return mockFormulas.first { $0.id == id }
    }
    
    func updateFormula(_ formula: Formula) {
        if let index = mockFormulas.firstIndex(where: { $0.id == formula.id }) {
            mockFormulas[index] = formula
        } else {
            mockFormulas.append(formula)
        }
        sendFormulasUpdate()
    }
    
    func sendFormulasUpdate() {
        formulasSubject.send(mockFormulas)
    }
    
    func update(_ formula: Formula) async throws {
        updateCalled = true
        
        if shouldThrowError {
            throw updateError ?? MockError.updateFailed
        }
        
        updateFormula(formula)
    }
    
    func save(_ formula: Formula) async throws {
        saveCalled = true
        
        if !shouldReturnSuccess {
            throw mockError ?? MockError.saveFailed
        }
        
        updateFormula(formula)
    }
    
    func delete(id: String) async throws {
        mockFormulas.removeAll { $0.id == id }
        sendFormulasUpdate()
    }
    
    func clearAll() async throws {
        mockFormulas.removeAll()
        sendFormulasUpdate()
    }
    
    func reset() {
        mockFormulas.removeAll()
        updateCalled = false
        saveCalled = false
        shouldReturnSuccess = true
        shouldThrowError = false
        updateError = nil
        mockError = nil
        sendFormulasUpdate()
    }
}

/// 模拟CameraService
class MockCameraService: CameraServiceProtocol {
    var cameraPermissionResult = true
    var photoLibraryPermissionResult = true
    var requestCameraPermissionCalled = false
    var requestPhotoLibraryPermissionCalled = false
    
    func checkCameraPermission() async -> Bool {
        return cameraPermissionResult
    }
    
    func requestCameraPermission() async -> Bool {
        requestCameraPermissionCalled = true
        return cameraPermissionResult
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        requestPhotoLibraryPermissionCalled = true
        return photoLibraryPermissionResult
    }
    
    func saveImageToDocuments(_ image: UIImage, fileName: String) throws -> String {
        return "test-images/\(fileName)"
    }
}

/// 模拟ImageUploadService
class MockImageUploadService: ImageUploadServiceProtocol {
    var shouldReturnSuccess = true
    var uploadImageCalled = false
    var mockUpdatedFormula: Formula?
    var mockError: Error?
    
    func uploadImageForFormula(_ formula: Formula, image: UIImage) async throws -> Formula {
        uploadImageCalled = true
        
        if shouldReturnSuccess {
            return mockUpdatedFormula ?? formula
        } else {
            throw mockError ?? MockError.uploadFailed
        }
    }
}

/// 模拟CuisineStateRepository
class MockCuisineStateRepository: CuisineStateRepositoryProtocol {
    
    // MARK: - Tracking Properties
    var saveCalled = false
    var deleteTabStatusesCalled = false
    var createTabStatusCalled = false
    var createTabStatusesCalled = false
    var shouldThrowError = false
    
    var lastSavedStatus: CuisineTabStatus?
    var lastDeletedFormulaId: String?
    
    // MARK: - Publisher
    private let subject = CurrentValueSubject<[CuisineTabStatus], Never>([])
    var cuisineTabStatusesPublisher: AnyPublisher<[CuisineTabStatus], Never> {
        subject.eraseToAnyPublisher()
    }
    
    // MARK: - Methods
    
    func load() -> [CuisineTabStatus] {
        return subject.value
    }
    
    func save(_ status: CuisineTabStatus) async throws {
        if shouldThrowError {
            throw MockError.saveFailed
        }
        
        saveCalled = true
        lastSavedStatus = status
        
        // 更新内部状态
        var currentStatuses = subject.value
        if let index = currentStatuses.firstIndex(where: { 
            $0.formulaId == status.formulaId && $0.tabType == status.tabType 
        }) {
            currentStatuses[index] = status
        } else {
            currentStatuses.append(status)
        }
        subject.send(currentStatuses)
    }
    
    func getTabStatus(formulaId: String, tab: CuisineTab) -> CuisineTabStatus? {
        return subject.value.first { $0.formulaId == formulaId && $0.tabType == tab }
    }
    
    func createTabStatuses(from formula: Formula) async throws {
        if shouldThrowError {
            throw MockError.createFailed
        }
        
        createTabStatusesCalled = true
        
        var current = subject.value
        for tab in CuisineTab.allCases {
            if !current.contains(where: { $0.formulaId == formula.id && $0.tabType == tab }) {
                let status = CuisineTabStatus(
                    formulaId: formula.id,
                    formulaName: formula.name,
                    tabType: tab,
                    items: []
                )
                current.append(status)
            }
        }
        subject.send(current)
    }
    
    func createTabStatus(from formula: Formula, tabType: CuisineTab) async throws {
        if shouldThrowError {
            throw MockError.createFailed
        }
        
        createTabStatusCalled = true
        
        var current = subject.value
        if !current.contains(where: { $0.formulaId == formula.id && $0.tabType == tabType }) {
            let status = CuisineTabStatus(
                formulaId: formula.id,
                formulaName: formula.name,
                tabType: tabType,
                items: []
            )
            current.append(status)
            subject.send(current)
        }
    }
    
    func deleteTabStatuses(formulaId: String) async throws {
        if shouldThrowError {
            throw MockError.deleteFailed
        }
        
        deleteTabStatusesCalled = true
        lastDeletedFormulaId = formulaId
        
        // 从内部状态中移除
        let filteredStatuses = subject.value.filter { $0.formulaId != formulaId }
        subject.send(filteredStatuses)
    }
    
    // MARK: - Helper Methods
    
    func publishTabStatuses(_ statuses: [CuisineTabStatus]) {
        subject.send(statuses)
    }
    
    func reset() {
        saveCalled = false
        deleteTabStatusesCalled = false
        createTabStatusCalled = false
        createTabStatusesCalled = false
        shouldThrowError = false
        lastSavedStatus = nil
        lastDeletedFormulaId = nil
        subject.send([])
    }
}

/// 测试错误类型
enum MockError: Error, LocalizedError {
    case updateFailed
    case saveFailed
    case uploadFailed
    case networkError
    case unknownError
    case createFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .updateFailed:
            return "更新失败"
        case .saveFailed:
            return "保存失败"
        case .uploadFailed:
            return "图片上传失败"
        case .networkError:
            return "网络错误"
        case .unknownError:
            return "未知错误"
        case .createFailed:
            return "创建失败"
        case .deleteFailed:
            return "删除失败"
        }
    }
}

// MARK: - 测试工具方法

extension XCTestCase {
    
    /// 创建测试用的Formula
    func createTestFormula(id: String = UUID().uuidString, name: String = "Test Formula") -> Formula {
        return Formula(
            name: name,
            ingredients: Ingredients(),
            tools: [],
            preparation: [],
            steps: [],
            tips: [],
            tags: [],
            date: Date(),
            state: .loading
        )
    }
    
    /// 创建详细测试用的Formula（用于DetailViewModel测试）
    func createDetailTestFormula(id: String = UUID().uuidString, name: String = "测试详情菜谱") -> Formula {
        var formula = Formula(
            name: name,
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "主料1", quantity: "100g", category: nil)
                ],
                spicesSeasonings: [
                    Ingredient(name: "配料1", quantity: "适量", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "蘸料1", quantity: "1勺")
                ]
            ),
            tools: [Tool(name: "平底锅")],
            preparation: [PreparationStep(step: "准备1", details: "准备步骤1")],
            steps: [CookingStep(step: "料理1", details: "料理步骤1")],
            tips: ["小贴士1"],
            tags: ["测试", "详情"],
            date: Date(),
            prompt: nil,
            state: .finish,
            imgpath: "test-image-path.jpg",
            isCuisine: false
        )
        formula.id = id
        return formula
    }
    
    /// 创建测试用的图片
    func createTestImage(size: CGSize = CGSize(width: 100, height: 100), color: UIColor = .blue) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    /// 创建测试用的CuisineTabStatus
    func createTestTabStatus(formulaId: String = "test-formula", 
                             tabType: CuisineTab = .procurement) -> CuisineTabStatus {
        let testItems = [
            CuisineListItem(
                formulaId: formulaId,
                formulaName: "测试菜谱",
                title: "测试项目1",
                subtitle: "100g",
                type: .ingredient,
                originalIndex: 0
            ),
            CuisineListItem(
                formulaId: formulaId,
                formulaName: "测试菜谱",
                title: "测试项目2",
                subtitle: "200g",
                type: .ingredient,
                originalIndex: 1
            )
        ]
        
        return CuisineTabStatus(
            formulaId: formulaId,
            formulaName: "测试菜谱",
            tabType: tabType,
            items: testItems
        )
    }
}

// MARK: - 扩展方法

extension Formula {
    func withCuisineStatus(_ isCuisine: Bool) -> Formula {
        var formula = self
        formula.isCuisine = isCuisine
        return formula
    }
}

// MARK: - 工具函数

/// 重置Mock状态
func resetMockStates() {
    // 如果需要重置Mock状态，可以在这里实现
}