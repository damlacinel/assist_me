//
//  DynamicButton.swift
//  Memory Support
//
//  Created by Damla Cinel on 11.09.25.
//

import SwiftUI

// Dynamic styles (responsive to screen size)
// Use these for real-life usage across 40/41/44/45/49 mm watches.


public struct ADStandardButtonDynamic: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            // Side ≈ 30% of available width, clamped 56–84 pt for accessibility & consistency
            let side = min(84, max(56, geo.size.width * 0.30))

            configuration.label
                .frame(width: side, height: side)
                .background(configuration.isPressed ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .font(.system(size: side * 0.23, weight: .semibold))
                .clipShape(RoundedRectangle(cornerRadius: side * 0.25))
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
                .contentShape(Rectangle()) // better tap hitbox
        }
    }
}

public struct MultipleChoiceButtonDynamic: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            // Height ≈ 12% of available height, clamped 44–72 pt
            let minHeight = min(72, max(44, geo.size.height * 0.12))

            configuration.label
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: minHeight)
                .background(configuration.isPressed ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .font(.system(size: max(14, minHeight * 0.35), weight: .medium))
                .cornerRadius(minHeight * 0.25)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
                .contentShape(Rectangle())
        }
    }
}

/*
 Note:
 >> By default, the prototype styles (ADStandardButtonStyle, MultipleChoiceButtonStyle) are used.
 >> Those are fixed-size implementations, tested on the 45 mm Apple Watch.
 >> For real-world usage across all watch sizes, these dynamic styles can be used instead.

 Example usage:
 ------------------------------------------------
 // Prototype (default in project):
 Button("Start") { ... }
     .buttonStyle(ADStandardButtonStyle())

 // Dynamic replacement:
 Button("Start") { ... }
     .buttonStyle(ADStandardButtonDynamic())

 Button("Option A") { ... }
     .buttonStyle(MultipleChoiceButtonDynamic())
 ------------------------------------------------

 >> This way you can switch gradually: keep prototypes for quick testing,
    use dynamics for production-ready, size-independent layouts.
*/
