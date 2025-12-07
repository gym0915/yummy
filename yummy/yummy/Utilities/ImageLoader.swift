import UIKit
import Foundation

// MARK: - 图片加载工具
final class ImageLoader {
    
    // 单例
    static let shared = ImageLoader()
    private init() {}
    
    // 内存缓存
    private let cache = NSCache<NSString, UIImage>()
    
    // MARK: - 从相对路径加载图片
    func loadImage(from relativePath: String) -> UIImage? {
        AppLog("📂 [ImageLoader] 开始加载图片: \(relativePath)", level: .debug, category: .image)
        
        // 先检查缓存
        if let cachedImage = cache.object(forKey: relativePath as NSString) {
            AppLog("📂 [ImageLoader] 从缓存获取图片成功", level: .info, category: .image)
            return cachedImage
        }
        
        AppLog("📂 [ImageLoader] 缓存中未找到图片，从文件系统加载", level: .debug, category: .image)
        
        // 从文件系统加载
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            AppLog("❌ [ImageLoader] 无法获取Documents目录", level: .error, category: .image)
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(relativePath)
        AppLog("📂 [ImageLoader] 完整文件路径: \(fileURL.path)", level: .debug, category: .image)
        
        // 检查文件是否存在
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        AppLog("📂 [ImageLoader] 文件是否存在: \(fileExists)", level: .debug, category: .image)
        
        guard let imageData = try? Data(contentsOf: fileURL) else {
            AppLog("❌ [ImageLoader] 无法读取文件数据", level: .error, category: .image)
            return nil
        }
        
        AppLog("📂 [ImageLoader] 文件数据大小: \(imageData.count) bytes", level: .debug, category: .image)
        
        guard let image = UIImage(data: imageData) else {
            AppLog("❌ [ImageLoader] 无法从数据创建UIImage", level: .error, category: .image)
            return nil
        }
        
        AppLog("📂 [ImageLoader] 成功创建UIImage，尺寸: \(image.size), scale: \(image.scale)", level: .info, category: .image)
        
        // 缓存图片
        cache.setObject(image, forKey: relativePath as NSString)
        AppLog("📂 [ImageLoader] 图片已缓存", level: .debug, category: .image)
        
        return image
    }
    
    // MARK: - 清理缓存
    func clearCache() {
        cache.removeAllObjects()
    }
}