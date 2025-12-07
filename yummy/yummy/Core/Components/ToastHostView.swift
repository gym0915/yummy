import SwiftUI
import LucideIcons

struct ToastHostView: View {
    @EnvironmentObject private var toastManager: ToastManager

    var body: some View {
        ZStack {
            if let item = toastManager.currentItem {
                container(for: item)
                    .id(item.id)
                    .transition(.move(edge: item.position.transitionEdge).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: toastManager.currentItem?.id)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func container(for item: ToastItem) -> some View {
        VStack {
            if item.position == .top { toastView(item) }
            Spacer(minLength: 0)
            if item.position == .bottom { toastView(item) }
        }
        .padding(.horizontal, 16)
        .padding(.top, item.position == .top ? 12 : 0)
        .padding(.bottom, item.position == .bottom ? 12 : 0)
    }

    private func toastView(_ item: ToastItem) -> some View {
        HStack(spacing: 10) {
            Image(uiImage: item.style.iconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(.white)

            Text(item.message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(item.style.backgroundColor)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color.backgroundDefault.ignoresSafeArea()
        VStack {}
    }
    .overlay(ToastHostView().environmentObject(ToastManager.shared))
    .onAppear {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            ToastManager.shared.show("当前网络不可用", style: .warning)
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            ToastManager.shared.show("操作成功", style: .success, position: .top)
        }
    }
}


