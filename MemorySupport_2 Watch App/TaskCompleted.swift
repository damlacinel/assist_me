//
//  TaskCompleted.swift
//  Memory Support
//
//  Created by Damla Cinel on 04.03.25.
//

import SwiftUI

/// FireworksAnimationView, asset catalog’daki resim kareleriyle animasyon oluşturur.
struct FireworksAnimationView: View {
    @State private var currentFrame = 0
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
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: animationDuration / Double(frames.count), repeats: true) { timer in
            currentFrame = (currentFrame + 1) % frames.count
        }
    }
}

/// Genel olarak kullanılacak TaskCompletionView.
/// onContinue closure’ı, tamamlandıktan sonra hangi view'in gösterileceğini belirler.
struct TaskCompletionView<NextView: View>: View {
    let onContinue: () -> NextView

    var body: some View {
        ZStack {
            // Arka planda animasyon: Fireworks
            FireworksAnimationView()
            
            // Üzerine bindirilmiş içerik
            VStack(spacing: 20) {
                Text("Great job!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Continue butonunu doğrudan NavigationLink içerisine alıyoruz.
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


