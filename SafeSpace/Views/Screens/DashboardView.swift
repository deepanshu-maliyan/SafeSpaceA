import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Stats
                    statsSection
                    
                    // Recent detections
                    recentDetections
                    
                    // Alerts
                    AlertListView(alerts: appState.alerts)
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Mission Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SystemStatusBadge(status: appState.systemStatus)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CodeBuddies")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.text)
                    
                    Text("Detecting the Undetectable")
                        .font(.subheadline)
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "shield.checkmark")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)
                }
            }
            
            HStack {
                Label("Mission Time", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
                
                Spacer()
                
                Text(appState.missionStartTime.missionTimeString())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(16)
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("System Status")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ProgressMetricView(
                    title: "Detection Accuracy",
                    value: appState.detectionAccuracy,
                    icon: "checkmark.circle",
                    color: AppColors.success
                )
                
                ProgressMetricView(
                    title: "Processing Power",
                    value: appState.processingPower,
                    icon: "cpu",
                    color: AppColors.info
                )
                
                ProgressMetricView(
                    title: "Battery",
                    value: appState.batteryLevel,
                    icon: "battery.75",
                    color: AppColors.warning
                )
                
                ProgressMetricView(
                    title: "Detection Speed",
                    value: appState.detectionSpeed,
                    icon: "speedometer",
                    color: AppColors.accent
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Objects Detected")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                HStack {
                    ForEach(ObjectType.allCases.prefix(6), id: \.self) { type in
                        let count = appState.objectsFound[type] ?? 0
                        
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(type.color.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: type.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(type.color)
                            }
                            
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(AppColors.text)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private var recentDetections: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Detections")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(AppColors.accent)
                }
            }
            
            ForEach(Array(appState.detectedObjects.prefix(3))) { object in
                ObjectItemView(detectedObject: object)
            }
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
} 