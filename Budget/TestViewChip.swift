import SwiftUI

struct TestChipView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("CHIP TEST")
                .font(.title)
                .foregroundColor(.white)
            
            // Test with fake data
            PaymentChipView(
                paymentMethod: PaymentMethod(name: "Test Payment"),
                isSelected: false,
                onTap: {
                    print("Test payment chip tapped")
                }
            )
            
            CategoryChipView(
                category: Category(name: "Test Category"),
                isSelected: false,
                onTap: {
                    print("Test category chip tapped")
                }
            )
        }
        .padding()
        .background(Color.black)
    }
}

#Preview {
    TestChipView()
}
