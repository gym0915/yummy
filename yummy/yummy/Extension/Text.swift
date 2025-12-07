//
//  Text.swift
//  wtoe
//
//  Created by steve on 2025/6/18.
//

import Foundation
import SwiftUI

protocol AppTextStyle {
    var font: Font { get }
    var textColor: Color { get }
    var weight: Font.Weight { get }
    var design: Font.Design { get }
    var textHeight: CGFloat { get }
}

enum AppText: AppTextStyle {
    case navigationTitle
    case tag
    case cardTitle
    case cardGray
    case dataText
    case body
    case title
    case subtitle
    
    

    var font: Font {
        switch self {
        case .navigationTitle:
            return .title
        case .title:
            return .title3
        case .subtitle:
            return .headline
        case .body:
            return .body
        case .tag, .dataText:
            return .caption
        case .cardTitle, .cardGray:
            return .callout
        }
    }

    var textColor: Color {
        switch self {
        case .navigationTitle, .title, .body , .cardTitle:
            return .textPrimary
        case .subtitle, .dataText, .cardGray:
            return .textLightGray
        case .tag:
            return .accent
        }
    }

    var weight: Font.Weight {
        switch self {
        case .navigationTitle, .title:
            return .bold
        case .subtitle:
            return .semibold
        case .body,.cardGray, .cardTitle:
            return .regular
        case .tag, .dataText:
            return .light
        }
    }

    var design: Font.Design {
        switch self {
        case .navigationTitle, .tag, .cardTitle, .title, .subtitle, .body, .dataText, .cardGray:
            return .rounded
        }
    }

    var textHeight: CGFloat {
        return 44.0
    }
}

extension Text {
    func appStyle(_ style: AppText) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.textColor)
            .fontWeight(style.weight)
            .fontDesign(style.design)
//            .frame(height: style.textHeight)
    }
}
    

