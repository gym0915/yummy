//
//  CuisineFilterView.swift
//  yummy
//
//  Created by steve on 2025/7/27.
//

import SwiftUI

struct CuisineFilterView: View {
    @Binding var selectedTab: CuisineTab
    @Namespace private var namespace
    
    private let tabs = CuisineTab.allCases
    
    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            ForEach(tabs, id: \.self) { tab in
                VStack(spacing: 8) {
                    
                    switch tab {
                    case .procurement:
                        Image("icon-shop")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    case .prepare:
                        Image("icon-prepare")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    case .cuisine:
                        Image("icon-cook2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }
                                       
                    Text(tab.displayName)
                        .frame(maxWidth: .infinity)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if tab == selectedTab {
                        RoundedRectangle(cornerRadius: 2)
                            .frame(height: 1.5)
                            .matchedGeometryEffect(id: "selection", in: namespace)
                    }
                }
                .padding(.top, 8)
                .contentShape(.interaction, .rect)
                .foregroundStyle(tab == selectedTab ? .accent : .textPrimary)
                .onTapGesture {
                    selectedTab = tab
                    
                    AppLog("当前选择Tab：\(tab.displayName)", level: .debug, category: .ui)
                }
            }
            .animation(.spring, value: selectedTab)
        }
    }
}

fileprivate struct CuisineFilterViewPreview: View {
    @State private var selectedTab: CuisineTab = .procurement
    
    var body: some View {
        VStack {
            CuisineFilterView(selectedTab: $selectedTab)
            
            Text("当前选择Tab: \(selectedTab.displayName)")
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    CuisineFilterViewPreview()
}
