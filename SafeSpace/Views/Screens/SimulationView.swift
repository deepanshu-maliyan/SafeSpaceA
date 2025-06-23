import SwiftUI
import PhotosUI

struct SimulationView: View {
    @EnvironmentObject var appState: AppState
    @State private var simulationActive = false
    @State private var selectedEnvironment: SimulationEnvironment = .normalStation
    @State private var lightingLevel: Double = 0.5
    @State private var occlusionLevel: Double = 0.0
    @State private var isImagePickerPresented = false
    @State private var photoPickerItem: PhotosPickerItem?
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $photoPickerItem, matching: .images) {
                        Image(systemName: "photo")
                            .foregroundColor(AppColors.text)
                    }
                    .onChange(of: photoPickerItem) { newValue in
                        if let newValue {
                            loadTransferable(from: newValue)
                        }
                    }
                }
            }
        }
    }
    
    private var simulationPreview: some View {
        VStack(spacing: 8) {
            ZStack {
                if let simulationImage = appState.simulationImage {
                    // Display processed image
                    Image(uiImage: simulationImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 240)
                        .cornerRadius(12)
                } else if let capturedImage = appState.capturedImage {
                    // Display captured image with adjustments
                    let adjustedImage = appState.mlModelService.processImageWithEffects(
                        capturedImage,
                        lightingLevel: lightingLevel,
                        occlusionLevel: occlusionLevel
                    )
                    Image(uiImage: adjustedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 240)
                        .cornerRadius(12)
                } else {
                    // Display default placeholder
                    Rectangle()
                        .fill(Color.black)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.metering.none")
                                    .font(.system(size: 48))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("No image selected")
                                    .font(.callout)
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.top, 8)
                            }
                        )
                        .frame(height: 240)
                        .cornerRadius(12)
                }
                
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
                
                // Processing indicator
                if appState.mlModelService.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
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
                        appState.simulationImage = nil
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
            .disabled(appState.capturedImage == nil && appState.simulationImage == nil)
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
                    value: "\(appState.detectedObjects.count)",
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
            
            // Detected objects list
            ObjectListView(
                objects: appState.detectedObjects,
                title: "Detected Objects"
            )
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
                    .onChange(of: value.wrappedValue) { _ in
                        // Update preview when slider changes
                        if !simulationActive {
                            updatePreview()
                        }
                    }
                
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
                
                // Update preview with new settings
                if !simulationActive {
                    updatePreview()
                }
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
        
        if let capturedImage = appState.capturedImage {
            // Run ML model on adjusted image
            let adjustedImage = appState.mlModelService.processImageWithEffects(
                capturedImage,
                lightingLevel: lightingLevel,
                occlusionLevel: occlusionLevel
            )
            
            // Set this as temporary preview
            appState.simulationImage = adjustedImage
            
            // Process with ML model
            appState.mlModelService.processImage(adjustedImage) { 
                // Update with actual detection results
                appState.simulationImage = appState.mlModelService.processedImage
            }
        }
    }
    
    private func updatePreview() {
        appState.updatePreviewWithSettings()
    }
    
    private func loadTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        appState.capturedImage = image
                        
                        // Update preview with current settings
                        updatePreview()
                    }
                case .failure(let error):
                    print("Photo picker error: \(error)")
                }
            }
        }
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
        
        // Make sure these values are synced with the app state
        appState.simulationLighting = lightingLevel
        appState.simulationOcclusion = occlusionLevel
    }
    
    private func calculateBrightness() -> Double {
        return (lightingLevel - 0.5) * 0.7
    }
    
    private func calculateAccuracy() -> Int {
        // Use real detection confidence if available
        if !appState.detectedObjects.isEmpty {
            let avgConfidence = appState.detectedObjects.map { $0.confidence }.reduce(0, +) / Double(appState.detectedObjects.count)
            return Int(avgConfidence * 100)
        }
        
        // Simulate accuracy based on lighting and occlusion
        let baseAccuracy: Double = 92
        let lightingImpact = (1.0 - lightingLevel) * 20
        let occlusionImpact = occlusionLevel * 30
        
        let adjustedAccuracy = baseAccuracy - lightingImpact - occlusionImpact
        return max(60, min(99, Int(adjustedAccuracy)))
    }
    
    private func calculateObjectsFound() -> Int {
        // Use real detection count if available
        if simulationActive && !appState.detectedObjects.isEmpty {
            return appState.detectedObjects.count
        }
        
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
        // Calculate failure rate based on detection accuracy
        return 100 - calculateAccuracy()
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