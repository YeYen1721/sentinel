//
//  AppIconGenerator.swift
//  Sentinel
//
//  Programmatic app icon generator for shield design
//

import SwiftUI

struct ShieldIconView: View {
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.27, green: 0.55, blue: 0.96) // #4588F5 blue

            // Shield shape
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height

                Path { path in
                    // Shield outline
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.05))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.15))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.55))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.5, y: height * 0.95),
                        control: CGPoint(x: width * 0.85, y: height * 0.75)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.15, y: height * 0.55),
                        control: CGPoint(x: width * 0.15, y: height * 0.75)
                    )
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.15))
                    path.closeSubpath()
                }
                .fill(Color(red: 0.27, green: 0.55, blue: 0.96))

                // White half (right side)
                Path { path in
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.05))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.15))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.55))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.5, y: height * 0.95),
                        control: CGPoint(x: width * 0.85, y: height * 0.75)
                    )
                    path.closeSubpath()
                }
                .fill(.white)

                // Border outline
                Path { path in
                    path.move(to: CGPoint(x: width * 0.5, y: height * 0.05))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.15))
                    path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.55))
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.5, y: height * 0.95),
                        control: CGPoint(x: width * 0.85, y: height * 0.75)
                    )
                    path.addQuadCurve(
                        to: CGPoint(x: width * 0.15, y: height * 0.55),
                        control: CGPoint(x: width * 0.15, y: height * 0.75)
                    )
                    path.addLine(to: CGPoint(x: width * 0.15, y: height * 0.15))
                    path.closeSubpath()
                }
                .stroke(Color(red: 0.27, green: 0.55, blue: 0.96), lineWidth: width * 0.02)
            }
        }
    }
}

// Preview
#Preview {
    ShieldIconView()
        .frame(width: 1024, height: 1024)
}
