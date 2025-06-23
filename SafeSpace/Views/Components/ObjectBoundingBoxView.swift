import SwiftUI

struct ObjectBoundingBoxView: View {
    var detectedObject: DetectedObject
    var parentSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            let box = calculateBoundingBox(in: geometry.size)
            
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .stroke(detectedObject.type.color, lineWidth: 2)
                    .background(detectedObject.type.color.opacity(0.1))
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Image(systemName: detectedObject.type.icon)
                            .foregroundColor(detectedObject.type.color)
                        
                        Text(detectedObject.type.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(detectedObject.type.color)
                        
                        Spacer()
                        
                        Text("\(Int(detectedObject.confidence * 100))%")
                            .font(.caption2)
                            .padding(2)
                            .background(detectedObject.type.color.opacity(0.3))
                            .cornerRadius(4)
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                }
                .frame(width: box.width)
            }
            .position(x: box.midX, y: box.midY)
            .frame(width: box.width, height: box.height)
        }
    }
    
    private func calculateBoundingBox(in size: CGSize) -> CGRect {
        let x = detectedObject.boundingBox.origin.x * size.width
        let y = detectedObject.boundingBox.origin.y * size.height
        let width = detectedObject.boundingBox.width * size.width
        let height = detectedObject.boundingBox.height * size.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        ForEach(DetectedObject.sampleObjects) { object in
            ObjectBoundingBoxView(detectedObject: object, parentSize: CGSize(width: 400, height: 600))
        }
    }
    .frame(width: 400, height: 600)
} 