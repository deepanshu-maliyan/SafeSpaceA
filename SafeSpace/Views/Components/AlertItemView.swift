import SwiftUI

struct AlertItemView: View {
    var alert: Alert
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.severity.icon)
                .foregroundColor(alert.severity.color)
                .font(.system(size: 20))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.text)
                    
                    Spacer()
                    
                    Text(alert.timestamp.timeAgo())
                        .font(.caption2)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(alert.severity.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alert.severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AlertListView: View {
    var alerts: [Alert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alerts")
                .font(.headline)
                .foregroundColor(AppColors.text)
            
            if alerts.isEmpty {
                Text("No alerts")
                    .font(.subheadline)
                    .foregroundColor(AppColors.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(alerts) { alert in
                    AlertItemView(alert: alert)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        AlertItemView(alert: Alert(
            title: "Fire Extinguisher Missing",
            message: "Fire extinguisher in Sector B not detected during last scan.",
            severity: .warning,
            timestamp: Date().addingTimeInterval(-7200)
        ))
        
        AlertItemView(alert: Alert(
            title: "Model Updated",
            message: "Object detection model has been updated to v2.1.",
            severity: .info,
            timestamp: Date().addingTimeInterval(-3600)
        ))
    }
    .padding()
    .background(AppColors.background)
} 