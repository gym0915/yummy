import Foundation
import CoreData

// Core Data 栈单例，负责加载 `FormulaContainer` 数据模型并提供上下文。
final class CoreDataStack {
    // MARK: - Singleton
    static let shared = CoreDataStack()
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FormulaContainer")
        if inMemory {
            // 单元测试时使用内存存储
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 为持久化存储描述添加自动迁移配置，允许 Core Data 自动推断映射模型并执行轻量级迁移
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("❌ Core Data 加载失败: \(error.localizedDescription)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Properties
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    /// 创建后台线程 `NSManagedObjectContext`，用于写操作。
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
} 
