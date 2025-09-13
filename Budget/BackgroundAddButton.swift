import SwiftUI
import PhotosUI

struct BackgroundAddButton: View {
    @EnvironmentObject private var store: BackgroundImageStore
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) {
            // Circular “+” with material background
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                .shadow(radius: 8)
        }
        .accessibilityLabel("Add Background Image")
        // Use both onChange and task(id:) so selection always processes
        .onChange(of: item) { oldValue, newValue in
            Task { await loadSelection(newValue) }
        }
        .task(id: item) {
            await loadSelection(item)
        }
    }

    private func loadSelection(_ selection: PhotosPickerItem?) async {
        guard let selection else { return }
        do {
            if let data = try await selection.loadTransferable(type: Data.self),
               let img  = UIImage(data: data) {
                await MainActor.run { store.setImage(img) }
            }
        } catch {
            // ignore failures; keep previous background
        }
    }
}

