//
//  SpeechBubble.swift
//  H&I Personalized Medicine
//
//  Created by Marcus Grant on 8/18/23.
//

import SwiftUI

struct SpeechBubble: Shape {
    var radius: CGFloat = 15.0
    var triangleSize: CGSize = CGSize(width: 20, height: 10)

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        
        // Top-left corner
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius,
                    startAngle: Angle(degrees: -180),
                    endAngle: Angle(degrees: -90),
                    clockwise: false)
        
        // Top-right corner
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                    radius: radius,
                    startAngle: Angle(degrees: -90),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        
        // Bottom-right corner
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius - triangleSize.height),
                    radius: radius,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)

        // Add triangle for the "speech" part
        path.addLine(to: CGPoint(x: (rect.midX + triangleSize.width/2), y: rect.maxY - triangleSize.height))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: (rect.midX - triangleSize.width/2), y: rect.maxY - triangleSize.height))
        
        // Bottom-left corner
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius - triangleSize.height),
                    radius: radius,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)
        
        return path
    }
}


struct SpeechBubble_Previews: PreviewProvider {
    static var previews: some View {
        SpeechBubble()
    }
}
