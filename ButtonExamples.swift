import SwiftUI

// MARK: - Examples of proper Apple Glass Button usage
struct ButtonExamples: View {
    var body: some View {
        VStack(spacing: 20) {
            // Standard glass button
            Button("Standard Glass Button") {
                // Action
            }
            .buttonStyle(.glass)
            
            // Prominent glass button
            Button("Prominent Glass Button") {
                // Action
            }
            .buttonStyle(.glassProminent)
            
            // Custom styled glass button
            Button("Custom Glass Button") {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Favorite")
                }
            }
            .buttonStyle(.glass)
            .font(.system(size: 14, weight: .medium))
            
            // Multiple glass buttons in container
            GlassEffectContainer(spacing: 12.0) {
                VStack(spacing: 12) {
                    Button("Action 1") {
                        // Action
                    }
                    .buttonStyle(.glass)
                    
                    Button("Action 2") {
                        // Action
                    }
                    .buttonStyle(.glass)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ButtonExamples()
}