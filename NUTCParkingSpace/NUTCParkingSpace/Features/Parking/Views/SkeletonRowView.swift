 import SwiftUI

struct PulseEffect: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.3 : 0.7)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(PulseEffect())
    }
}

struct SkeletonRowView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                // Name placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 120, height: 20)
                
                // Time placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 150, height: 14)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                // Count placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 60, height: 30)
                
                // Label placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 12)
            }
        }
        .padding(.vertical, 8)
        .shimmer() // Apply shimmer effect
    }
}

struct SkeletonRowView_Previews: PreviewProvider {
    static var previews: some View {
        SkeletonRowView()
            .padding()
    }
}
