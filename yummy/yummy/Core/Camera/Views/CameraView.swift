//
//  CameraView.swift
//  yummy
//
//  Created by steve on 2025/1/27.
//

import SwiftUI
import UIKit

struct CameraView: View {
    let formula: Formula
    @Binding var navigationPath: [NavigationPage]
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        CameraPickerView(
            sourceType: .camera,
            onImagePicked: { image in
                viewModel.handleImagePicked(image, formula: formula) {
                    // 拍照成功后返回上一页
                    dismiss()
                }
            },
            onCancel: {
                // 取消拍照返回上一页
                dismiss()
            }
        )
        .ignoresSafeArea()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .alert("相机权限", isPresented: $viewModel.showPermissionAlert) {
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要相机权限才能拍摄照片，请在设置中开启相机权限")
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay {
            uploadOverlay
        }
    }
    
    @ViewBuilder
    private var uploadOverlay: some View {
        if viewModel.isUploading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("正在保存图片...")
                        .foregroundColor(.white)
                        .appStyle(.body)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - PhotoLibraryView
struct PhotoLibraryView: View {
    let formula: Formula
    @Binding var navigationPath: [NavigationPage]
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = PhotoLibraryViewModel()
    
    var body: some View {
        CameraPickerView(
            sourceType: .photoLibrary,
            onImagePicked: { image in
                viewModel.handleImagePicked(image, formula: formula) {
                    // 选择图片成功后返回上一页
                    dismiss()
                }
            },
            onCancel: {
                // 取消选择返回上一页
                dismiss()
            }
        )
        .ignoresSafeArea()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .alert("相册权限", isPresented: $viewModel.showPermissionAlert) {
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("需要相册权限才能选择照片，请在设置中开启相册权限")
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .overlay {
            uploadOverlay
        }
    }
    
    @ViewBuilder
    private var uploadOverlay: some View {
        if viewModel.isUploading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("正在保存图片...")
                        .foregroundColor(.white)
                        .appStyle(.body)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - PhotoLibraryViewModel
@MainActor
class PhotoLibraryViewModel: ObservableObject {
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?
    @Published var isUploading = false
    
    private let cameraService: CameraServiceProtocol
    private let imageUploadService: ImageUploadServiceProtocol
    private let formulaRepository: FormulaRepositoryProtocol
    
    init(
        cameraService: CameraServiceProtocol = CameraService.shared,
        imageUploadService: ImageUploadServiceProtocol = ImageUploadService.shared,
        formulaRepository: FormulaRepositoryProtocol = FormulaRepository.shared
    ) {
        self.cameraService = cameraService
        self.imageUploadService = imageUploadService
        self.formulaRepository = formulaRepository
    }
    
    func handleImagePicked(_ image: UIImage, formula: Formula, completion: @escaping () -> Void) {
        Task {
            await uploadImage(image, formula: formula, completion: completion)
        }
    }
    
    private func uploadImage(_ image: UIImage, formula: Formula, completion: @escaping () -> Void) async {
        isUploading = true
        clearError()
        
        do {
            let updatedFormula = try await imageUploadService.uploadImageForFormula(formula, image: image)
            // 保存更新后的 Formula 到数据库
            try await formulaRepository.save(updatedFormula)
            isUploading = false
            completion()
        } catch {
            setError("图片保存失败：\(error.localizedDescription)")
            isUploading = false
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
    }
    
    func clearError() {
        errorMessage = nil
    }
}
