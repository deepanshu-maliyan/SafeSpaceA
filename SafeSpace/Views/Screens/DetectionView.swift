import SwiftUI
import AVFoundation

struct DetectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var flashOn = false
    @State private var isCameraInitialized = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main camera view
                cameraView
            }
            .navigationTitle("Detection")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initialize camera on appear
                initializeCamera()
            }
            .alert("Camera Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Camera view
    private var cameraView: some View {
        ZStack {
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
                    
                    // Camera controls overlay
                    VStack {
                        // Top status bar
                        HStack {
                            statusBadge
                            Spacer()
                            
                            Button(action: {
                                flashOn.toggle()
                                appState.cameraService.flashMode = flashOn ? .on : .off
                            }) {
                                Image(systemName: flashOn ? "bolt.fill" : "bolt.slash")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .disabled(!appState.cameraService.isFlashAvailable)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom camera controls
                        HStack {
                            Spacer()
                            
                            // Capture button
                            Button(action: {
                                appState.capturePhoto()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 70, height: 70)
                                    
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 80, height: 80)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 100)
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
                    
                    // Controls overlay for captured image
                    VStack {
                        // Top status bar
                        HStack {
                            statusBadge
                            Spacer()
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Detection results
                        if !appState.detectedObjects.isEmpty {
                            detectionResultsView
                                .padding(.horizontal)
                        }
                        
                        // Bottom controls for captured image
                        HStack(spacing: 40) {
                            // Retake button
                            Button(action: {
                                // Reset and allow new capture
                                appState.capturedImage = nil
                                appState.processedImage = nil
                                appState.detectedObjects = []
                                
                                // Restart camera session
                                if !appState.isDetecting {
                                    appState.startDetection()
                                }
                            }) {
                                VStack {
                                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    
                                    Text("Retake")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                            }
                            
                            // Use photo button
                            Button(action: {
                                // Process the image if not already processed
                                if appState.processedImage == nil {
                                    appState.processImage(appState.capturedImage!)
                                }
                            }) {
                                VStack {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    
                                    Text("Use Photo")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(AppColors.accent.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Detection results view
    private var detectionResultsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack {
                    Text("\(appState.detectedObjects.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Detected")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(Color.white.opacity(0.5))
                    .frame(height: 30)
                
                VStack {
                    Text("\(Int(appState.detectionAccuracy * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.success)
                    
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Divider()
                    .background(Color.white.opacity(0.5))
                    .frame(height: 30)
                
                VStack {
                    Text("35ms")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.accent)
                    
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(12)
        }
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
                .foregroundColor(.white)
            
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
    
    // Initialize camera
    private func initializeCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
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
            }
        }
    }
}

#Preview {
    DetectionView()
        .environmentObject(AppState())
} 
