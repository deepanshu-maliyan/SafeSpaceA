import SwiftUI
import AVFoundation

struct DetectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var cameraError: String?
    @State private var flashOn: Bool = false
    @State private var zoomLevel: Double = 1.0
    @State private var isCameraInitialized: Bool = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Camera view
                ZStack {
                    if isCameraInitialized {
                        // Camera preview when no image is captured
                        if appState.capturedImage == nil {
                            cameraPreview
                        } else {
                            // Show captured image with detections
                            capturedImageView
                        }
                    } else {
                        // Setup camera view
                        setupView
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
                        // Reset and allow new capture
                        appState.capturedImage = nil
                        appState.processedImage = nil
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(appState.capturedImage != nil ? AppColors.text : AppColors.secondaryText)
                    }
                    .disabled(appState.capturedImage == nil)
                }
            }
            .onAppear {
                if !isCameraInitialized {
                    checkCameraPermission()
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                if appState.cameraService.authorizationStatus == .denied {
                    Button("Open Settings", action: {
                        openSettings()
                    })
                    Button("Cancel", role: .cancel) { }
                } else {
                    Button("OK", role: .cancel) { }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var cameraPreview: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                if appState.isCameraSetup, appState.cameraService.session != nil {
                    CameraPreviewView(cameraService: appState.cameraService)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Color.black
                        .frame(width: geometry.size.width, height: geometry.size.height)
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
    
    private var capturedImageView: some View {
        GeometryReader { geometry in
            ZStack {
                if let processedImage = appState.processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else if let capturedImage = appState.capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    
                    if appState.mlModelService.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accent))
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                    }
                } else {
                    Color.black
                }
            }
        }
    }
    
    private var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.secondaryText)
            
            Text(permissionStatusTitle)
                .font(.headline)
                .foregroundColor(AppColors.text)
            
            Text(permissionStatusMessage)
                .font(.subheadline)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if appState.cameraService.authorizationStatus == .denied {
                    openSettings()
                } else {
                    checkCameraPermission()
                }
            }) {
                Text(appState.cameraService.authorizationStatus == .denied ? "Open Settings" : "Setup Camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    private var permissionStatusTitle: String {
        switch appState.cameraService.authorizationStatus {
        case .authorized:
            return "Setting Up Camera"
        case .denied:
            return "Camera Access Denied"
        case .restricted:
            return "Camera Access Restricted"
        case .notDetermined:
            return "Camera Access Required"
        @unknown default:
            return "Camera Access Required"
        }
    }
    
    private var permissionStatusMessage: String {
        switch appState.cameraService.authorizationStatus {
        case .authorized:
            return "Initializing camera for object detection"
        case .denied:
            return "SafeSpace needs camera access to detect objects. Please enable camera access in Settings."
        case .restricted:
            return "Camera access is restricted on this device."
        case .notDetermined:
            return "SafeSpace needs camera access to detect objects"
        @unknown default:
            return "SafeSpace needs camera access to detect objects"
        }
    }
    
    private var detectionStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.isDetecting ? AppColors.success : AppColors.secondaryAccent)
                .frame(width: 8, height: 8)
            
            Text(appState.isDetecting ? 
                 (appState.capturedImage == nil ? "Ready to Capture" : "Detection Complete") : 
                 "Detection Paused")
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
            if appState.capturedImage != nil {
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
                    if appState.cameraService.isFlashAvailable {
                        appState.toggleFlash()
                        flashOn = appState.cameraService.flashMode != .off
                    }
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
                .disabled(!appState.cameraService.isFlashAvailable || appState.capturedImage != nil)
                
                Button(action: {
                    if appState.isDetecting {
                        // If we already have a captured image, stop detection
                        if appState.capturedImage != nil {
                            appState.stopDetection()
                        } else {
                            // Otherwise capture a photo
                            appState.capturePhoto()
                        }
                    } else {
                        appState.startDetection()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(appState.capturedImage != nil ? 
                                  (appState.isDetecting ? AppColors.secondaryAccent : AppColors.accent) : 
                                  (appState.isDetecting ? AppColors.accent : AppColors.cardBackground))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: appState.capturedImage != nil ? 
                              (appState.isDetecting ? "stop.fill" : "play.fill") : 
                              (appState.isDetecting ? "camera.aperture" : "camera"))
                            .font(.system(size: 30))
                            .foregroundColor(appState.isDetecting || appState.capturedImage != nil ? .white : AppColors.secondaryText)
                    }
                }
                .disabled(!isCameraInitialized)
                
                Button(action: {
                    // Reset and allow new capture
                    appState.capturedImage = nil
                    appState.processedImage = nil
                    
                    if !appState.isDetecting {
                        appState.startDetection()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(appState.capturedImage != nil ? AppColors.text : AppColors.secondaryText)
                    }
                }
                .disabled(appState.capturedImage == nil)
            }
            .padding(.vertical)
        }
        .background(AppColors.background)
    }
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupCamera()
                } else {
                    self.alertTitle = "Camera Access Denied"
                    self.alertMessage = "SafeSpace needs camera access to detect objects. Please enable it in Settings."
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func setupCamera() {
        // Ensure we're on the main thread when setting up camera
        DispatchQueue.main.async {
            appState.setupCamera { success in
                if success {
                    self.isCameraInitialized = true
                } else if let error = appState.cameraService.error {
                    self.alertTitle = "Camera Error"
                    self.alertMessage = error.errorDescription ?? "Unknown camera error"
                    self.showingAlert = true
                } else {
                    self.alertTitle = "Camera Error"
                    self.alertMessage = "Unknown camera error"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    DetectionView()
        .environmentObject(AppState())
} 