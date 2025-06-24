import SwiftUI
import AVFoundation

struct DetectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var permissionRequested = false
    @State private var cameraAuthorized = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCameraInitialized = false
    @State private var flashOn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                if cameraAuthorized && isCameraInitialized {
                    cameraView
                } else {
                    setupView
                }
            }
            .navigationTitle("Detection")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Check permission status on appear
                checkCameraPermission()
            }
            .alert("Camera Error", isPresented: $showingAlert) {
                if !cameraAuthorized {
                    Button("Open Settings") {
                        openSettings()
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Camera view when permission is granted
    private var cameraView: some View {
        VStack(spacing: 0) {
            // Camera preview area
            ZStack {
                if appState.capturedImage == nil {
                    // Live camera preview
                    GeometryReader { geometry in
                        ZStack {
                            // Camera preview
                            if let _ = appState.cameraService.session {
                                CameraPreviewView(cameraService: appState.cameraService)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                
                                // Grid overlay
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
                                .opacity(0.4)
                            } else {
                                Color.black
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                    }
                } else {
                    // Captured image with detections
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
                            }
                        }
                    }
                }
                
                // Status overlay
                VStack {
                    HStack {
                        statusBadge
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
    }
    
    // Setup view when waiting for permission
    private var setupView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundColor(AppColors.accent)
            
            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.text)
            
            Text("SafeSpace needs camera access to detect objects in your space environment.")
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal)
            
            Button(action: {
                if !permissionRequested {
                    requestCameraPermission()
                } else if !cameraAuthorized {
                    openSettings()
                }
            }) {
                Text(permissionRequested && !cameraAuthorized ? "Open Settings" : "Allow Camera Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.accent)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
    
    private var statusBadge: some View {
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
                    appState.toggleFlash()
                    flashOn = appState.cameraService.flashMode != .off
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
    
    // Check current camera permission status
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            cameraAuthorized = true
            initializeCamera()
        case .denied, .restricted:
            cameraAuthorized = false
            permissionRequested = true
            alertMessage = "Camera access has been denied. Please enable it in Settings."
            showingAlert = true
        case .notDetermined:
            cameraAuthorized = false
            // Will request permission
        @unknown default:
            cameraAuthorized = false
        }
    }
    
    // Request camera permission
    private func requestCameraPermission() {
        permissionRequested = true
        
        // Use main actor to ensure UI updates happen on main thread
        Task { @MainActor in
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
            
            if granted {
                DispatchQueue.main.async {
                        cameraAuthorized = true
                        initializeCamera()
                    }
            } else {
                cameraAuthorized = false
                alertMessage = "Camera access has been denied. Please enable it in Settings."
                showingAlert = true
            }
        }
    }
    
    // Initialize camera after permission is granted
    private func initializeCamera() {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            alertMessage = "Camera access not granted."
            showingAlert = true
            return
        }

        appState.setupCamera { success in
            if success {
                self.isCameraInitialized = true
                self.appState.startDetection()
            } else {
                self.alertMessage = "Failed to initialize camera. Please try again."
                self.showingAlert = true
            }
        }
    }

    // Open app settings
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        UIApplication.shared.open(settingsUrl)
    }
}

#Preview {
    DetectionView()
        .environmentObject(AppState())
} 
