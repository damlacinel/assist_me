//
//  Button.swift
//  Memory Support
//
//  Created by Damla Cinel on 04.03.25.
//

import SwiftUI

//Standard, commonly used button for navigation purposes
//>> Example: "Start" button in cognitive games
struct ADStandardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 60, height: 60)
            .background(configuration.isPressed ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .font(.system(size: 14, weight: .semibold))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}


//Button style for multiple choice options
//>> Example: answer options in memory or MMSE tasks
struct MultipleChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity) //Full width
            .background(configuration.isPressed ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

