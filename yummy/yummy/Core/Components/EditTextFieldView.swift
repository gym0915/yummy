//
//  EditTextFieldView.swift
//  yummy
//
//  Created by steve on 2025/1/7.
//

import SwiftUI

/// 编辑页面文本输入框组件
/// 带字符计数提示的文本输入框，用于各种需要输入限制的表单字段
/// 支持单行和多行文本输入
struct EditTextFieldView: View {
    private let placeholder: String
    @Binding private var text: String
    private let maxLength: Int?
    private let isMultiline: Bool
    private let minHeight: CGFloat
    private let animationDelayNanoseconds: UInt64 = 100_000_000 // 0.1秒
    
    /// 初始化编辑文本输入框视图
    /// - Parameters:
    ///   - placeholder: 占位符文字
    ///   - text: 绑定的文本内容
    ///   - maxLength: 最大字符数限制，nil 表示无限制
    ///   - isMultiline: 是否支持多行输入，默认为false
    ///   - minHeight: 多行输入时的最小高度，默认60
    init(
        placeholder: String,
        text: Binding<String>,
        maxLength: Int? = nil,
        isMultiline: Bool = false,
        minHeight: CGFloat = 60
    ) {
        self.placeholder = placeholder
        self._text = text
        self.maxLength = maxLength
        self.isMultiline = isMultiline
        self.minHeight = minHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isMultiline {
                // 多行文本输入
                multilineTextInput
            } else {
                // 单行文本输入
                singleLineTextInput
            }
        }
    }
    
    // MARK: - 单行文本输入
    private var singleLineTextInput: some View {
        TextField(placeholder, text: $text)
            .foregroundStyle(.textPrimary)
            .textFieldStyle(EditTextFieldStyle())
            .onSubmit {
                // 在用户完成输入时（如按回车或失去焦点）进行字符截断
                if let maxLength = maxLength, text.count > maxLength {
                    text = String(text.prefix(maxLength))
                }
            }
            .onChange(of: text) { _, newValue in
                // 延迟处理字符截断，避免干扰拼音输入
                Task {
                    try? await Task.sleep(nanoseconds: animationDelayNanoseconds)
                    await MainActor.run {
                        if let maxLength = maxLength, text.count > maxLength {
                            text = String(text.prefix(maxLength))
                        }
                    }
                }
            }
//            .overlay {
//                HStack {
//                    Spacer()
//                    if let maxLength = maxLength {
//                        Text("\(text.count)/\(maxLength)")
//                            .font(.caption)
//                            .foregroundColor(isOverLimit ? .red : .textLightGray)
//                    }
//                }
//                .padding()
//            }
    }
    
    // MARK: - 多行文本输入
    private var multilineTextInput: some View {
        ZStack(alignment: .topLeading) {
            // 背景和边框
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.backgroundDefault)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.lineFrame, lineWidth: 0.5)
                )
                .frame(minHeight: minHeight)
            
            // 占位符
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.textLightGray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
            
            // 文本编辑器
            TextEditor(text: $text)
                .foregroundStyle(.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: minHeight)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .onChange(of: text) { _, newValue in
                    // 延迟处理字符截断，避免干扰拼音输入
                    Task {
                        try? await Task.sleep(nanoseconds: animationDelayNanoseconds)
                        await MainActor.run {
                            if let maxLength = maxLength, text.count > maxLength {
                                text = String(text.prefix(maxLength))
                            }
                        }
                    }
                }
            
            // 字符计数显示在右下角
            if let maxLength = maxLength {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(text.count)/\(maxLength)")
                            .font(.caption)
                            .foregroundColor(isOverLimit ? .red : .textLightGray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - 私有计算属性
    /// 是否超出字符限制
    private var isOverLimit: Bool {
        guard let maxLength = maxLength else { return false }
        return text.count > maxLength
    }
}

// MARK: - 编辑文本框样式
struct EditTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.backgroundDefault)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.lineFrame, lineWidth: 0.5)
            )
    }
}

// MARK: - 预览
#Preview {
    @Previewable @State var nameText = "示例美食名字"
    @Previewable @State var tagText = "示例标签"
    @Previewable @State var stepText = "炖鸡汤炖鸡汤"
    
    VStack(spacing: 16) {
        // 单行输入框
        EditTextFieldView(
            placeholder: "请输入美食名字",
            text: $nameText,
            maxLength: 50
        )
        
        EditTextFieldView(
            placeholder: "添加标签",
            text: $tagText,
            maxLength: 10
        )
        
        // 多行输入框
        EditTextFieldView(
            placeholder: "请输入步骤详情",
            text: $stepText,
            maxLength: 50,
            isMultiline: true,
            minHeight: 60
        )
    }
    .padding()
    .background(Color.backgroundDefault)
}
