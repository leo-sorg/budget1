import SwiftUI

// MARK: - Emoji Helper Button
struct EmojiHelperButton: View {
    let onEmojiSelected: (String) -> Void
    @State private var showEmojiPicker = false
    
    // Common emojis that users might want for categories and payments
    private let commonEmojis = [
        // Food & Dining
        "🍽️", "🍕", "🍔", "🍟", "🥗", "🍝", "🍜", "🍲", "🥘", "🍳",
        "🥞", "🧇", "🥓", "🍖", "🍗", "🥩", "🌮", "🌯", "🥙", "🥚",
        "🍞", "🥖", "🥨", "🧀", "🥯", "🍎", "🍌", "🍊", "🍋", "🍇",
        "🍓", "🥝", "🍑", "🍒", "🥥", "🍍", "🥭", "🍅", "🥑", "🌶️",
        "🥒", "🥬", "🥕", "🌽", "🥔", "🍠", "☕", "🍵", "🧃", "🥤",
        
        // Transportation
        "🚗", "🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐",
        "🛻", "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "🛴", "🚁", "✈️",
        "🚀", "🚆", "🚄", "🚅", "🚈", "🚝", "🚞", "🚋", "🚃", "🚖",
        
        // Shopping & Money
        "🛍️", "🛒", "💳", "💰", "💵", "💴", "💶", "💷", "🏪", "🏬",
        "🛍️", "👕", "👖", "👗", "👚", "👔", "🧥", "👞", "👟", "👠",
        
        // Health & Medicine
        "🏥", "💊", "💉", "🩺", "🦷", "👩‍⚕️", "👨‍⚕️", "🧑‍⚕️",
        
        // Technology & Work
        "💻", "📱", "⌚", "📺", "📻", "🎮", "💼", "📚", "✏️", "📝",
        "🖥️", "⌨️", "🖱️", "🖨️", "📷", "📹", "🎥", "📞", "☎️",
        
        // Home & Living
        "🏠", "🏡", "🏢", "🏬", "🏭", "🏗️", "🏘️", "🛏️", "🛋️", "🚿",
        "🛁", "🚽", "💡", "🔌", "🔋", "🧹", "🧽", "🧴", "🧼", "🗑️",
        
        // Entertainment & Leisure
        "🎬", "🎭", "🎨", "🎪", "🎯", "🎲", "🃏", "🎸", "🎵", "🎶",
        "🎤", "🎧", "📖", "📚", "🎮", "🏀", "⚽", "🏈", "⚾", "🎾",
        
        // Animals & Pets
        "🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯",
        "🐸", "🐵", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅",
        
        // Fitness & Health
        "💪", "🏃‍♂️", "🏃‍♀️", "🚴‍♂️", "🚴‍♀️", "🏋️‍♂️", "🏋️‍♀️", "🤸‍♂️", "🤸‍♀️",
        "🧘‍♂️", "🧘‍♀️", "🏊‍♂️", "🏊‍♀️", "⛹️‍♂️", "⛹️‍♀️",
        
        // Payment Methods
        "💳", "💰", "💵", "💸", "🏧", "📱", "💎", "🪙", "💳",
        
        // Subscriptions & Services
        "📱", "📺", "🎵", "🎬", "📰", "📡", "🌐", "☁️",
        
        // Symbols
        "💼", "🎁", "🛡️", "⚡", "🔥", "⭐", "✨", "🌟", "💫", "🎯"
    ]
    
    var body: some View {
        Button(action: {
            showEmojiPicker = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "face.smiling")
                    .font(.system(size: 16))
                Text("Pick Emoji")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerSheet(
                emojis: commonEmojis,
                onEmojiSelected: { emoji in
                    onEmojiSelected(emoji)
                    showEmojiPicker = false
                },
                onDismiss: {
                    showEmojiPicker = false
                }
            )
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Emoji Picker Sheet
struct EmojiPickerSheet: View {
    let emojis: [String]
    let onEmojiSelected: (String) -> Void
    let onDismiss: () -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Choose Emoji")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                .padding()
                
                // Emoji Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button(action: {
                                onEmojiSelected(emoji)
                            }) {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
    }
}
