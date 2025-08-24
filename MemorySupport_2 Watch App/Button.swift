//
//  Button.swift
//  Memory Support
//
//  Created by Damla Cinel on 04.03.25.
//

import SwiftUI

/// Alzheimer hastaları için optimize edilmiş, tutarlı bir buton stili.
/// Bu stil, Apple Watch ekranında rahatlıkla kullanılabilmesi için
/// yeterli dokunma alanı, büyük font ve belirgin görsel geri bildirim sağlar.
struct ADStandardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Butonun genişliği ve yüksekliği: Apple Watch'ta yeterli dokunma alanı sağlamak için ayarlanabilir
            .frame(width: 60, height: 60)
            // Buton arka plan rengi; basıldığında farklı bir renk vererek geri bildirim sağlar.
            .background(configuration.isPressed ? Color.gray : Color.blue)
            // Buton içeriği için yüksek kontrastlı renk
            .foregroundColor(.white)
            // Buton metni için okunabilir ve yeterince büyük font
            .font(.system(size: 14, weight: .semibold))
            // Köşeleri yuvarlatılmış kare şeklinde buton
            .clipShape(RoundedRectangle(cornerRadius: 15))
            // Basılma durumunda hafif ölçeklendirme ile kullanıcıya dokunuş geri bildirimi
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            // Animasyon, basma durumunun yumuşak geçişi için
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}


/// Multiple choice sorular için optimize edilmiş dikdörtgen buton stili.
struct MultipleChoiceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            // Buton seçeneklerinde tüm genişliği kaplaması için
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .medium))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Stil kullanım örneği
struct ButtonContentView: View {
    var body: some View {
        VStack {
            Button(action: {
                // Buton aksiyonu burada tanımlanır.
            }) {
                Text("Start")
            }
            .buttonStyle(ADStandardButtonStyle())
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

