import Foundation
import CoreData

extension FormulaEntity {
    /// 将 Core Data 实体转换为业务模型 `Formula`（基于属性级映射）。
    func toModel() -> Formula? {
        // 必要字段校验
        guard
            let id = self.id,
            let name = self.name,
            let ingredientsData = self.ingredients,
            let toolsData = self.tools,
            let preparationData = self.preparation,
            let stepsData = self.steps,
            let tipsData = self.tips,
            let tagsData = self.tags
        else {
            return nil
        }

        let decoder = JSONDecoder()
        do {
            let ingredients = try decoder.decode(Ingredients.self, from: ingredientsData)
            let tools = try decoder.decode([Tool].self, from: toolsData)
            let preparation = try decoder.decode([PreparationStep].self, from: preparationData)
            let steps = try decoder.decode([CookingStep].self, from: stepsData)
            let tips = try decoder.decode([String].self, from: tipsData)
            let tags = try decoder.decode([String].self, from: tagsData)

            var formula = Formula(
                name: name,
                ingredients: ingredients,
                tools: tools,
                preparation: preparation,
                steps: steps,
                tips: tips,
                tags: tags,
                date: self.date ?? Date(),
                prompt: self.prompt,
                state: FormulaState(rawValue: self.state) ?? .loading,
                imgpath: self.imgpath,
                isCuisine: self.isCuisine
            )
            formula.id = id
            return formula
        } catch {
            AppLog("⚠️ FormulaEntity → Formula 解码失败: \(error)", level: .warning, category: .coredata)
            return nil
        }
    }

    /// 根据业务模型构建新的 `FormulaEntity` 并插入到指定 `NSManagedObjectContext` 中（属性级映射）。
    /// - Parameters:
    ///   - model: 业务层 `Formula`
    ///   - ctx: `NSManagedObjectContext`
    static func from(model: Formula, in ctx: NSManagedObjectContext) {
        let entity = FormulaEntity(context: ctx)
        entity.id = model.id
        entity.name = model.name
        entity.date = model.date
        entity.state = model.state.rawValue
        entity.prompt = model.prompt

        let encoder = JSONEncoder()
        entity.ingredients = try? encoder.encode(model.ingredients)
        entity.tools = try? encoder.encode(model.tools)
        entity.preparation = try? encoder.encode(model.preparation)
        entity.steps = try? encoder.encode(model.steps)
        entity.tips = try? encoder.encode(model.tips)
        entity.tags = try? encoder.encode(model.tags)
        entity.imgpath = model.imgpath
        entity.isCuisine = model.isCuisine
    }

    // MARK: - State ↔︎ Int16 映射 已由 FormulaState.rawValue 直接完成，无需额外方法
    
    // MARK: - 子元素数组操作支持
    
    /// 更新主料数组
    func updateMainIngredients(_ ingredients: [Ingredient]) {
        guard let currentIngredients = getCurrentIngredients() else { return }
        let newIngredients = Ingredients(
            mainIngredients: ingredients,
            spicesSeasonings: currentIngredients.spicesSeasonings,
            sauce: currentIngredients.sauce
        )
        updateIngredients(newIngredients)
    }
    
    /// 更新配料调料数组
    func updateSpicesSeasonings(_ ingredients: [Ingredient]) {
        guard let currentIngredients = getCurrentIngredients() else { return }
        let newIngredients = Ingredients(
            mainIngredients: currentIngredients.mainIngredients,
            spicesSeasonings: ingredients,
            sauce: currentIngredients.sauce
        )
        updateIngredients(newIngredients)
    }
    
    /// 更新蘸料数组
    func updateSauce(_ sauce: [SauceIngredient]) {
        guard let currentIngredients = getCurrentIngredients() else { return }
        let newIngredients = Ingredients(
            mainIngredients: currentIngredients.mainIngredients,
            spicesSeasonings: currentIngredients.spicesSeasonings,
            sauce: sauce
        )
        updateIngredients(newIngredients)
    }
    
    /// 更新厨具数组
    func updateTools(_ tools: [Tool]) {
        let encoder = JSONEncoder()
        self.tools = try? encoder.encode(tools)
        AppLog("🔧 [FormulaEntity] 厨具数组已更新，共 \(tools.count) 项", category: .coredata)
    }
    
    /// 更新准备步骤数组
    func updatePreparation(_ preparation: [PreparationStep]) {
        let encoder = JSONEncoder()
        self.preparation = try? encoder.encode(preparation)
        AppLog("📋 [FormulaEntity] 准备步骤数组已更新，共 \(preparation.count) 项", category: .coredata)
    }
    
    /// 更新烹饪步骤数组
    func updateSteps(_ steps: [CookingStep]) {
        let encoder = JSONEncoder()
        self.steps = try? encoder.encode(steps)
        AppLog("👨‍🍳 [FormulaEntity] 烹饪步骤数组已更新，共 \(steps.count) 项", category: .coredata)
    }
    
    /// 更新技巧数组
    func updateTips(_ tips: [String]) {
        let encoder = JSONEncoder()
        self.tips = try? encoder.encode(tips)
        AppLog("💡 [FormulaEntity] 技巧数组已更新，共 \(tips.count) 项", category: .coredata)
    }
    
    /// 更新标签数组
    func updateTags(_ tags: [String]) {
        let encoder = JSONEncoder()
        self.tags = try? encoder.encode(tags)
        AppLog("🏷️ [FormulaEntity] 标签数组已更新，共 \(tags.count) 项", category: .coredata)
    }
    
    // MARK: - 私有辅助方法
    
    /// 获取当前的 Ingredients 对象
    private func getCurrentIngredients() -> Ingredients? {
        guard let ingredientsData = self.ingredients else {
            AppLog("⚠️ [FormulaEntity] 无法获取当前 ingredients 数据", level: .warning, category: .coredata)
            return nil
        }
        
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Ingredients.self, from: ingredientsData)
        } catch {
            AppLog("⚠️ [FormulaEntity] ingredients 解码失败: \(error)", level: .warning, category: .coredata)
            return nil
        }
    }
    
    /// 更新 Ingredients 对象
    private func updateIngredients(_ ingredients: Ingredients) {
        let encoder = JSONEncoder()
        do {
            self.ingredients = try encoder.encode(ingredients)
            AppLog("🥬 [FormulaEntity] Ingredients 已更新", category: .coredata)
        } catch {
            AppLog("⚠️ [FormulaEntity] ingredients 编码失败: \(error)", level: .warning, category: .coredata)
        }
    }
}
