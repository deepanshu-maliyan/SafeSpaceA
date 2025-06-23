import SwiftUI

struct SimulationView: View {
    @EnvironmentObject var appState: AppState
    @State private var simulationActive = false
    @State private var selectedEnvironment: SimulationEnvironment = .normalStation
    @State private var lightingLevel: Double = 0.5
    @State private var occlusionLevel: Double = 0.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Simulation preview
                    simulationPreview
                    
                    // Controls
                    controlsSection
                    
                    // Environment selection
                    environmentSection
                    
                    // Detection results
                    if simulationActive {
                        resultsSection
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle("Simulation Lab")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var simulationPreview: some View {
        VStack(spacing: 8) {
            ZStack {
                // Display different environments based on selection
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        Image("simulation_\(selectedEnvironment == .normalStation ? "normal" : "dim")")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .brightness(calculateBrightness())
                            .overlay(
                                Rectangle()
                                    .fill(Color.black.opacity(occlusionLevel * 0.5))
                            )
                    )
                    .frame(height: 240)
                    .cornerRadius(12)
                
                // Status badge
                VStack {
                    HStack {
                        Spacer()
                        
                        StatusBadgeView(
                            status: simulationActive ? "Simulating" : "Ready",
                            color: simulationActive ? AppColors.accent : AppColors.secondaryText
                        )
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // Simulation overlay showing detected objects
                if simulationActive {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.accent.opacity(0.2))
                    
                    Image(systemName: "square.dashed")
                        .font(.system(size: 120))
                        .foregroundColor(AppColors.accent.opacity(0.3))
                }
            }
            
            Text(selectedEnvironment.rawValue)
                .font(.caption)
                .foregroundColor(AppColors.secondaryText)
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            Text("Simulation Controls")
                .font(.headline)
                .foregroundColor(AppColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 20) {
                sliderControl(
                    title: "Lighting Level",
                    icon: "sun.max",
                    value: $lightingLevel,
                    minLabel: "Dark",
                    maxLabel: "Bright",
                    color: AppColors.warning
                )
                
                sliderControl(
                    title: "Occlusion Level",
                    icon: "eye.slash",
                    value: $occlusionLevel,
                    minLabel: "None",
                    maxLabel: "High",
                    color: AppColors.info
                )
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
            
            Button(action: {
                withAnimation {
                    if simulationActive {
                        simulationActive = false
                    } else {
                        startSimulation()
                    }
                }
            }) {
                Text(simulationActive ? "Stop Simulation" : "Start Simulation")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(simulationActive ? AppColors.secondaryAccent : AppColors.accent)
                    .cornerRadius(12)
            }
        }
    }
    
    private var environmentSection: some View {
        VStack(spacing: 16) {
            Text("Environment")
                .font(.headline)
                .foregroundColor(AppColors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(SimulationEnvironment.allCases, id: \.self) { environment in
                    environmentButton(environment)
                }
            }
        }
    }
    
    private var resultsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Simulation Results")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text("YOLOv8")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.accent.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(AppColors.accent)
            }
            
            VStack(spacing: 12) {
                resultMetricRow(
                    title: "Detection Accuracy",
                    value: "\(calculateAccuracy())%",
                    icon: "checkmark.seal",
                    color: getAccuracyColor()
                )
                
                Divider().background(AppColors.secondaryText.opacity(0.3))
                
                resultMetricRow(
                    title: "Objects Found",
                    value: "\(calculateObjectsFound())/7",
                    icon: "cube.box",
                    color: AppColors.info
                )
                
                Divider().background(AppColors.secondaryText.opacity(0.3))
                
                resultMetricRow(
                    title: "Detection Time",
                    value: "\(calculateDetectionTime()) ms",
                    icon: "speedometer",
                    color: AppColors.accent
                )
                
                Divider().background(AppColors.secondaryText.opacity(0.3))
                
                resultMetricRow(
                    title: "Failure Rate",
                    value: "\(calculateFailureRate())%",
                    icon: "exclamationmark.triangle",
                    color: getFailureColor()
                )
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(12)
        }
    }
    
    private func sliderControl(title: String, icon: String, value: Binding<Double>, minLabel: String, maxLabel: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppColors.text)
                
                Spacer()
                
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
            
            HStack(spacing: 12) {
                Text(minLabel)
                    .font(.caption2)
                    .foregroundColor(AppColors.secondaryText)
                
                Slider(value: value, in: 0...1)
                    .tint(color)
                
                Text(maxLabel)
                    .font(.caption2)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
    
    private func environmentButton(_ environment: SimulationEnvironment) -> some View {
        Button(action: {
            withAnimation {
                selectedEnvironment = environment
                adjustSettingsForEnvironment(environment)
            }
        }) {
            HStack {
                Text(environment.rawValue)
                    .font(.callout)
                    .foregroundColor(selectedEnvironment == environment ? .white : AppColors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                if selectedEnvironment == environment {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedEnvironment == environment ? AppColors.accent : AppColors.cardBackground)
            )
        }
    }
    
    private func resultMetricRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    // Helper functions
    
    private func startSimulation() {
        simulationActive = true
        // In a real app, you would start the actual simulation process here
    }
    
    private func adjustSettingsForEnvironment(_ environment: SimulationEnvironment) {
        switch environment {
        case .normalStation:
            lightingLevel = 0.8
            occlusionLevel = 0.0
        case .dimLighting:
            lightingLevel = 0.3
            occlusionLevel = 0.0
        case .emergencyLighting:
            lightingLevel = 0.1
            occlusionLevel = 0.0
        case .maintenanceMode:
            lightingLevel = 0.6
            occlusionLevel = 0.4
        case .sleepQuarters:
            lightingLevel = 0.2
            occlusionLevel = 0.2
        }
    }
    
    private func calculateBrightness() -> Double {
        return (lightingLevel - 0.5) * 0.7
    }
    
    private func calculateAccuracy() -> Int {
        // Simulate accuracy based on lighting and occlusion
        let baseAccuracy: Double = 92
        let lightingImpact = (1.0 - lightingLevel) * 20
        let occlusionImpact = occlusionLevel * 30
        
        let adjustedAccuracy = baseAccuracy - lightingImpact - occlusionImpact
        return max(60, min(99, Int(adjustedAccuracy)))
    }
    
    private func calculateObjectsFound() -> Int {
        // Simulate objects found based on lighting and occlusion
        let baseObjects = 7
        let lightingImpact = Int((1.0 - lightingLevel) * 3)
        let occlusionImpact = Int(occlusionLevel * 4)
        
        return max(3, baseObjects - lightingImpact - occlusionImpact)
    }
    
    private func calculateDetectionTime() -> Int {
        // Simulate detection time based on lighting and occlusion
        let baseTime = 35
        let lightingImpact = Int((1.0 - lightingLevel) * 20)
        let occlusionImpact = Int(occlusionLevel * 30)
        
        return baseTime + lightingImpact + occlusionImpact
    }
    
    private func calculateFailureRate() -> Int {
        // Simulate failure rate based on lighting and occlusion
        let baseRate = 5
        let lightingImpact = Int((1.0 - lightingLevel) * 15)
        let occlusionImpact = Int(occlusionLevel * 25)
        
        return baseRate + lightingImpact + occlusionImpact
    }
    
    private func getAccuracyColor() -> Color {
        let accuracy = calculateAccuracy()
        if accuracy >= 90 {
            return AppColors.success
        } else if accuracy >= 75 {
            return AppColors.warning
        } else {
            return AppColors.secondaryAccent
        }
    }
    
    private func getFailureColor() -> Color {
        let failure = calculateFailureRate()
        if failure <= 10 {
            return AppColors.success
        } else if failure <= 25 {
            return AppColors.warning
        } else {
            return AppColors.secondaryAccent
        }
    }
}

#Preview {
    SimulationView()
        .environmentObject(AppState())
} 