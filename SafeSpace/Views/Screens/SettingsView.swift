import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var confidenceThreshold = 0.7
    @State private var fpsLimit = 30.0
    @State private var useGPU = true
    @State private var detectHazardsOnly = false
    @State private var enableNotifications = true
    @State private var modelVersion = "YOLOv8n Space 2.1"
    
    var body: some View {
        NavigationStack {
            List {
                // Model settings
                modelSettingsSection
                
                // Detection settings
                detectionSettingsSection
                
                // Alert settings
                alertSettingsSection
                
                // About and Info
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var modelSettingsSection: some View {
        Section {
            HStack {
                Text("Model Version")
                Spacer()
                Text(modelVersion)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            modelVersionControl
            
            Toggle("Use GPU Acceleration", isOn: $useGPU)
            
            Button(action: {
                // In a real app, this would update the model
            }) {
                Text("Check for Model Updates")
                    .foregroundColor(AppColors.accent)
            }
        } header: {
            Text("Model Settings")
                .foregroundColor(AppColors.accent)
        } footer: {
            Text("The model version affects accuracy and performance.")
                .foregroundColor(AppColors.secondaryText)
        }
        .listRowBackground(AppColors.cardBackground)
    }
    
    private var modelVersionControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Model Size")
                Spacer()
                Text("Nano")
                    .foregroundColor(AppColors.accent)
            }
            
            HStack(spacing: 4) {
                modelOptionButton("Nano", isSelected: true)
                modelOptionButton("Small", isSelected: false)
                modelOptionButton("Medium", isSelected: false)
                modelOptionButton("Large", isSelected: false)
            }
        }
    }
    
    private var detectionSettingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Confidence Threshold")
                    Spacer()
                    Text("\(Int(confidenceThreshold * 100))%")
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)
                    .tint(AppColors.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("FPS Limit")
                    Spacer()
                    Text("\(Int(fpsLimit))")
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Slider(value: $fpsLimit, in: 5...60, step: 5)
                    .tint(AppColors.accent)
            }
            
            Toggle("Detect Only Hazard Items", isOn: $detectHazardsOnly)
        } header: {
            Text("Detection Settings")
                .foregroundColor(AppColors.accent)
        } footer: {
            Text("Higher confidence reduces false positives but may miss some objects.")
                .foregroundColor(AppColors.secondaryText)
        }
        .listRowBackground(AppColors.cardBackground)
    }
    
    private var alertSettingsSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $enableNotifications)
            
            Picker("Alert Sound", selection: .constant("Sonar")) {
                Text("None").tag("None")
                Text("Beep").tag("Beep")
                Text("Sonar").tag("Sonar")
                Text("Alert").tag("Alert")
            }
            
            Toggle("Vibrate on Critical Alerts", isOn: .constant(true))
            
            Button(action: {
                // Test alert
            }) {
                Text("Test Alert")
                    .foregroundColor(AppColors.accent)
            }
        } header: {
            Text("Alert Settings")
                .foregroundColor(AppColors.accent)
        }
        .listRowBackground(AppColors.cardBackground)
    }
    
    private var aboutSection: some View {
        Section {
            NavigationLink(destination: Text("About Screen").foregroundColor(.white)) {
                Label("About SafeSpace", systemImage: "info.circle")
            }
            
            NavigationLink(destination: Text("Help Screen").foregroundColor(.white)) {
                Label("Help & Support", systemImage: "questionmark.circle")
            }
            
            HStack {
                Label("App Version", systemImage: "swift")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AppColors.secondaryText)
            }
        } header: {
            Text("About")
                .foregroundColor(AppColors.accent)
        }
        .listRowBackground(AppColors.cardBackground)
    }
    
    private func modelOptionButton(_ label: String, isSelected: Bool) -> some View {
        Button(action: {
            // Switch model version
        }) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.accent : AppColors.cardBackground)
                .foregroundColor(isSelected ? .white : AppColors.secondaryText)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.accent, lineWidth: isSelected ? 0 : 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
} 