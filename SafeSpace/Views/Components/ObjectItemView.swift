import SwiftUI

struct ObjectItemView: View {
    var detectedObject: DetectedObject
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(detectedObject.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: detectedObject.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(detectedObject.type.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(detectedObject.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.text)
                
                Text(detectedObject.type.rawValue)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(detectedObject.confidence * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(confidentColor(detectedObject.confidence))
                
                Text(detectedObject.timestamp.timeAgo())
                    .font(.caption2)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
    }
    
    private func confidentColor(_ confidence: Double) -> Color {
        if confidence >= 0.9 {
            return AppColors.success
        } else if confidence >= 0.7 {
            return AppColors.warning
        } else {
            return AppColors.danger
        }
    }
}

struct ObjectListView: View {
    var objects: [DetectedObject]
    var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.text)
            
            if objects.isEmpty {
                Text("No objects detected")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(objects) { object in
                    ObjectItemView(detectedObject: object)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(DetectedObject.sampleObjects) { object in
            ObjectItemView(detectedObject: object)
        }
    }
    .padding()
    .background(AppColors.background)
}