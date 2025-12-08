//
//  MainTabView.swift
//  yummy
//
//  Created by steve on 2025/6/19.
//

import SwiftUI
import LucideIcons

enum TabItem: String, CaseIterable {
    case add = "Add"
    
    var symblImage: UIImage {
        switch self {
        case .add: Lucide.plus.withRenderingMode(.alwaysTemplate)
        }
    }
}

struct MainTabView: View {
    @State private var showTidyViewSheet: Bool = false
    @State private var navigationPath: [NavigationPage] = []
    
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var scrollView
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundDefault.ignoresSafeArea()
            
            // 底层：主要内容区域
            NavigationStack(path: $navigationPath) {
                HomeView(navigationPath: $navigationPath, zoomNamespace: scrollView)
                    .navigationDestination(for: NavigationPage.self) { page in
                        switch page {
                        case .detail(let formula):
                            DetailView(formulaId: formula.id, navigationPath: $navigationPath)
                                .navigationTransition(.zoom(sourceID: formula.id, in: scrollView))
                        case .cuisine(let focusId):
                            CuisineView(navigationPath: $navigationPath, focusId: focusId)
                        case .camera(let formula):
                            CameraView(formula: formula, navigationPath: $navigationPath)
                        case .photoLibrary(let formula):
                            PhotoLibraryView(formula: formula, navigationPath: $navigationPath)
                        }
                        
                    }
            }
            
            // 上层：透明背景 + 浮动按钮
            bottomNavigationBar
                .sheet(isPresented: $showTidyViewSheet) {
                    TidyView()
                }
                .opacity(navigationPath.isEmpty ? 1 : 0)
                .allowsHitTesting(navigationPath.isEmpty)
        }
    }
    
    private var bottomNavigationBar : some View {
        
        ZStack(alignment: .bottom) {
            // 背景层：应用 mask 的毛玻璃背景
//            BlurView(style: .systemUltraThinMaterial,removeAllFilter: true)
//                .blur(radius: 5 ,opaque: false)
//                .padding([.horizontal,.bottom],-45)
//                .frame(maxWidth: .infinity)
//                .frame(height: 90)
            
            
            BlurView()
                .blur(radius: 3)
                .padding(.horizontal,-45)
                .padding(.bottom,-45)
                .frame(height: 90)
//                .padding(.top,-100)
            
            
            
//            Rectangle()
//                .fill(Color.clear)
//                .frame(maxWidth: .infinity)
//                .frame(height: 140)
//                .background(
//                    RoundedRectangle(cornerRadius: 0)
//                        .fill(.ultraThinMaterial)
//                        .offset(y: 65)
////                        .shadow(color: .lineDefault.opacity(0.5), radius: 10, x: 0, y: -20)
//                )
            
            
            
            VStack(alignment: .center) {
                
                CustomAddButton(
                    showTidyViewSheet: $showTidyViewSheet
                )
                .padding(.bottom, 8)
            }
//            .frame(maxWidth: .infinity)
//            .frame(height: 100)
//            .background(
//                .ultraThinMaterial
//            )
        }
        .allowsHitTesting(true) // 允许点击事件
    }
    

}
#Preview {
    MainTabView()
        .environmentObject(HomeViewModel())
}
