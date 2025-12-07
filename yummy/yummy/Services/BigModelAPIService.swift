import Foundation

enum BigModelAPIError: Error {
    case invalidURL
    case requestFailed(String)
    case invalidResponse
    case decodingFailed(Error)
    case noData
}

class BigModelAPIService {
    func callAPI(apiKey: String, modelName: String, prompt: String) async throws -> Formula {
        AppLog("🔑 [大模型API] API Key: \(String(apiKey.prefix(10)))...", level: .debug, category: .network)
        AppLog("🤖 [大模型API] 模型名称: \(modelName)", level: .debug, category: .network)
        AppLog("📝 [大模型API] 用户输入: \(prompt)", level: .debug, category: .network)
        
        guard let url = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions") else {
            AppLog("❌ [大模型API] URL无效", level: .error, category: .network)
            throw BigModelAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": modelName,
            "messages": [
                [
                    "role": "system",
                    "content": PromptConstants.systemPrompt
                ],
                [
                "role": "user",
                "content": prompt
                ]
            ],
            "top_p": 0.95,
            "temperature": 0.6,
            "max_tokens": 16384,
            "thinking": [
                "type": "auto"
            ],
            "tools": [
                [
                    "type": "web_search",
                    "web_search": [
                        "search_result": true,
                        "search_engine": "search-std"
                    ]
                ]
            ],
            "stream": false
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            AppLog("❌ [大模型API] 创建请求体失败", level: .error, category: .network)
            throw BigModelAPIError.requestFailed("创建请求体失败")
        }
        request.httpBody = httpBody

        // 请求详情日志
        AppLog("🌐 [大模型API] 开始发送请求到: \(url.absoluteString)", level: .debug, category: .network)
        AppLog("📊 [大模型API] 请求参数 - 模型: \(modelName), top_p: 0.7, temperature: 0.95, max_tokens: 16384", level: .debug, category: .network)
        if let _ = String(data: httpBody, encoding: .utf8) {
            AppLog("📤 [大模型API] 请求体大小: \(httpBody.count) bytes", level: .debug, category: .network)
            await MainActor.run { AppLogger.shared.logDataSummary(httpBody, description: "大模型API 请求体", category: .network, level: .debug) }
        }

        do {
            AppLog("⏳ [大模型API] 等待服务器响应...", level: .debug, category: .network)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                AppLog("❌ [大模型API] 响应格式无效", level: .error, category: .network)
                throw BigModelAPIError.invalidResponse
            }

            // 响应状态日志
            AppLog("📡 [大模型API] 收到响应 - 状态码: \(httpResponse.statusCode)", level: .debug, category: .network)
            AppLog("📥 [大模型API] 响应数据大小: \(data.count) bytes", level: .debug, category: .network)
            await MainActor.run { AppLogger.shared.logDataSummary(data, description: "大模型API 响应体", category: .network, level: .debug) }
            
            if let responseString = String(data: data, encoding: .utf8) {
                AppLog("📄 [大模型API] 响应内容预览: \(String(responseString.prefix(200)))...", level: .debug, category: .network)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                AppLog("❌ [大模型API] 请求失败 - 状态码: \(httpResponse.statusCode)", level: .error, category: .network)
                await MainActor.run { AppLogger.shared.logDataSummary(data, description: "错误响应体", category: .network, level: .error) }
                if let errorString = String(data: data, encoding: .utf8) {
                    AppLog("❌ [大模型API] 错误详情: \(errorString)", level: .error, category: .network)
                    throw BigModelAPIError.requestFailed("请求失败，状态码: \(httpResponse.statusCode), 错误信息: \(errorString)")
                } else {
                    AppLog("❌ [大模型API] 请求失败 - 状态码: \(httpResponse.statusCode)，无错误详情", level: .error, category: .network)
                    throw BigModelAPIError.requestFailed("请求失败，状态码: \(httpResponse.statusCode)")
                }
            }
            
            AppLog("✅ [大模型API] 请求成功，开始解析响应数据...", level: .info, category: .network)
            
            // 首先解析大模型的响应格式，提取出真正的 JSON 内容
            do {
                guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    AppLog("❌ [大模型API] JSON解析失败 - 响应不是有效的 JSON 对象", level: .error, category: .network)
                    await MainActor.run { AppLogger.shared.logDataSummary(data, description: "原始响应体", category: .network, level: .error) }
                    throw BigModelAPIError.decodingFailed(NSError(domain: "InvalidJSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "响应不是有效的 JSON 对象"]))
                }
                
                guard let choices = jsonObject["choices"] as? [[String: Any]], 
                      let firstChoice = choices.first,
                      let message = firstChoice["message"] as? [String: Any],
                      let content = message["content"] as? String else {
                    AppLog("❌ [大模型API] 响应结构解析失败 - 无法提取 content 字段", level: .error, category: .network)
                    throw BigModelAPIError.decodingFailed(NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法从响应中提取 content 字段"]))
                }
                
                AppLog("✅ [大模型API] 成功提取内容，长度: \(content.count) 字符", level: .debug, category: .network)
                AppLog("📋 [大模型API] 内容预览: \(String(content.prefix(100)))...", level: .debug, category: .network)
                
                // 从 content 字符串中提取 JSON 部分（去掉 ```json 和 ``` 包装）
                let jsonString: String
                if content.contains("```json") {
                    // 处理 markdown 格式的 JSON
                    let components = content.components(separatedBy: "```json")
                    if components.count > 1 {
                        let jsonPart = components[1].components(separatedBy: "```")[0]
                        jsonString = jsonPart.trimmingCharacters(in: .whitespacesAndNewlines)
                        AppLog("🔧 [大模型API] 从 Markdown 格式中提取 JSON", level: .debug, category: .network)
                    } else {
                        jsonString = content
                    }
                } else {
                    jsonString = content
                }
                
                AppLog("📝 [大模型API] 准备解析的 JSON 长度: \(jsonString.count) 字符", level: .debug, category: .network)
                
                // 将 JSON 字符串转换为 Data
                guard let jsonData = jsonString.data(using: .utf8) else {
                    AppLog("❌ [大模型API] JSON 转换失败 - 无法将字符串转换为 Data", level: .error, category: .network)
                    throw BigModelAPIError.decodingFailed(NSError(domain: "InvalidJSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法将 JSON 字符串转换为 Data"]))
                }
                
                // 解码为 Formula 对象
                AppLog("🔄 [大模型API] 开始将 JSON 解码为 Formula 对象...", level: .debug, category: .network)
                let decoder = JSONDecoder()
                do {
                    let formula = try decoder.decode(Formula.self, from: jsonData)
                    AppLog("🎉 [大模型API] Formula 对象解码成功!", level: .info, category: .network)
                    AppLog("📋 [大模型API] 菜谱名称: \(formula.name)", level: .info, category: .formula)
                    AppLog("🥘 [大模型API] 主料数量: \(formula.ingredients.mainIngredients.count)", level: .debug, category: .formula)
                    AppLog("🔧 [大模型API] 工具数量: \(formula.tools.count)", level: .debug, category: .formula)
                    AppLog("👨‍🍳 [大模型API] 步骤数量: \(formula.steps.count)", level: .debug, category: .formula)
                    return formula
                } catch let decodingError as DecodingError {
                    AppLog("❌ [大模型API] Formula 解码失败，详细错误信息:", level: .error, category: .network)
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        AppLog("   类型不匹配: \(type), 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error, category: .network)
                        AppLog("   错误描述: \(context.debugDescription)", level: .error, category: .network)
                    case .valueNotFound(let type, let context):
                        AppLog("   值未找到: \(type), 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error, category: .network)
                        AppLog("   错误描述: \(context.debugDescription)", level: .error, category: .network)
                    case .keyNotFound(let key, let context):
                        AppLog("   键未找到: \(key.stringValue), 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error, category: .network)
                        AppLog("   错误描述: \(context.debugDescription)", level: .error, category: .network)
                    case .dataCorrupted(let context):
                        AppLog("   数据损坏, 路径: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))", level: .error, category: .network)
                        AppLog("   错误描述: \(context.debugDescription)", level: .error, category: .network)
                    @unknown default:
                        AppLog("   未知解码错误: \(decodingError)", level: .error, category: .network)
                    }
                    await MainActor.run { AppLogger.shared.logDataSummary(jsonData, description: "用于解码的JSON", category: .network, level: .error) }
                    throw BigModelAPIError.decodingFailed(decodingError)
                }
                
            } catch let jsonError {
                AppLog("❌ [大模型API] JSON 解析失败: \(jsonError.localizedDescription)", level: .error, category: .network)
                await MainActor.run { AppLogger.shared.logDataSummary(data, description: "原始响应体", category: .network, level: .error) }
                throw BigModelAPIError.decodingFailed(jsonError)
            }

        } catch {
            AppLog("❌ [大模型API] 网络请求失败: \(error.localizedDescription)", level: .error, category: .network)
            throw BigModelAPIError.requestFailed("网络请求发生错误: \(error.localizedDescription)")
        }
    }
}
