import SwiftUI

struct DetectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var cameraImage: Image? = Image("camera_placeholder")
    @State private var flashOn: Bool = false
    @State private var zoomLevel: Double = 1.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Camera view
                ZStack {
                    // Camera preview
                    cameraPreview
                    
                    // Detected objects overlay
                    GeometryReader { geometry in
                        ZStack {
                            // Show bounding boxes for detected objects
                            ForEach(appState.isDetecting ? DetectedObject.sampleObjects : []) { object in
                                ObjectBoundingBoxView(
                                    detectedObject: object,
                                    parentSize: geometry.size
                                )
                            }
                        }
                    }
                    
                    // Status overlay
                    VStack {
                        HStack {
                            detectionStatusBadge
                            Spacer()
                        }
                        .padding()
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.black)
                
                // Camera controls
                cameraControls
            }
            .background(AppColors.background)
            .navigationTitle("Detection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Toggle settings panel
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(AppColors.text)
                    }
                }
            }
        }
    }
    
    private var cameraPreview: some View {
        GeometryReader { geometry in
            ZStack {
                if appState.isDetecting {
                    cameraImage?
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.black
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "camera.metering.none")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Camera preview will appear here")
                            .font(.callout)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                // Grid overlay
                ZStack {
                    Grid {
                        ForEach(0..<3) { _ in
                            GridRow {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5)
                                }
                            }
                        }
                    }
                }
                .opacity(0.4)
            }
        }
    }
    
    private var detectionStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isDetecting ? AppColors.success : AppColors.secondaryAccent)
                .frame(width: 8, height: 8)
            
            Text(appState.isDetecting ? "Detecting" : "Detection Paused")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.text)
            
            if appState.isDetecting {
                Text("YOLOv8")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.accent.opacity(0.2))
                    .cornerRadius(4)
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.7))
        .cornerRadius(20)
    }
    
    private var cameraControls: some View {
        VStack(spacing: 24) {
            // Detection stats
            if appState.isDetecting {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(appState.detectedObjects.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.text)
                        
                        Text("Detected")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Divider()
                        .background(AppColors.secondaryText)
                        .frame(height: 30)
                    
                    VStack {
                        Text("\(Int(appState.detectionAccuracy * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.success)
                        
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Divider()
                        .background(AppColors.secondaryText)
                        .frame(height: 30)
                    
                    VStack {
                        Text("35ms")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.accent)
                        
                        Text("Speed")
                            .font(.caption)
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding()
                .background(AppColors.cardBackground)
            }
            
            // Camera buttons
            HStack(spacing: 24) {
                Button(action: {
                    flashOn.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: flashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(flashOn ? AppColors.warning : AppColors.secondaryText)
                    }
                }
                
                Button(action: {
                    if appState.isDetecting {
                        appState.stopDetection()
                    } else {
                        appState.startDetection()
                        
                        // Simulate adding detected objects
                        if appState.detectedObjects.isEmpty {
                            for object in DetectedObject.sampleObjects {
                                appState.addDetectedObject(object)
                            }
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(appState.isDetecting ? AppColors.secondaryAccent : AppColors.accent)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: appState.isDetecting ? "stop.fill" : "camera.aperture")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(AppColors.background)
    }
}

#Preview {
    DetectionView()
        .environmentObject(AppState())
} 