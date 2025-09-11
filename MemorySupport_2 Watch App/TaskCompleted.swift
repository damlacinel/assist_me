//
//  TaskCompleted.swift
//  Memory Support
//
//  Created by Damla Cinel on 04.03.25.
//

import SwiftUI

//FireworksAnimationView
//>> Creates a frame-based animation using images from the asset catalog
struct FireworksAnimationView: View {
    @State private var currentFrame = 0
    @State private var timer: Timer?
    
    private let frames = ["fireworks-0", "fireworks-4", "fireworks-8", "fireworks-12",
                          "fireworks-16", "fireworks-20", "fireworks-24", "fireworks-28",
                          "fireworks-32", "fireworks-36", "fireworks-40", "fireworks-44"]
    private let animationDuration: TimeInterval = 1.5

    var body: some View {
        Image(frames[currentFrame])
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                startAnimation()
            }
            .onDisappear(){
                stopAnimation()
            }
    }
    
    //Runs the animation by cycling through frames on a timer
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: animationDuration / Double(frames.count), repeats: true) { timer in
            currentFrame = (currentFrame + 1) % frames.count
        }
    }
    
    private func stopAnimation(){
        timer?.invalidate()
        timer = nil
    }
}

//TaskCompletionView
//>> Generic completion screen with background animation and a continue action button
struct TaskCompletionView<NextView: View>: View {
    let onContinue: () -> NextView

    var body: some View {
        ZStack {
           //Background animation >> Fireworks (similarity feeling)
            FireworksAnimationView()
            
            VStack(spacing: 20) {
                Text("Great job!") //motivation aspect here
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                //Continue buttob as NavigationLink
                NavigationLink(destination: onContinue()) {
                    Text("Continue")
                        .font(.system(size: 14))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


