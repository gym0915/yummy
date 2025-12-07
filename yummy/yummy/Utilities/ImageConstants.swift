import UIKit

// MARK: - 图片尺寸常量
enum ImageConstants {
    
    // MARK: - 比例常量
    /// 图片标准比例 3:4 (宽:高)
    static let aspectRatio: CGFloat = 3.0 / 4.0
    
    // MARK: - 屏幕尺寸相关
    /// 屏幕宽度
    static let screenWidth = UIScreen.main.bounds.width
    
    /// 水平边距
    static let horizontalPadding: CGFloat = 16
    
    // MARK: - DetailView 图片尺寸
    /// DetailView finish状态图片高度 (全屏宽度 * 4/3)
    static let detailFinishImageHeight = screenWidth * 4 / 3
    
    /// DetailView 其他状态图片高度 (去除边距后的宽度 * 4/3)
    static let detailNormalImageHeight = (screenWidth - horizontalPadding * 2) * 4 / 3
    
    // MARK: - HomeCardView 图片尺寸
    /// HomeCardView 图片宽度 (两列布局：屏幕宽度 - 左右边距32pt - 中间间距16pt，再除以2)
    static let homeCardImageWidth = (screenWidth - 48) / 2
    
    /// HomeCardView 图片高度 (根据3:4比例计算)
    static let homeCardImageHeight = homeCardImageWidth * 4 / 3
    
    // MARK: - ImageUploadView 图片尺寸
    /// ImageUploadView上传区域高度
    static let uploadViewHeight = screenWidth * 4 / 3
} 