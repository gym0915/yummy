//
//  CuisineGroupHeaderView.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import SwiftUI

struct CuisineGroupHeaderView: View {
    let formulaName: String
    
    var body: some View {
        HStack {
            Text(formulaName)
                .appStyle(.title)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.backgroundDefault)
    }
}

#Preview {
    VStack(spacing: 0) {
        CuisineGroupHeaderView(formulaName: "厚切牛排")
        CuisineGroupHeaderView(formulaName: "手撕包菜")
        CuisineGroupHeaderView(formulaName: "炖豆腐")
    }
} 