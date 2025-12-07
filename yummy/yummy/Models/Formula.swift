//
//  Formula.swift
//  yummy
//
//  Created by steve on 2025/6/21.
//

import Foundation
import SwiftUI

// MARK: - Formula
struct Formula: Codable, Identifiable, Equatable, Hashable {
    var id: String = UUID().uuidString
    
    // MARK: - 基本字段
    var name: String
    /// 触发生成时用户输入的原始文案，重试时复用
    var prompt: String?
    let ingredients: Ingredients
    let tools: [Tool]
    let preparation: [PreparationStep]
    let steps: [CookingStep]
    let tips: [String]
    let tags: [String]
    let date: Date
    var state: FormulaState
    var imgpath: String?
    var isCuisine: Bool = false
    
    // 为了匹配 JSON 的 key，需要实现 CodingKeys
    enum CodingKeys: String, CodingKey {
        case name
        case ingredients
        case tools
        case preparation
        case steps
        case tips
        case tags
        case date
        case imgpath
        case isCuisine
    }
    
    // 日期格式化器（用于 JSON 编解码）
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        return formatter
    }()
    
    // 自定义解码初始化方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        ingredients = try container.decode(Ingredients.self, forKey: .ingredients)
        tools = try container.decode([Tool].self, forKey: .tools)
        preparation = try container.decode([PreparationStep].self, forKey: .preparation)
        steps = try container.decode([CookingStep].self, forKey: .steps)
        tips = try container.decode([String].self, forKey: .tips)
        tags = try container.decode([String].self, forKey: .tags)
        
        // 如果 JSON 中没有 date 字段，使用当前日期作为默认值
        // if let dateString = try container.decodeIfPresent(String.self, forKey: .date),
        //    let parsedDate = Formula.dateFormatter.date(from: dateString) {
        //     date = parsedDate
        // } else {
        date = DateFormatterUtility.currentDate()
        state = .loading
        prompt = nil
        imgpath = try container.decodeIfPresent(String.self, forKey: .imgpath)
        isCuisine = try container.decodeIfPresent(Bool.self, forKey: .isCuisine) ?? false
        // }
    }
    
    // 手动实现编码方法以确保兼容性
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(tools, forKey: .tools)
        try container.encode(preparation, forKey: .preparation)
        try container.encode(steps, forKey: .steps)
        try container.encode(tips, forKey: .tips)
        try container.encode(tags, forKey: .tags)
        try container.encode(Formula.dateFormatter.string(from: date), forKey: .date)
        try container.encodeIfPresent(imgpath, forKey: .imgpath)
        try container.encode(isCuisine, forKey: .isCuisine)
    }
    
    // 手动初始化方法（用于创建 mock 数据等）
    init(name: String, ingredients: Ingredients, tools: [Tool], preparation: [PreparationStep], steps: [CookingStep], tips: [String], tags: [String], date: Date, prompt: String? = nil, state: FormulaState, imgpath: String? = nil, isCuisine: Bool = false) {
        self.name = name
        self.ingredients = ingredients
        self.tools = tools
        self.preparation = preparation
        self.steps = steps
        self.tips = tips
        self.tags = tags
        self.date = date
        self.prompt = prompt
        self.state = state
        self.imgpath = imgpath
        self.isCuisine = isCuisine
    }
    
    static var mock: Formula {
        return Formula(
            name: "老母鸡汤",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "老母鸡", quantity: "1只", category: "畜禽肉类"),
                    Ingredient(name: "甜玉米", quantity: "1根", category: "谷薯杂豆类"),
                    Ingredient(name: "胡萝卜", quantity: "1根", category: "蔬菜类"),
                    Ingredient(name: "干莲子", quantity: "30克", category: "谷薯杂豆类"),
                    Ingredient(name: "枸杞", quantity: "10克", category: "蔬菜类"),
                    Ingredient(name: "干百合", quantity: "20克", category: "蔬菜类")
                ],
                spicesSeasonings: [
                    Ingredient(name: "生姜", quantity: "几片", category: nil),
                    Ingredient(name: "大葱", quantity: "几段", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "老抽", quantity: "少许"),
                    SauceIngredient(name: "熬油", quantity: "适量"),
                    SauceIngredient(name: "鸡精", quantity: "适量"),
                    SauceIngredient(name: "淀粉", quantity: "一大勺")
                ]
            ),
            tools: [
                Tool(name: "案板"),
                Tool(name: "刀"),
                Tool(name: "厨房剪刀"),
                Tool(name: "锅"),
                Tool(name: "砂锅")
            ],
            preparation: [
                PreparationStep(step: "鸡的处理", details: "剪掉鸡的饺子剪掉鸡的饺子剪掉鸡的饺子剪掉鸡的饺子剪掉鸡的饺子剪掉鸡的饺子剪掉鸡的饺子"),
                PreparationStep(step: "焯水", details: "用冷水下锅..."),
                PreparationStep(step: "配料准备", details: "准备甜玉米...")
            ],
            steps: [
                CookingStep(step: "炒鸡块", details: "锅中加油..."),
                CookingStep(step: "加水炖煮", details: "添加开水..."),
                CookingStep(step: "砂锅炖煮", details: "将鸡块...")
            ],
            tips: [
                "老母鸡不需要焯水...",
                "焯水时不要使用料酒...",
                "炖鸡汤时加开水...",
                "盐要最后放...",
                "枸杞不耐高温..."
            ],
            tags: [
                "汤类",
                "滋补",
                "家常菜"
            ],
            date: DateFormatterUtility.currentDate(),
            prompt: "示例 prompt",
            state: .finish,
            imgpath: nil
        )
    }
    
    static var mockFinish: Formula {
        var formula = Formula(
            name: "美式牛肉汉堡",
            ingredients: Ingredients(
                mainIngredients: [
                    Ingredient(name: "牛肉馅", quantity: "一斤", category: "畜禽肉类"),
                    Ingredient(name: "洋葱", quantity: "1个", category: "蔬菜类"),
                    Ingredient(name: "鸡蛋", quantity: "1个", category: "蛋类"),
                    Ingredient(name: "番茄", quantity: "2片", category: "蔬菜类"),
                    Ingredient(name: "生菜", quantity: "1片", category: "蔬菜类"),
                    Ingredient(name: "芝士", quantity: "2片", category: "奶制品"),
                    Ingredient(name: "面包", quantity: "1个", category: "谷物制品")
                ],
                spicesSeasonings: [
                    Ingredient(name: "料酒", quantity: "适量", category: nil),
                    Ingredient(name: "生抽", quantity: "适量", category: nil),
                    Ingredient(name: "黑胡椒", quantity: "多多", category: nil)
                ],
                sauce: [
                    SauceIngredient(name: "秘制汉堡酱", quantity: "适量")
                ]
            ),
            tools: [
                Tool(name: "案板"),
                Tool(name: "刀"),
                Tool(name: "锅"),
                Tool(name: "铲子")
            ],
            preparation: [
                PreparationStep(step: "鸡的处理", details: "剪掉鸡的饺子，切掉鸡的屁股，去掉鸡脖子的皮，抠干净腔内残余的内脏，把鸡剁成块，用清水清洗干净"),
                PreparationStep(step: "配料准备", details: "准备甜玉米、胡萝卜、干莲子、枸杞、干百合等食材，确保食材新鲜，无变质，便于炖煮出美味的鸡汤")
            ],
            steps: [
                CookingStep(step: "焯水", details: "用冷水下锅，加入几片生姜和几段大葱，煮沸后打去浮沫，煮3分钟，捞出鸡块，用温水清洗干净，去除腥味"),
                CookingStep(step: "炒鸡块", details: "锅中加油，下入生姜片和大葱段煸炒出香味，加入鸡块翻炒至表面微微焦黄，散发出浓郁的香味，使鸡肉更加入味"),
                CookingStep(step: "加水炖煮", details: "加入开水，大火煮沸后大火煮5分钟，再转小火煮10分钟，盖上盖子继续炖煮，使鸡肉的鲜味充分释放"),
                CookingStep(step: "加入配料炖煮", details: "加入甜玉米、胡萝卜、干莲子、枸杞、干百合等配料，继续炖煮，使食材的味道充分融合"),
                CookingStep(step: "调味", details: "根据个人口味，加入适量的盐，确保盐放得适时，使鸡肉的鲜味更加突出")
            ],
            tips: [
                "牛肉选择好一些的部位...",
                "汉堡包要选择松软的...",
                "蔬菜要新鲜..."
            ],
            tags: [
                "老母鸡汤",
                "老母鸡汤",
                "老母鸡汤"
            ],
            date: DateFormatterUtility.currentDate(),
            prompt: "示例 prompt",
            state: .finish,
            imgpath: "images/formula_65144521-A58A-4B60-AE3E-EAF2D92E41D9_1753353411.jpg" // 添加一个测试图片路径
        )
        // 设置固定的 ID，确保预览中的数据匹配
        formula.id = "mock-finish-formula-id"
        return formula
    }
    
    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Ingredients
struct Ingredients: Codable, Equatable, Hashable {
    let mainIngredients: [Ingredient]
    let spicesSeasonings: [Ingredient]
    let sauce: [SauceIngredient]

    // 为了匹配 JSON 的 key，需要实现 CodingKeys
    enum CodingKeys: String, CodingKey {
        case mainIngredients = "main-ingredients"
        case spicesSeasonings = "spices-seasonings"
        case sauce
    }

    // 自定义解码，兼容 sauce 字段返回 [[]] 的情况
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 主料 & 香料可以缺省 -> 默认为空数组
        mainIngredients = (try? container.decode([Ingredient].self, forKey: .mainIngredients)) ?? []
        spicesSeasonings = (try? container.decode([Ingredient].self, forKey: .spicesSeasonings)) ?? []

        // sauce 可能是 []、[{}] 或 [[]]
        if let directSauce = try? container.decode([SauceIngredient].self, forKey: .sauce) {
            sauce = directSauce
        } else if let nestedSauce = try? container.decode([[SauceIngredient]].self, forKey: .sauce) {
            // 将嵌套数组拍平成一维
            sauce = nestedSauce.flatMap { $0 }
        } else {
            sauce = []
        }
    }
    
    // 为单元测试 / mock 数据提供成员初始化器
    init(mainIngredients: [Ingredient] = [],
         spicesSeasonings: [Ingredient] = [],
         sauce: [SauceIngredient] = []) {
        self.mainIngredients = mainIngredients
        self.spicesSeasonings = spicesSeasonings
        self.sauce = sauce
    }
}

// MARK: - Ingredient
struct Ingredient: Codable, Equatable, Hashable {
    let name: String
    let quantity: String
    let category: String? // category 字段现在是可选的
}

// MARK: - Tool
struct Tool: Codable, Equatable, Hashable {
    let name: String
}

// MARK: - PreparationStep
struct PreparationStep: Codable, Equatable, Hashable {
    let step: String
    let details: String
}

// MARK: - CookingStep
struct CookingStep: Codable, Equatable, Hashable {
    let step: String
    let details: String
}

// MARK: - SauceIngredient
struct SauceIngredient: Codable, Equatable, Hashable {
    let name: String
    let quantity: String
}

// MARK: - 业务流程状态
/// 统一的菜谱生成流程状态，伴随一条记录完整生命周期
enum FormulaState: Int16, Codable, Hashable {
    case loading = 0     // 正在生成
    case upload  = 1     // 生成完成，等待上传封面
    case finish  = 2     // 封面上传完毕
    case error   = 3     // 生成或上传失败，可重试
}

