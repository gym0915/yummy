import Foundation
import os.log

/// 统一日志管理器，基于 os.Logger 的现代化日志系统
/// 支持级别控制、模块分类、大数据截断与 DEBUG/RELEASE 策略
@MainActor
final class AppLogger {
    
    // MARK: - 日志级别
    enum LogLevel: Int, CaseIterable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case critical = 4
        
        var name: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARN"
            case .error: return "ERROR"
            case .critical: return "CRITICAL"
            }
        }
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔧"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🔥"
            }
        }
    }
    
    // MARK: - 日志分类
    enum Category: String, CaseIterable {
        case general = "General"
        case network = "Network"
        case ui = "UI"
        case service = "Service"
        case viewmodel = "ViewModel"
        case coredata = "CoreData"
        case camera = "Camera"
        case image = "Image"
        case share = "Share"
        case notification = "Notification"
        case formula = "Formula"
        case cuisine = "Cuisine"
        case app = "App"
        
        var emoji: String {
            switch self {
            case .general: return "📱"
            case .network: return "🌐"
            case .ui: return "🎨"
            case .service: return "⚙️"
            case .viewmodel: return "🧠"
            case .coredata: return "💾"
            case .camera: return "📸"
            case .image: return "🖼️"
            case .share: return "📤"
            case .notification: return "📱"
            case .formula: return "🍳"
            case .cuisine: return "🥘"
            case .app: return "🌅"
            }
        }
    }
    
    // MARK: - 配置
    static let shared = AppLogger()
    
    /// 最小日志级别，低于此级别的日志将被忽略
    private var minimumLogLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }()
    
    /// 是否启用日志输出
    private var isLoggingEnabled: Bool = true
    
    /// 大数据截断阈值（字节）
    private let maxLogDataSize: Int = 2048
    
    /// 截断提示文本长度
    private let truncateIndicatorLength: Int = 100
    
    private let subsystem = "com.yummy.app"
    private var loggers: [Category: Logger] = [:]
    
    // MARK: - 初始化
    private init() {
        setupLoggers()
    }
    
    private func setupLoggers() {
        for category in Category.allCases {
            loggers[category] = Logger(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - 配置方法
    
    /// 设置最小日志级别
    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }
    
    /// 启用或禁用日志
    func setLoggingEnabled(_ enabled: Bool) {
        isLoggingEnabled = enabled
    }
    
    // MARK: - 核心日志方法
    
    /// 记录日志
    /// - Parameters:
    ///   - level: 日志级别
    ///   - category: 日志分类
    ///   - message: 消息内容
    ///   - function: 调用函数名
    ///   - file: 调用文件名
    ///   - line: 调用行号
    func log(
        level: LogLevel,
        category: Category = .general,
        _ message: @autoclosure () -> String,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        guard isLoggingEnabled && level.rawValue >= minimumLogLevel.rawValue else {
            return
        }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let processedMessage = processMessage(message())
        let logText = "\(level.emoji) [\(category.emoji) \(category.rawValue)] \(processedMessage)"
        
        guard let logger = loggers[category] else {
            // 回退到系统日志
            os_log("%{public}@", log: OSLog.default, type: level.osLogType, logText)
            return
        }
        
        // 使用对应的 os.Logger
        switch level {
        case .debug:
            logger.debug("\(logText, privacy: .public)")
        case .info:
            logger.info("\(logText, privacy: .public)")
        case .warning:
            logger.warning("\(logText, privacy: .public)")
        case .error:
            logger.error("\(logText, privacy: .public)")
        case .critical:
            logger.critical("\(logText, privacy: .public)")
        }
    }
    
    // MARK: - 便捷方法
    
    func debug(_ message: @autoclosure () -> String, category: Category = .general, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .debug, category: category, message(), function: function, file: file, line: line)
    }
    
    func info(_ message: @autoclosure () -> String, category: Category = .general, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .info, category: category, message(), function: function, file: file, line: line)
    }
    
    func warning(_ message: @autoclosure () -> String, category: Category = .general, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .warning, category: category, message(), function: function, file: file, line: line)
    }
    
    func error(_ message: @autoclosure () -> String, category: Category = .general, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .error, category: category, message(), function: function, file: file, line: line)
    }
    
    func critical(_ message: @autoclosure () -> String, category: Category = .general, function: String = #function, file: String = #file, line: Int = #line) {
        log(level: .critical, category: category, message(), function: function, file: file, line: line)
    }
    
    // MARK: - 数据处理
    
    /// 处理消息内容，包括大数据截断
    private func processMessage(_ message: String) -> String {
        guard message.utf8.count > maxLogDataSize else {
            return message
        }
        
        // 计算截断位置
        let truncateAt = maxLogDataSize - truncateIndicatorLength
        let truncatedMessage = String(message.prefix(truncateAt))
        let remaining = message.utf8.count - truncateAt
        
        return "\(truncatedMessage)... (截断 \(remaining) 字节)"
    }
    
    // MARK: - 特殊用途方法
    
    /// 记录大量数据（如 JSON）的摘要
    func logDataSummary(
        _ data: Data,
        description: String,
        category: Category = .general,
        level: LogLevel = .debug
    ) {
        let size = data.count
        let summary = "数据摘要: \(description), 大小: \(size) 字节"
        
        if size <= 1024 {
            // 小数据直接显示
            if let string = String(data: data, encoding: .utf8) {
                log(level: level, category: category, "\(summary) - 内容: \(string)")
            } else {
                log(level: level, category: category, "\(summary) - 二进制数据")
            }
        } else {
            // 大数据只显示摘要
            log(level: level, category: category, summary)
        }
    }
    
    /// 记录 JSON 对象的摘要
    func logJSONSummary(
        _ object: Any,
        description: String,
        category: Category = .general,
        level: LogLevel = .debug
    ) {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            logDataSummary(data, description: "\(description) (JSON)", category: category, level: level)
        } catch {
            log(level: .error, category: category, "无法序列化JSON: \(description) - \(error)")
        }
    }
    
    /// 记录对象状态变化
    func logStateChange(
        _ description: String,
        from oldState: String,
        to newState: String,
        category: Category = .general
    ) {
        info("\(description): \(oldState) -> \(newState)", category: category)
    }
    
    /// 记录性能计时
    func logTiming(
        _ description: String,
        duration: TimeInterval,
        category: Category = .general
    ) {
        let formattedDuration = String(format: "%.3f", duration)
        info("⏱️ \(description): \(formattedDuration)s", category: category)
    }
}

// MARK: - 全局便捷函数

/// 全局日志函数，用于快速迁移现有的 print 调用
func AppLog(
    _ message: @autoclosure () -> String,
    level: AppLogger.LogLevel = .info,
    category: AppLogger.Category = .general,
    function: String = #function,
    file: String = #file,
    line: Int = #line
) {
    // 先在当前上下文计算消息文本，避免在逃逸闭包中捕获非逃逸的 @autoclosure 参数（Swift 6 严格并发）
    let evaluatedMessage = message()
    // 为了兼容在非主线程/非隔离上下文中的调用，这里将日志调度到 MainActor 执行，
    // 以避免对 @MainActor 隔离的 AppLogger 进行越界访问
    Task { @MainActor in
        AppLogger.shared.log(
            level: level,
            category: category,
            evaluatedMessage,
            function: function,
            file: file,
            line: line
        )
    }
}

/// 全局便捷函数：记录二进制数据摘要（避免直接在非隔离上下文调用 @MainActor 方法）
func AppLogDataSummary(
    _ data: Data,
    description: String,
    category: AppLogger.Category = .general,
    level: AppLogger.LogLevel = .debug
) {
    Task { @MainActor in
        AppLogger.shared.logDataSummary(
            data,
            description: description,
            category: category,
            level: level
        )
    }
}

/// 全局便捷函数：记录 JSON 对象摘要（避免直接在非隔离上下文调用 @MainActor 方法）
func AppLogJSONSummary(
    _ object: Any,
    description: String,
    category: AppLogger.Category = .general,
    level: AppLogger.LogLevel = .debug
) {
    Task { @MainActor in
        AppLogger.shared.logJSONSummary(
            object,
            description: description,
            category: category,
            level: level
        )
    }
}