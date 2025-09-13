import SwiftUI

@MainActor
final class BackgroundImageStore: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var blur: CGFloat = 0
    @Published var dim: Double = 0
}
