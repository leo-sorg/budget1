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
            if store.image != nil {
                Button("Remove Background") { store.image = nil }
            }
        }
        .onChange(of: item) { newItem in
            guard let newItem else { return }
            Task {
                do {
                    // Load Data (Transferable), then make a UIImage — this compiles.
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run { store.image = img }
                    } else {
                        await MainActor.run { store.image = nil }
                    }
                } catch {
                    await MainActor.run { store.image = nil }
                }
            }
        }
    }
}
