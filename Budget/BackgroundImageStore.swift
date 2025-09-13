import SwiftUI

@MainActor
final class BackgroundImageStore: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var blur: CGFloat = 0          // optional: UI blur control
    @Published var dim: Double = 0.0          // optional: UI dim control
}
