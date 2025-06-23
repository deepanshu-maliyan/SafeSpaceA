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
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    
    var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    override init() {
        super.init()
        // Check initial authorization status
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    // Setup and configuration
    func setup(completion: @escaping (Bool) -> Void) {
        checkPermissions { [weak self] hasPermission in
            guard let self = self else { return }
            if hasPermission {
                self.setupCamera { success in
                    DispatchQueue.main.async {
                        self.isCameraReady = success
                        completion(success)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.error = .deniedAuthorization
                    completion(false)
                }
            }
        }
    }
    
    func checkPermissions(completion: @escaping (Bool) -> Void) {
        // Update the current status
        self.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch self.authorizationStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func setupCamera(completion: @escaping (Bool) -> Void) {
        // Ensure we're on a background thread for camera setup
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            
            // Create a new session
            let session = AVCaptureSession()
            session.beginConfiguration()
            
            // Check for camera device
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                    completion(false)
                }
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(self.output) {
                    session.addOutput(self.output)
                }
                
                session.commitConfiguration()
                
                self.previewLayer.session = session
                self.previewLayer.videoGravity = .resizeAspectFill
                
                // Check if flash is available
                self.isFlashAvailable = device.hasFlash
                
                self.session = session
                
                // Start the session on a background thread
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
                
            } catch {
                print("Failed to setup camera: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = .cameraUnavailable
                    completion(false)
                }
            }
        }
    }
    
    func capturePhoto() {
        guard let session = session, session.isRunning else {
            error = .captureError
            return
        }
        
        let photoSettings = AVCapturePhotoSettings()
        
        // Configure flash
        if isFlashAvailable {
            photoSettings.flashMode = flashMode
        }
        
        self.delegate = PhotoCaptureDelegate { [weak self] image in
            guard let image = image else {
                self?.error = .captureError
                return
            }
            DispatchQueue.main.async {
                self?.capturedImage = image
            }
        }
        
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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.stopRunning()
        }
    }
    
    func resumeSession() {
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
        
        // Only add the preview layer if the session exists
        if cameraService.session != nil {
            cameraService.previewLayer.frame = view.bounds
            view.layer.addSublayer(cameraService.previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
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