import SwiftUI

// MARK: - Reusable Bottom Sheet Component
struct BottomSheet<SheetContent: View>: View {
    let sheetContent: SheetContent
    let buttonTitle: String
    let buttonAction: () -> Void
    let onClose: () -> Void
    let isButtonDisabled: Bool
    
    init(
        buttonTitle: String,
        buttonAction: @escaping () -> Void,
        onClose: @escaping () -> Void,
        isButtonDisabled: Bool = false,
        @ViewBuilder content: () -> SheetContent
    ) {
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.onClose = onClose
        self.isButtonDisabled = isButtonDisabled
        self.sheetContent = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            HStack(alignment: .top) {
                // Drag indicator in center
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                Spacer()
            }
            .overlay(
                // X button overlaid on right
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .offset(x: -20, y: 20) // 20pt from right, 20pt from top
                }
            )
            .frame(height: 60)
            
            // Dynamic content
            sheetContent
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            
            // Fixed button at bottom with safe area consideration
            Button(buttonTitle, action: buttonAction)
                .buttonStyle(AppButtonStyle())
                .disabled(isButtonDisabled)
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
        }
        .background(Color(white: 0.15))
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Category Bottom Sheet Content
struct CategorySheetContent: View {
    @Binding var name: String
    @Binding var emoji: String
    @Binding var isIncome: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                TextField("e.g. Food", text: $name)
                    .textFieldStyle(GlassTextFieldStyle())
            }
            
            // Emoji field
            VStack(alignment: .leading, spacing: 8) {
                Text("Emoji (optional)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                TextField("e.g. 🍕", text: $emoji)
                    .textFieldStyle(GlassTextFieldStyle())
            }
            
            // Type selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 12) {
                    Button(action: { isIncome = false }) {
                        Text("Expense")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .background(GlassChipBackground(isSelected: !isIncome))
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { isIncome = true }) {
                        Text("Income")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .background(GlassChipBackground(isSelected: isIncome))
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Payment Bottom Sheet Content
struct PaymentSheetContent: View {
    @Binding var name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Type")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            TextField("e.g. Credit Card, Pix", text: $name)
                .textFieldStyle(GlassTextFieldStyle())
        }
        .padding(.bottom, 60) // Extra padding for smaller sheet
    }
}
