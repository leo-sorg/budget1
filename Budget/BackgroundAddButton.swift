import SwiftUI
import PhotosUI

struct BackgroundAddButton: View {
    @EnvironmentObject private var store: BackgroundImageStore
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
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
        .onChange(of: pickerItem) { oldValue, newValue in
            Task { await loadSelection(newValue) }
        }
        .task(id: pickerItem) {
            await loadSelection(pickerItem)
        }
    }

    @MainActor
    private func setBackground(_ ui: UIImage?) {
        store.setImage(ui)
    }

    private func loadSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let ui   = UIImage(data: data) {
                await MainActor.run { setBackground(ui) }
            }
        } catch {
            // ignore failures
        }
    }
}

