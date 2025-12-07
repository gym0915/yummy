import Foundation
import Combine
import CoreData

// MARK: - 协议
protocol FormulaRepositoryProtocol {
    var formulasPublisher: AnyPublisher<[Formula], Never> { get }
    /// 同步返回当前所有 Formula（读取 CurrentValueSubject）
    func all() -> [Formula]
    func save(_ formula: Formula) async throws
    func update(_ formula: Formula) async throws
    func delete(id: String) async throws
}

// MARK: - 实现
final class FormulaRepository: NSObject, FormulaRepositoryProtocol {

    // 共享单例
    static let shared = FormulaRepository()

    // 发布器
    private let subject = CurrentValueSubject<[Formula], Never>([])
    var formulasPublisher: AnyPublisher<[Formula], Never> { subject.eraseToAnyPublisher() }

    // MARK: - 同步获取全部记录
    func all() -> [Formula] {
        subject.value
    }

    // FRC 监听 Core Data 更新
    private let fetchedResultsController: NSFetchedResultsController<FormulaEntity>

    private override init() {
        // Fetch Request
        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            let formulas = (fetchedResultsController.fetchedObjects ?? []).compactMap { $0.toModel() }
            subject.value = formulas
            AppLog("📚 [FormulaRepository] 初始化完成，加载了 \(formulas.count) 条菜谱记录", category: .coredata)
        } catch {
            AppLog("⚠️ [FormulaRepository] 初始 fetch 失败: \(error)", level: .warning, category: .coredata)
        }
    }

    // MARK: - Public CRUD
    func save(_ formula: Formula) async throws {
        let context = CoreDataStack.shared.newBackgroundContext()
        try await context.perform {
            // 尝试查找是否已存在同 id 的记录
            let request: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", formula.id)
            let encoder = JSONEncoder()

            if let existing = try context.fetch(request).first {
                // 更新已有记录
                let oldState = FormulaState(rawValue: existing.state) ?? .loading
                let newState = formula.state
                
                existing.name = formula.name
                existing.date = formula.date
                existing.state = formula.state.rawValue
                existing.prompt = formula.prompt
                existing.imgpath = formula.imgpath
                existing.isCuisine = formula.isCuisine
                existing.ingredients = try? encoder.encode(formula.ingredients)
                existing.tools       = try? encoder.encode(formula.tools)
                existing.preparation = try? encoder.encode(formula.preparation)
                existing.steps       = try? encoder.encode(formula.steps)
                existing.tips        = try? encoder.encode(formula.tips)
                existing.tags        = try? encoder.encode(formula.tags)
                
                if oldState != newState {
                    AppLog("📝 [FormulaRepository] 状态更新 - ID: \(formula.id), 名称: \(formula.name)", category: .coredata)
                    AppLog("📝 [FormulaRepository] 状态变更: \(self.stateDescription(oldState)) -> \(self.stateDescription(newState))", category: .coredata)
                } else {
                    AppLog("📝 [FormulaRepository] 记录更新 - ID: \(formula.id), 名称: \(formula.name), 状态: \(self.stateDescription(newState))", category: .coredata)
                }
            } else {
                // 不存在则插入新记录
                FormulaEntity.from(model: formula, in: context)
                AppLog("➕ [FormulaRepository] 新记录创建 - ID: \(formula.id), 名称: \(formula.name), 状态: \(self.stateDescription(formula.state))", category: .coredata)
            }
            try context.save()
        }
    }

    func update(_ formula: Formula) async throws {
        let context = CoreDataStack.shared.newBackgroundContext()
        try await context.perform {
            // 查找现有记录
            let request: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", formula.id)
            
            guard let existing = try context.fetch(request).first else {
                AppLog("⚠️ [FormulaRepository] 更新失败 - 未找到 ID: \(formula.id) 的记录", category: .coredata)
                throw NSError(domain: "FormulaRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "未找到要更新的记录"])
            }
            
            let encoder = JSONEncoder()
            let oldState = FormulaState(rawValue: existing.state) ?? .loading
            let newState = formula.state
            
            // 更新所有字段
            existing.name = formula.name
            existing.date = formula.date
            existing.state = formula.state.rawValue
            existing.prompt = formula.prompt
            existing.imgpath = formula.imgpath
            existing.isCuisine = formula.isCuisine
            existing.ingredients = try? encoder.encode(formula.ingredients)
            existing.tools       = try? encoder.encode(formula.tools)
            existing.preparation = try? encoder.encode(formula.preparation)
            existing.steps       = try? encoder.encode(formula.steps)
            existing.tips        = try? encoder.encode(formula.tips)
            existing.tags        = try? encoder.encode(formula.tags)
            
            try context.save()
            
            if oldState != newState {
                AppLog("📝 [FormulaRepository] 记录更新（状态变更） - ID: \(formula.id), 名称: \(formula.name)", category: .coredata)
                AppLog("📝 [FormulaRepository] 状态变更: \(self.stateDescription(oldState)) -> \(self.stateDescription(newState))", category: .coredata)
            } else {
                AppLog("📝 [FormulaRepository] 记录更新 - ID: \(formula.id), 名称: \(formula.name), 状态: \(self.stateDescription(newState))", category: .coredata)
            }
        }
    }

    func delete(id: String) async throws {
        let context = CoreDataStack.shared.newBackgroundContext()
        try await context.perform {
            let request: NSFetchRequest<FormulaEntity> = FormulaEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            if let obj = try context.fetch(request).first {
                let formulaName = obj.name ?? "未知"
                context.delete(obj)
                try context.save()
                AppLog("🗑️ [FormulaRepository] 记录删除 - ID: \(id), 名称: \(formulaName)", category: .coredata)
            }
        }
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

// MARK: - NSFetchedResultsControllerDelegate
extension FormulaRepository: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let objects = controller.fetchedObjects as? [FormulaEntity] else { return }
        let formulas = objects.compactMap { $0.toModel() }
        subject.send(formulas)
        AppLog("🔄 [FormulaRepository] 数据变更通知发送，当前总数: \(formulas.count)", category: .coredata)
    }
}
