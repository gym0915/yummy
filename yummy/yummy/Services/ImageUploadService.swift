import UIKit
import Foundation

// MARK: - 图片上传服务协议
protocol ImageUploadServiceProtocol {
    /// 上传图片并更新 Formula 数据
    func uploadImageForFormula(_ formula: Formula, image: UIImage) async throws -> Formula
}

// MARK: - 图片上传服务实现
final class ImageUploadService: ImageUploadServiceProtocol {
    
    // 依赖注入
    private let cameraService: CameraServiceProtocol
    private let formulaRepository: FormulaRepositoryProtocol
    
    // 单例
    static let shared = ImageUploadService(
        cameraService: CameraService.shared,
        formulaRepository: FormulaRepository.shared
    )
    
    init(cameraService: CameraServiceProtocol, formulaRepository: FormulaRepositoryProtocol) {
        self.cameraService = cameraService
        self.formulaRepository = formulaRepository
    }
    
    // MARK: - 主要功能
    func uploadImageForFormula(_ formula: Formula, image: UIImage) async throws -> Formula {
        AppLog("📸 [图片上传] 开始处理封面上传 - ID: \(formula.id), 名称: \(formula.name)", category: .image)
        AppLog("📊 [图片上传] 当前状态: \(stateDescription(formula.state))", category: .image)
        
        do {
            // 1. 生成唯一的文件名
            let fileName = generateFileName(for: formula)
            AppLog("📂 [图片上传] 生成文件名: \(fileName)", level: .debug, category: .image)
            
            // 2. 保存图片到本地文件系统
            AppLog("💾 [图片上传] 开始保存图片到本地文件系统...", category: .image)
            let imagePath = try cameraService.saveImageToDocuments(image, fileName: fileName)
            AppLog("✅ [图片上传] 图片保存成功 - 路径: \(imagePath)", category: .image)
            
            // 3. 更新 Formula 数据
            var updatedFormula = formula
            updatedFormula.imgpath = imagePath
            updatedFormula.state = .finish // 图片上传完成，状态变为 finish
            
            AppLog("🏁 [状态变更] \(formula.id) - \(formula.name): upload -> finish", category: .image)
            
            // 4. 保存到 CoreData
            AppLog("💾 [图片上传] 保存更新到数据库...", category: .image)
            try await formulaRepository.save(updatedFormula)
            
            AppLog("🎉 [图片上传] 封面上传完成 - ID: \(formula.id), 名称: \(formula.name)", category: .image)
            AppLog("📁 [图片上传] 最终图片路径: \(imagePath)", level: .debug, category: .image)
            
            return updatedFormula
            
        } catch {
            AppLog("❌ [图片上传] 上传失败 - ID: \(formula.id), 错误: \(error.localizedDescription)", level: .error, category: .image)
            AppLog("❌ [状态变更] \(formula.id) - \(formula.name): \(formula.state) -> error (上传失败)", level: .error, category: .image)
            
            // 将状态设置为错误
            var errorFormula = formula
            errorFormula.state = .error
            try? await formulaRepository.save(errorFormula)
            
            throw error
        }
    }
    
    // MARK: - 私有方法
    private func generateFileName(for formula: Formula) -> String {
        // 使用 formula.id 和当前时间戳生成唯一文件名
        let timestamp = Int(Date().timeIntervalSince1970)
        return "formula_\(formula.id)_\(timestamp).jpg"
    }
    
    // MARK: - 辅助方法
    private func stateDescription(_ state: FormulaState) -> String {
        switch state {
        case .loading:
            return "loading (正在生成)"
        case .upload:
            return "upload (生成完成，等待上传封面)"
        case .finish:
            return "finish (封面上传完毕)"
        case .error:
            return "error (生成或上传失败)"
        }
    }
}