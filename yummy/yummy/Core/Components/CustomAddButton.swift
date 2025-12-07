//
//  CustomAddButton.swift
//  yummy
//
//  Created by steve on 2025/1/21.
//

import SwiftUI
import LucideIcons

struct CustomAddButton: View {
    @Binding var showTidyViewSheet: Bool
    
    var body: some View {
        Button(action: {
            showTidyViewSheet = true
        }) {
            Image(uiImage: Lucide.plus.withRenderingMode(.alwaysTemplate))
                .resizable()
                .frame(width: 34, height: 34)
                .foregroundStyle(.white)
                .foregroundStyle(.white)
//                .background(
//                    Circle()
//                        .fill(.accent)
//                        .frame(width: 68, height: 68)
//                        .shadow(
//                            color: Color.black.opacity(0.25),
//                            radius: 10,
//                            x: 3,
//                            y: 3
//                        )
//                )
        }
        
//        .foregroundColor(.clear)
//        .buttonStyle(.glassProminent)
//        .frame(width: 150, height: 150)
//        .font(.headline)
        .frame(width: 52, height: 52)
        .background(
            Circle()
                .fill(.accent)
                .glassEffect(.clear.interactive(), in: .circle)
        )
        .clipShape(Circle())
        .glassEffect(.clear.interactive(), in: .circle)
//        .padding(.bottom, 16)
    }
}

#Preview {
    ZStack {
        Color.backgroundDefault.ignoresSafeArea()
        
        CustomAddButton(showTidyViewSheet: .constant(false))
    }
} 
