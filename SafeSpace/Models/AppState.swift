import SwiftUI
import Combine

class AppState: ObservableObject {
    // Services
    let mlModelService = MLModelService()
    let cameraService = CameraService()
    
    // Detection related
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isDetecting: Bool = false
    @Published var detectionAccuracy: Double = 0.85
    @Published var detectionSpeed: Double = 0.95
    
    // Image related
    @Published var capturedImage: UIImage?
    @Published var processedImage: UIImage?
    @Published var simulationImage: UIImage?
    
    // System status
    @Published var systemStatus: SystemStatus = .online
    @Published var batteryLevel: Double = 0.87
    @Published var processingPower: Double = 0.72
    @Published var alerts: [Alert] = []
    
    // Simulation settings
    @Published var simulationLighting: Double = 0.5
    @Published var simulationOcclusion: Double = 0.0
    @Published var simulationEnvironment: SimulationEnvironment = .normalStation
    
    // Stats
    @Published var objectsFound: [ObjectType: Int] = [:]
    @Published var missionStartTime: Date = Date()
    @Published var detectionHistory: [DetectedObject] = []
    
    // Camera setup status
    @Published var isCameraSetup: Bool = false
    
    // For demo purposes
    init() {
        setupDemoStats()
        setupDemoAlerts()
        
        // Listen to captured images
        cameraService.$capturedImage
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] image in
                self?.handleCapturedImage(image)
            }
            .store(in: &cancellables)
            
        // Listen to ML processing results
        mlModelService.$detectedObjects
            .receive(on: RunLoop.main)
            .sink { [weak self] objects in
                self?.updateDetections(objects)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func setupCamera(completion: @escaping (Bool) -> Void) {
        if !isCameraSetup {
            cameraService.setup { [weak self] success in
                guard let self = self else { return }
                self.isCameraSetup = success
                completion(success)
            }
        } else {
            completion(true)
        }
    }
    
    func startDetection() {
        isDetecting = true
        if capturedImage == nil {
            // When no image is captured yet, start the camera session
            cameraService.resumeSession()
        }
    }
    
    func stopDetection() {
        isDetecting = false
        cameraService.stopSession()
    }
    
    func capturePhoto() {
        cameraService.capturePhoto()
    }
    
    func toggleFlash() {
        cameraService.toggleFlash()
    }
    
    func handleCapturedImage(_ image: UIImage) {
        self.capturedImage = image
        
        // Process the image with ML model to detect objects
        processImage(image)
    }
    
    func processImage(_ image: UIImage) {
        mlModelService.processImage(image) { [weak self] in
            guard let self = self else { return }
            
            self.processedImage = self.mlModelService.processedImage
            
            // Update detection stats based on processing results
            if !self.mlModelService.detectedObjects.isEmpty {
                self.updateDetectionStats()
            }
        }
    }
    
    func runSimulation(with image: UIImage) {
        guard let capturedImage = capturedImage ?? simulationImage else { return }
        
        // Apply lighting and occlusion effects
        let processedImage = mlModelService.processImageWithEffects(
            capturedImage,
            lightingLevel: simulationLighting,
            occlusionLevel: simulationOcclusion
        )
        
        // Store processed image for display
        simulationImage = processedImage
        
        // Process the image with ML model
        mlModelService.processImage(processedImage) { [weak self] in
            guard let self = self else { return }
            
            // Update with processed image that has bounding boxes
            self.simulationImage = self.mlModelService.processedImage
            
            // Update stats
            if !self.mlModelService.detectedObjects.isEmpty {
                self.updateDetectionStats()
            }
        }
    }
    
    func updatePreviewWithSettings() {
        guard let image = capturedImage ?? simulationImage else { return }
        
        // Just update the preview with lighting/occlusion adjustments without ML processing
        simulationImage = mlModelService.processImageWithEffects(
            image,
            lightingLevel: simulationLighting,
            occlusionLevel: simulationOcclusion
        )
    }
    
    private func updateDetections(_ objects: [DetectedObject]) {
        detectedObjects = objects
        
        // Log new detected objects in history
        for object in objects {
            detectionHistory.append(object)
            
            if object.isHazard {
                let alert = Alert(
                    title: "\(object.type.rawValue) Detected",
                    message: "A \(object.type.rawValue.lowercased()) has been detected with \(Int(object.confidence * 100))% confidence.",
                    severity: .warning,
                    timestamp: Date()
                )
                addAlert(alert)
            }
        }
    }
    
    func addDetectedObject(_ object: DetectedObject) {
        detectedObjects.insert(object, at: 0)
        detectionHistory.append(object)
        
        // Update stats
        let currentCount = objectsFound[object.type] ?? 0
        objectsFound[object.type] = currentCount + 1
        
        // Generate alert if needed
        if object.isHazard {
            let alert = Alert(
                title: "\(object.type.rawValue) Detected",
                message: "A \(object.type.rawValue.lowercased()) has been detected with \(Int(object.confidence * 100))% confidence.",
                severity: .warning,
                timestamp: Date()
            )
            addAlert(alert)
        }
    }
    
    private func updateDetectionStats() {
        // Update accuracy estimate based on detected objects' confidence
        if !mlModelService.detectedObjects.isEmpty {
            let averageConfidence = mlModelService.detectedObjects.map { $0.confidence }.reduce(0, +) / Double(mlModelService.detectedObjects.count)
            detectionAccuracy = max(0.6, min(0.99, averageConfidence))
        }
        
        // Update detected object counts
        for object in mlModelService.detectedObjects {
            let currentCount = objectsFound[object.type] ?? 0
            objectsFound[object.type] = currentCount + 1
        }
    }
    
    func addAlert(_ alert: Alert) {
        alerts.insert(alert, at: 0)
        // In a real app, you might want to trigger a notification here
    }
    
    private func setupDemoStats() {
        for type in ObjectType.allCases {
            objectsFound[type] = Int.random(in: 1...5)
        }
        
        // Set mission to have started a random time between 1 and 12 hours ago
        let hoursAgo = Double.random(in: 1...12)
        missionStartTime = Date().addingTimeInterval(-hoursAgo * 3600)
    }
    
    private func setupDemoAlerts() {
        alerts = [
            Alert(title: "Model Updated", message: "Object detection model has been updated to v2.1.", severity: .info, timestamp: Date().addingTimeInterval(-3600)),
            Alert(title: "Fire Extinguisher Missing", message: "Fire extinguisher in Sector B not detected during last scan.", severity: .warning, timestamp: Date().addingTimeInterval(-7200))
        ]
    }
}

enum SystemStatus: String {
    case online = "Online"
    case degraded = "Degraded"
    case offline = "Offline"
    case updating = "Updating"
    
    var color: Color {
        switch self {
        case .online:
            return AppColors.success
        case .degraded:
            return AppColors.warning
        case .offline:
            return AppColors.danger
        case .updating:
            return AppColors.info
        }
    }
}

enum SimulationEnvironment: String, CaseIterable {
    case normalStation = "Normal Station"
    case dimLighting = "Dim Lighting"
    case emergencyLighting = "Emergency Lighting"
    case maintenanceMode = "Maintenance Mode"
    case sleepQuarters = "Sleep Quarters"
}

struct Alert: Identifiable {
    var id = UUID()
    var title: String
    var message: String
    var severity: AlertSeverity
    var timestamp: Date
    var isRead: Bool = false
}

enum AlertSeverity: String {
    case info, warning, critical
    
    var color: Color {
        switch self {
        case .info:
            return AppColors.info
        case .warning:
            return AppColors.warning
        case .critical:
            return AppColors.danger
        }
    }
    
    var icon: String {
        switch self {
        case .info:
            return "info.circle"
        case .warning:
            return "exclamationmark.triangle"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
} 