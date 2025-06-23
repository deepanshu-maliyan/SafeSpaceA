import SwiftUI

struct StatusBadgeView: View {
    var status: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SystemStatusBadge: View {
    var status: SystemStatus
    
    var body: some View {
        StatusBadgeView(status: status.rawValue, color: status.color)
    }
}

#Preview {
    HStack {
        SystemStatusBadge(status: .online)
        SystemStatusBadge(status: .offline)
        SystemStatusBadge(status: .degraded)
        SystemStatusBadge(status: .updating)
    }
} 