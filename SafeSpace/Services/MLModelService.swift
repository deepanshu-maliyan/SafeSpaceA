import Foundation
import CoreML
import Vision
import UIKit
import SwiftUI

class MLModelService: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var processedImage: UIImage?
    @Published var isProcessing: Bool = false
    
    private var visionModel: VNCoreMLModel?
    
    init() {
        setupModel()
    }
    
    private func setupModel() {
        do {
            // Load the Core ML model
            if let modelURL = Bundle.main.url(forResource: "best", withExtension: "mlmodelc") {
                visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            } else {
                print("Failed to find model URL")
            }
        } catch {
            print("Failed to create Vision model: \(error)")
        }
    }
    
    // Process image for object detection
    func processImage(_ image: UIImage, completionHandler: @escaping () -> Void) {
        guard let visionModel = visionModel else {
            print("Vision model not initialized")
            return
        }
        
        isProcessing = true
        detectedObjects = []
        
        guard let cgImage = image.cgImage else { 
            print("Failed to get CGImage")
            isProcessing = false
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Vision request failed: \(error)")
                self.isProcessing = false
                return
            }
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.handleDetectionResults(results, imageSize: image.size)
                
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.processedImage = self.drawBoundingBoxes(on: image)
                    completionHandler()
                }
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform detection: \(error)")
            isProcessing = false
        }
    }
    
    // Handle detection results and convert to our app's DetectedObject model
    private func handleDetectionResults(_ results: [VNRecognizedObjectObservation], imageSize: CGSize) {
        var newObjects: [DetectedObject] = []
        
        for observation in results {
            guard let topLabelObservation = observation.labels.first else { continue }
            
            // Map the detected label to our app's ObjectType
            let label = topLabelObservation.identifier.lowercased()
            let confidence = Double(topLabelObservation.confidence)
            
            if confidence < 0.5 {
                // Skip low confidence detections
                continue
            }
            
            // Map the label to our app's ObjectType
            var objectType: ObjectType?
            if label.contains("fire") || label.contains("extinguisher") {
                objectType = .fireExtinguisher
            } else if label.contains("oxygen") || label.contains("tank") {
                objectType = .oxygenTank
            } else if label.contains("tool") || label.contains("box") || label.contains("toolbox") {
                objectType = .toolbox
            }
            
            guard let type = objectType else { continue }
            
            // Create a DetectedObject
            let object = DetectedObject(
                name: "\(type.rawValue) #\(newObjects.count + 1)",
                type: type,
                confidence: confidence,
                boundingBox: CGRect(
                    x: observation.boundingBox.minX,
                    y: 1 - observation.boundingBox.maxY, // Convert from Vision coordinates to UIKit coordinates
                    width: observation.boundingBox.width,
                    height: observation.boundingBox.height
                ),
                timestamp: Date()
            )
            
            newObjects.append(object)
        }
        
        DispatchQueue.main.async {
            self.detectedObjects = newObjects
        }
    }
    
    // Draw bounding boxes on the processed image
    private func drawBoundingBoxes(on image: UIImage) -> UIImage {
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        // Draw the original image
        image.draw(at: CGPoint.zero)
        
        let context = UIGraphicsGetCurrentContext()!
        
        for object in detectedObjects {
            // Get coordinates in image space
            let boundingBox = object.boundingBox
            let rect = CGRect(
                x: boundingBox.minX * imageSize.width,
                y: boundingBox.minY * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
            
            // Set up colors based on object type
            let typeColor = UIColor(object.type.color)
            
            // Draw bounding box
            context.setLineWidth(3.0)
            context.setStrokeColor(typeColor.cgColor)
            context.stroke(rect)
            
            // Draw semi-transparent background for label
            let labelRect = CGRect(x: rect.minX, y: rect.minY - 20, width: rect.width, height: 20)
            context.setFillColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor)
            context.fill(labelRect)
            
            // Draw label text
            let confidenceText = "\(object.type.rawValue): \(Int(object.confidence * 100))%"
            let textAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .bold),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            
            let textSize = confidenceText.size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: rect.minX + 5,
                y: rect.minY - 18,
                width: textSize.width,
                height: textSize.height
            )
            
            confidenceText.draw(in: textRect, withAttributes: textAttributes)
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage ?? image
    }
    
    // Apply lighting adjustment to image
    func adjustLighting(_ image: UIImage, level: Double) -> UIImage {
        let ciImage = CIImage(image: image)
        guard let ciImage = ciImage else { return image }
        
        let filter = CIFilter(name: "CIExposureAdjust")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        // Map 0-1 lighting level to exposure values (-1 to 1)
        let exposureValue = (level - 0.5) * 2
        filter?.setValue(exposureValue, forKey: kCIInputEVKey)
        
        guard let outputImage = filter?.outputImage else { return image }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Apply occlusion effect to image
    func applyOcclusion(_ image: UIImage, level: Double) -> UIImage {
        if level <= 0 {
            return image
        }
        
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Draw the original image
        image.draw(at: CGPoint.zero)
        
        // Apply vignette effect for occlusion
        if level > 0 {
            let context = UIGraphicsGetCurrentContext()!
            let outerRadius = min(size.width, size.height) * 0.8
            let innerRadius = outerRadius * (1 - CGFloat(level * 0.8))
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            // Create gradient for vignette
            let colors = [UIColor.clear.cgColor, UIColor(white: 0, alpha: CGFloat(level)).cgColor]
            let colorLocations: [CGFloat] = [0, 1]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: colorLocations
            )!
            
            context.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: innerRadius,
                endCenter: center,
                endRadius: outerRadius,
                options: .drawsBeforeStartLocation
            )
        }
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage ?? image
    }
    
    // Apply both lighting and occlusion
    func processImageWithEffects(_ image: UIImage, lightingLevel: Double, occlusionLevel: Double) -> UIImage {
        let lightingAdjusted = adjustLighting(image, level: lightingLevel)
        let occlusionApplied = applyOcclusion(lightingAdjusted, level: occlusionLevel)
        return occlusionApplied
    }
} 