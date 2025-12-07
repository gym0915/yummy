//
//  DateFormatterUtility.swift
//  yummy
//
//  Created by steve on 2025/6/21.
//

import Foundation

struct DateFormatterUtility {
    /// 时间格式化器 (格式: HH:mm:ss)
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    /// 返回当前时间的 Date 类型
    static func currentDate() -> Date {
        return Date()
    }
    
    /// 将 Date 转换为中文格式的日期字符串 (格式: 2025 年 7 月 6 日)
    static func formatDateToChinese(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "zh_Hans_CN")
        dateFormatter.dateFormat = "yyyy 年 M 月 d 日"
        return dateFormatter.string(from: date)
    }
}
