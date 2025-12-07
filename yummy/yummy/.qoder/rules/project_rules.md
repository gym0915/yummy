---
trigger: always_on
alwaysApply: true
---
Aways response in 中文

这是一个 iOS 开发项目
项目使用 SwiftUI 开发
使用的是 iOS 18 版本，模拟器使用iPhone 16 Pro (OS 18.5) 进行编译
如果要编译需要访问上级目录，/Users/steve/AppleDev/Yummy/yummy 
测试时使用 yummyTests 这个 scheme 来执行测试
每次修改代码都不要破坏以前的代码规范，在现有代码基础上进行修改
如需要输出日志，请使用 AppLog 进行打印，日志等级为 debug
如需要输出错误日志，请使用 AppLog 进行打印，日志等级为 error
如需要输出警告日志，请使用 AppLog 进行打印，日志等级为 warning
如需要输出信息日志，请使用 AppLog 进行打印，日志等级为 info
如需要输出 verbose 日志，请使用 AppLog 进行打印，日志等级为 verbose
如需要输出网络请求日志，请使用 AppLog 进行打印，日志等级为 network
如需要输出数据库日志，请使用 AppLog 进行打印，日志等级为 database
如需要输出 UI 日志，请使用 AppLog 进行打印，日志等级为 ui
如需要输出性能日志，请使用 AppLog 进行打印，日志等级为 performance

# 项目结构和编码规范

本项目遵循 MVVM (Model-View-ViewModel) 架构模式及扩展模式。

## 目录结构

- **Core**: 包含项目核心代码。此文件夹下按页面组织，如 Home、Launch、Settings、Detail 等，每个页面内部包含 Views (界面文件)、ViewModels (连接 View 和 Model 的中间代码文件)。Components 文件夹存放界面中可重用的组件。
- **Extensions**: 存放对现有类型（如各种数据类型、UI 元素等）进行功能扩展的代码，以增强其能力或提供便捷方法。
- **Service**: 存放处理数据获取、API 调用以及与其他外部服务交互的代码。这部分代码负责数据的获取和处理，供 ViewModel 使用。
- **Utilities**: 存放项目中各处可能用到的通用工具类、函数或常量，例如日期格式化、数据验证、常用的计算方法等。
- **Models**: 存放应用程序中使用的数据结构定义，通常是结构体 (struct) 或类 (class)，用于表示应用程序的数据模型。


# 编码规范

本项目遵循以下编码规范：

## 命名规范

- **总体原则**: 遵循驼峰命名规范 (camelCase)。

- **变量**: 使用小写开头的驼峰命名。例如：`userName`, `dataList`, `isLoading`。

- **常量**: 对于局部常量或实例常量，使用小写开头的驼峰命名 (`let` 关键字)。对于全局常量或类型常量，可以使用小写开头的驼峰命名或更明确的名称。例如：`let maxCount = 10`, `static let defaultTimeout = 30`。

- **函数/方法**: 使用小写开头的驼峰命名。例如：`fetchData()`, `updateUI()`, `handleTap(at: index:)`。

- **类/结构体/枚举/协议**: 使用大写开头的驼峰命名 (PascalCase)。例如：`UserModel`, `CryptoCurrency`, `APIError`, `DataFetching`。

- **文件名**: 通常与其中定义的类型或主要内容同名，并遵循相应的命名规范 (PascalCase)。例如：`UserModel.swift`, `DataService.swift`, `HomeView.swift`。

## 编写代码要求

- **可选类型处理**: 优先使用安全的 unwrapping 方式来处理可选类型，例如：
    - `if let` 或 `guard let` 进行条件绑定。
    - `??` (nil-coalescing operator) 提供默认值。
- **避免强制解包**: 除非在能确保可选类型一定有值的极少数情况下，应避免使用 `!` 进行强制解包。强制解包可能导致运行时崩溃 (crash)。

## 代码格式

（如果需要，可以在这里添加关于代码缩进、空格、换行等的规则）

## 设计原则

- **单一职责原则（SRP）**：每个类/结构体/文件只负责一项功能，保持代码高内聚低耦合。
- **开放封闭原则（OCP）**：通过协议和扩展实现功能扩展，避免直接修改已有代码。
- **依赖倒置原则（DIP）**：高层模块不依赖底层模块，二者都依赖于抽象（协议），如 ViewModel 依赖 Service 层接口。
- **接口隔离原则（ISP）**：接口设计尽量精细，避免"胖接口"，如主题协议只定义主题相关属性。
- **面向协议编程（POP）**：优先使用协议定义行为和接口，提升灵活性和可测试性。
- **组合优于继承**：通过结构体、协议和扩展组合功能，减少继承层级。
- **值类型优先**：数据模型多采用 struct，保证数据安全和简洁。
- **弱引用和内存管理**：在闭包中使用 [weak self]，防止循环引用和内存泄漏。
-**闭包中的弱引用**：
    - 当闭包（尤其是逃逸闭包 `@escaping`）需要捕获 `self` 时，为避免造成循环引用（Retain Cycle），应优先使用 `[weak self]` 或 `[unowned self]`。
    - 对于使用 `[weak self]` 捕获的 `self`，在使用前应通过 `guard let self = self else { return }` 进行安全解包。