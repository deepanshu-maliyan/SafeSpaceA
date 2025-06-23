import SwiftUI
import Combine

class AppState: ObservableObject {
    // Detection related
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isDetecting: Bool = false
    @Published var detectionAccuracy: Double = 0.85
    @Published var detectionSpeed: Double = 0.95
    
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
    
    // For demo purposes
    init() {
        setupDemoStats()
        setupDemoAlerts()
    }
    
    func startDetection() {
        isDetecting = true
        // In a real app, you'd start the camera and ML pipeline here
    }
    
    func stopDetection() {
        isDetecting = false
    }
    
    func addDetectedObject(_ object: DetectedObject) {
        detectedObjects.insert(object, at: 0)
        
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