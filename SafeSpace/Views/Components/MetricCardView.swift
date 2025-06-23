import SwiftUI

struct MetricCardView: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.text)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}

struct ProgressMetricView: View {
    var title: String
    var value: Double
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCardView(
            title: "Detection Speed",
            value: "35 ms",
            icon: "speedometer",
            color: AppColors.accent
        )
        
        ProgressMetricView(
            title: "Model Accuracy",
            value: 0.87,
            icon: "checkmark.circle",
            color: AppColors.success
        )
    }
    .padding()
    .background(AppColors.background)
} 