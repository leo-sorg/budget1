import SwiftUI
import PhotosUI

struct BackgroundPicker: View {
    @EnvironmentObject private var store: BackgroundImageStore
    @State private var item: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $item, matching: .images) {
                Text("Choose Background")
            }
            Button("Remove Background") {
                store.image = nil
            }
        }
        .onChange(of: item) { newItem in
            guard let newItem else { return }
            Task {
                // Load UIImage directly (handles HEIC/HEIF/RAW better)
                if let uiImage = try? await newItem.loadTransferable(type: UIImage.self) {
                    await MainActor.run { store.image = uiImage }
                }
            }
        }
    }
}
