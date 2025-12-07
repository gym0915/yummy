//
//  CameraViewModel.swift
//  yummy
//
//  Created by steve on 2025/8/1.
//

import Foundation
import SwiftUI
//import UIKit

@MainActor
class CameraViewModel: ObservableObject {
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?
    @Published var isUploading = false
    
    private let cameraService: CameraServiceProtocol
    private let imageUploadService: ImageUploadServiceProtocol
    private let formulaRepository: FormulaRepositoryProtocol
    
    init(
        cameraService: CameraServiceProtocol = CameraService.shared,
        imageUploadService: ImageUploadServiceProtocol = ImageUploadService.shared,
        formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared
    ) {
        self.cameraService = cameraService
        self.imageUploadService = imageUploadService
        self.formulaRepository = formulaRepository
    }
    
    func handleImagePicked(_ image: UIImage, formula: Formula, completion: @escaping () -> Void) {
        Task {
            await uploadImage(image, formula: formula, completion: completion)
        }
    }
    
    private func uploadImage(_ image: UIImage, formula: Formula, completion: @escaping () -> Void) async {
        isUploading = true
        clearError()
        
        do {
            let updatedFormula = try await imageUploadService.uploadImageForFormula(formula, image: image)
            // 保存更新后的 Formula 到数据库
            try await formulaRepository.save(updatedFormula)
            isUploading = false
            completion()
        } catch {
            setError("图片保存失败：\(error.localizedDescription)")
            isUploading = false
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
    }
    
    func clearError() {
        errorMessage = nil
    }
}
