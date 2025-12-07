import UIKit
import AVFoundation
import Photos

// MARK: - 相机服务协议
protocol CameraServiceProtocol {
    /// 检查相机权限
    func checkCameraPermission() async -> Bool
    /// 请求相机权限
    func requestCameraPermission() async -> Bool
    /// 请求相册权限
    func requestPhotoLibraryPermission() async -> Bool
    /// 保存图片到应用目录并返回相对路径
    func saveImageToDocuments(_ image: UIImage, fileName: String) throws -> String
}

// MARK: - 相机服务实现
final class CameraService: CameraServiceProtocol {
    
    // 单例
    static let shared = CameraService()
    private init() {}
    
    // MARK: - 权限检查
    func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    // MARK: - 权限请求
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - 图片保存
    func saveImageToDocuments(_ image: UIImage, fileName: String) throws -> String {
        // 获取 Documents 目录
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CameraError.documentsDirectoryNotFound
        }
        
        // 创建 images 子目录（如果不存在）
        let imagesDirectory = documentsDirectory.appendingPathComponent("images")
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
        
        // 创建完整的文件路径
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        // 在保存前对过大的原图进行像素级缩放，避免后续读取及渲染的内存问题
        let targetPixelWidth: CGFloat = 1200
        var imageToSave = image
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        AppLog("🗜️ [CameraService] 原图像素尺寸: \(Int(pixelWidth))x\(Int(pixelHeight)) (scale=\(image.scale))", level: .debug, category: .camera)
        if pixelWidth > targetPixelWidth, let scaled = image.scaledTo(pixelWidth: targetPixelWidth) {
            let newW = scaled.size.width * scaled.scale
            let newH = scaled.size.height * scaled.scale
            AppLog("📉 [CameraService] 已缩放图片至: \(Int(newW))x\(Int(newH)) (scale=\(scaled.scale))", category: .camera)
            imageToSave = scaled
        } else {
            AppLog("ℹ️ [CameraService] 无需缩放（目标宽度: \(Int(targetPixelWidth))px）", level: .debug, category: .camera)
        }
        
        // 将图片转换为 JPEG 数据（压缩质量 0.8）
        guard let imageData = imageToSave.jpegData(compressionQuality: 0.8) else {
            throw CameraError.imageConversionFailed
        }
        
        // 保存文件
        try imageData.write(to: fileURL)
        
        // 返回相对路径（相对于 Documents 目录）
        return "images/\(fileName)"
    }
}

// MARK: - 错误定义
enum CameraError: LocalizedError {
    case documentsDirectoryNotFound
    case imageConversionFailed
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .documentsDirectoryNotFound:
            return "无法找到文档目录"
        case .imageConversionFailed:
            return "图片转换失败"
        case .permissionDenied:
            return "相机权限被拒绝"
        }
    }
}

// MARK: - UIImage 缩放辅助（仅 CameraService 内部使用）
private extension UIImage {
    /// 按目标像素宽度等比缩放图片
    func scaledTo(pixelWidth targetPixelWidth: CGFloat) -> UIImage? {
        let currentPixelWidth = size.width * scale
        let currentPixelHeight = size.height * scale
        guard currentPixelWidth > 0, currentPixelHeight > 0, targetPixelWidth > 0 else { return nil }
        let ratio = targetPixelWidth / currentPixelWidth
        let targetSizeInPoints = CGSize(width: size.width * ratio, height: size.height * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        // 使用1.0的渲染scale，让像素宽度≈points宽度
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSizeInPoints, format: format)
        let result = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSizeInPoints))
        }
        return result
    }
}