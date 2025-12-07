//
//  TideView.swift
//  yummy
//
//  Created by steve on 2025/6/22.
//

import SwiftUI

struct TidyView: View {
    
    @StateObject var viewModel = TidyViewModel()
    @State var text: String = ""
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    private let textContent: String = "把美食文案粘贴进来吧，即刻拥有条理清晰的美食笔记，告别杂乱！"
    
    var body: some View {
        ZStack {
            Color.backgroundDefault.ignoresSafeArea()
            
            VStack(spacing: 16) {
                ModalHandleView()
                    .padding(.top, 6)

                
                NavigationBarSection
                
                textEditorSection
            }
        }
        .navigationBarHidden(true)
        .onChange(of: text, { _ , newValue in
            viewModel.inputtedText = newValue
            viewModel.isTrailingButtonRightEnabled = !newValue.isEmpty
        })
        .onAppear {
            // 将 dismiss 方法传递给 ViewModel
            viewModel.setDismissAction {
                dismiss()
            }
        }
    }
    
    private var textEditorSection: some View {
        ZStack(alignment: .topLeading) {
            Group{
                if text.isEmpty {
                    Text(textContent)
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundColor(.textLightGray)
                        .padding(16)
                }
                TextEditor(text: $text)
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundWhite)
                    .padding(16)
                    .opacity(text.isEmpty ? 0.1 : 1)
            }
        }
        .background(Color.backgroundWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.lineFrame, lineWidth: 1)
        )
        .padding(16)
        .frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading)
        .shadow(color: .lineFrame, radius: 1, x: 1, y: 1)
    }
    
    private var NavigationBarSection: some View {
        CustomNavigationBar(
            title: viewModel.navigationTitle,
            titleIcon: Image("icon-write2"),
            leadingButton: viewModel.leadingNavigationButton,
            trailingButtonLeft: nil,
            trailingButtonRight: viewModel.trailingNavigationButtonRight,
            isTransparent: true
        )
    }
}

#Preview {
    TidyView()
}
