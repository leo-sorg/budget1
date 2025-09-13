import SwiftUI
import PhotosUI

struct BackgroundPicker: View {
    @EnvironmentObject private var store: BackgroundImageStore
    @Environment(\.dismiss) private var dismiss

    @State private var item: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) {
                Text("Choose Background")
            }
            if store.image != nil {
                Button("Remove Background") {
                    store.image = nil
                    dismiss()
                }
            }

            // Debug status (helps verify state while testing)
            Text(store.image == nil ? "No background loaded" : "Background loaded ✓")
                .font(.footnote).opacity(0.6)
        }
        // ✅ Workaround: Some environments don’t fire onChange consistently.
        // Use BOTH onChange and task(id:) so selection is always handled.
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
            // Load Data (Transferable) → UIImage (UIImage is NOT Transferable).
            if let data = try await selection.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await MainActor.run {
                    store.image = img
                    // Auto-close the picker so user immediately sees the background
                    dismiss()
                }
            }
        } catch {
            // If anything fails, keep previous image state; no crash.
        }
    }
}
