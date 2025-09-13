import SwiftUI
import PhotosUI

struct ManageScreen: View {
    @EnvironmentObject private var store: BackgroundImageStore
    @State private var item: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Appearance").font(.title).bold()

                if let img = store.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.2)))
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.06))
                        .frame(height: 120)
                        .overlay(Text("No background").opacity(0.6))
                }

                PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) {
                    Text("Choose Background").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) { store.setImage(nil) } label: {
                    Text("Remove Background").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Dim");  Slider(value: $store.dim,  in: 0...0.6)
                    Text("Blur"); Slider(value: $store.blur, in: 0...16)
                }.padding(.top, 12)
            }
            .padding()
        }
        .background(Color.clear)
        // Ensure selection processing in all environments
        .onChange(of: item) { oldValue, newValue in
            Task { await loadSelection(newValue) }
        }
        .task(id: item) { await loadSelection(item) }
    }

    private func loadSelection(_ selection: PhotosPickerItem?) async {
        guard let selection else { return }
        do {
            if let data = try await selection.loadTransferable(type: Data.self),
               let img  = UIImage(data: data) {
                await MainActor.run { store.setImage(img) }
            }
        } catch {
            // ignore failures
        }
    }
}
