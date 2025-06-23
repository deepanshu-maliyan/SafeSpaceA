import SwiftUI

struct DetectedObject: Identifiable {
    var id = UUID()
    var name: String
    var type: ObjectType
    var confidence: Double
    var boundingBox: CGRect
    var timestamp: Date
    
    var isHazard: Bool {
        return type == .fireExtinguisher || type == .oxygenTank
    }
}

enum ObjectType: String, CaseIterable, Identifiable {
    case toolbox = "Toolbox"
    case oxygenTank = "Oxygen Tank"
    case fireExtinguisher = "Fire Extinguisher"
    case laptop = "Laptop"
    case medicalKit = "Medical Kit"
    case waterContainer = "Water Container"
    case spaceHelmet = "Space Helmet"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .fireExtinguisher:
            return AppColors.secondaryAccent
        case .oxygenTank:
            return AppColors.warning
        case .toolbox:
            return AppColors.info
        case .laptop:
            return AppColors.accent
        case .medicalKit:
            return Color.green
        case .waterContainer:
            return Color.blue
        case .spaceHelmet:
            return Color.white
        }
    }
    
    var icon: String {
        switch self {
        case .fireExtinguisher:
            return "flame.fill"
        case .oxygenTank:
            return "bubble.fill"
        case .toolbox:
            return "hammer.fill"
        case .laptop:
            return "laptopcomputer"
        case .medicalKit:
            return "cross.case.fill"
        case .waterContainer:
            return "drop.fill"
        case .spaceHelmet:
            return "figure.walk.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .fireExtinguisher:
            return "Critical safety equipment for fire emergencies in space."
        case .oxygenTank:
            return "Essential life support equipment containing breathable oxygen."
        case .toolbox:
            return "Contains necessary tools for station maintenance and repairs."
        case .laptop:
            return "Computing equipment for communication and mission operations."
        case .medicalKit:
            return "Contains medical supplies for emergency treatment."
        case .waterContainer:
            return "Stores potable water for crew consumption."
        case .spaceHelmet:
            return "Part of EVA suit required for spacewalks."
        }
    }
}

// Sample data for preview and testing
extension DetectedObject {
    static var sampleObjects: [DetectedObject] = [
        DetectedObject(name: "Main Fire Extinguisher", type: .fireExtinguisher, confidence: 0.96, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3), timestamp: Date()),
        DetectedObject(name: "Oxygen Supply A", type: .oxygenTank, confidence: 0.88, boundingBox: CGRect(x: 0.5, y: 0.2, width: 0.15, height: 0.25), timestamp: Date()),
        DetectedObject(name: "Maintenance Kit", type: .toolbox, confidence: 0.92, boundingBox: CGRect(x: 0.7, y: 0.6, width: 0.2, height: 0.2), timestamp: Date()),
        DetectedObject(name: "Command Laptop", type: .laptop, confidence: 0.95, boundingBox: CGRect(x: 0.3, y: 0.7, width: 0.25, height: 0.2), timestamp: Date())
    ]
} 