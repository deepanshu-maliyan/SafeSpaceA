import Foundation
import AVFoundation
import UIKit
import Combine
import SwiftUI

class CameraService: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isCameraReady = false
    @Published var error: CameraError?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var isFlashAvailable = true
    
    var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    // Setup camera - assumes permission is already granted
    func setup(completion: @escaping (Bool) -> Void) {
        // Make sure we're authorized before proceeding
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard authStatus == .authorized else {
            DispatchQueue.main.async {
                self.error = (authStatus == .denied) ? .deniedAuthorization : .restrictedAuthorization
                completion(false)
            }
            return
        }

        
        // Create a new session on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // Create session
            let session = AVCaptureSession()
            
            do {
                // Configure the session
                session.beginConfiguration()
                
                // Get camera device
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    DispatchQueue.main.async {
                        self.error = .cameraUnavailable
                        completion(false)
                    }
                    return
                }
                
                // Create device input
                let input = try AVCaptureDeviceInput(device: device)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(self.output) {
                    session.addOutput(self.output)
                }
                
                // Commit configuration
                session.commitConfiguration()
                
                // Configure preview layer
                self.previewLayer.session = session
                self.previewLayer.videoGravity = .resizeAspectFill
                
                // Check if flash is available
                self.isFlashAvailable = device.hasFlash
                
                // Store session
                self.session = session
                
                // Start session on background thread
                session.startRunning()
                
                DispatchQueue.main.async {
                    self.isCameraReady = true
                    completion(true)
                }
                
            } catch {
                DispatchQueue.main.async {
                    print("Camera setup error: \(error.localizedDescription)")
                    self.error = .cameraUnavailable
                    completion(false)
                }
            }
        }
    }
    
    func capturePhoto() {
        // Make sure we have a valid session
        guard let session = session, session.isRunning else {
            error = .captureError
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        
        // Configure flash
        if isFlashAvailable {
            photoSettings.flashMode = flashMode
        }
        
        // Create delegate to handle photo capture
        self.delegate = PhotoCaptureDelegate { [weak self] image in
            guard let self = self, let image = image else {
                self?.error = .captureError
                return
            }
            
            // Update on main thread
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
        
        // Capture photo
        if let delegate = self.delegate as? PhotoCaptureDelegate {
            output.capturePhoto(with: photoSettings, delegate: delegate)
        }
    }
    
    func toggleFlash() {
        guard isFlashAvailable else { return }
        
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
    }
    
    func stopSession() {
        // Stop session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.stopRunning()
        }
    }
    
    func resumeSession() {
        // Make sure we're authorized
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            return
        }
        
        // Resume session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.startRunning()
        }
    }
}

// Photo capture delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Could not create image from photo data")
            completion(nil)
            return
        }
        
        completion(image)
    }
}

// Camera Preview View using UIViewRepresentable
struct CameraPreviewView: UIViewRepresentable {
    let cameraService: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        // Only add the preview layer if the session exists and is running
        if let session = cameraService.session, session.isRunning {
            cameraService.previewLayer.frame = view.bounds
            view.layer.addSublayer(cameraService.previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update frame on bounds change
        cameraService.previewLayer.frame = uiView.bounds
    }
}

// Camera errors
enum CameraError: Error, LocalizedError {
    case deniedAuthorization
    case restrictedAuthorization
    case cameraUnavailable
    case captureError
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .deniedAuthorization:
            return "Camera access has been denied. Please enable it in Settings."
        case .restrictedAuthorization:
            return "Camera access is restricted"
        case .cameraUnavailable:
            return "Camera is unavailable"
        case .captureError:
            return "Failed to capture photo"
        case .saveFailed:
            return "Failed to save photo"
        }
    }
} 
