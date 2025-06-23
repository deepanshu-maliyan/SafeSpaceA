import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.white.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? AppColors.accent.opacity(0.8) : AppColors.accent)
            .cornerRadius(10)
            .foregroundColor(.white)
            .font(.headline)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? AppColors.cardBackground.opacity(0.8) : AppColors.cardBackground)
            .cornerRadius(10)
            .foregroundColor(AppColors.accent)
            .font(.headline)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppColors.accent, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
} 