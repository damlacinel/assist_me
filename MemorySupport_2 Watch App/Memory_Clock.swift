//
//  Memory_Clock.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 27.01.25.
//

//Giriş eksik
//Eğer çizilen saat kaydedilecekse çıkış kısmı eksik
//Akrep Yelkovanın büyüklükleri ayarlanmalı bir de tam ortada durmuyorlar
import SwiftUI

// MARK: - ClockPart Model
struct ClockPart: Identifiable, Equatable {
    enum PartType: Equatable {
        case hourHand
        case minuteHand
        case number(Int)
    }

    let id = UUID()
    let type: PartType
    var position: CGPoint = .zero
    var rotation: Int = 0 // 12 o'clock = 0 (hour hand: 0 means 12, 1 means 1, etc.; minute hand: each unit = 5 minutes)
    

    @ViewBuilder
      var view: some View {
          switch type {
          case .hourHand:
              // Fotoğraf yerine beyaz bir dikdörtgen kullanılıyor
                Rectangle()
                  .fill(Color.white)
                  .frame(width: 4, height: 150 * 0.3)
                  .offset(y: (-150) * 0.15)
                  .rotationEffect(.degrees(Double(rotation) * 30))
          case .minuteHand:
              // Fotoğraf yerine beyaz, daha ince bir dikdörtgen kullanılıyor
              Rectangle()
                  .fill(Color.white)
                  .frame(width: 2, height: 150 * 0.45)
                  .offset(y: (-150) * 0.225)
                  .rotationEffect(.degrees(Double(rotation) * 30))
          case .number(let value):
              Text("\(value)")
                  .font(.system(size: 14, weight: .bold))
                  .foregroundColor(.white)
                  .frame(width: 30, height: 30)
                  .multilineTextAlignment(.center)
          }
      }
      

    func withPosition(_ position: CGPoint) -> ClockPart {
        ClockPart(type: type, position: position, rotation: rotation)
    }

    func withRotation(_ rotation: Int) -> ClockPart {
        ClockPart(type: type, position: position, rotation: rotation)
    }
}

// MARK: - ClockGameView
struct ClockGameView: View {
    // Kontrol için state: false iken giriş ekranı, true iken saat canvas'ı
    @State private var showGame = false
    @State private var showHelp: Bool = false
    
    // Rastgele hedef saat (5 dakikalık artışlarla)
    @State private var targetHour: Int = 12
    @State private var targetMinute: Int = 0

    // Oyun parçaları: 12 sayı + hourHand, minuteHand
    let parts: [ClockPart] = {
        let numbers = (1...12).map { ClockPart(type: .number($0)) }
        let hands = [
            ClockPart(type: .hourHand),
            ClockPart(type: .minuteHand)
        ]
        return numbers.shuffled() + hands
    }()

    // MARK: - State Management for Game
    @State private var placedParts: [ClockPart] = []
    @State private var activePart: ClockPart? = nil
    @State private var partIndex = 0
    @State private var selectedPosition: CGPoint = .zero
    @State private var showConfirmation = false
    @State private var allNumbersPlaced = false
    @State private var isHandAdjusting = false

    // Tamamlanma ekranı için
    @State private var showCompletionSheet = false

    var body: some View {
        GeometryReader { geometry in
            let screenWidth  = geometry.size.width
            let screenHeight = geometry.size.height
            let clockSize = CGSize(width: screenWidth * 1.0, height: screenHeight * 1.0)
            let clockCenter = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
            
            if !showGame {
                ScrollView {
                        VStack(spacing: 20) {
                            Text("Start the Clock Construction")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            // Kısa açıklama (isteğe bağlı)
                            Text("Arrange the clock parts to set the correct time.")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                            
                            // Rastgele hedef saat gösterebilirsiniz (varsa)
                            Text("Set the time to: \(formattedTime(hour: targetHour, minute: targetMinute))")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            
                            HStack(spacing: 20) {
                                Button("Start") {
                                    showGame = true
                                    startGame(withCenter: clockCenter)
                                }
                                .buttonStyle(ADStandardButtonStyle())
                                
                                Button(action: {
                                    showHelp = true
                                }) {
                                    Image(systemName: "h.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(ADStandardButtonStyle())
                            }
                        }
                        .padding()
                    }
            } else {
                // Saat kurma ekranı
                ScrollView {
                        
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 5)
                                .frame(width: clockSize.width, height: clockSize.height)
                                .position(clockCenter)
                            
                            // Yerleştirilen parçalar
                            ForEach(placedParts) { part in
                                part.view
                                    .frame(width: sizeForPart(part, clockSize: clockSize),
                                           height: sizeForPart(part, clockSize: clockSize))
                                    .position(part.position)
                                    .gesture(
                                        // Yalnızca sayı draggable
                                        isNumber(part) ? DragGesture()
                                            .onChanged { value in
                                                if let idx = placedParts.firstIndex(where: { $0.id == part.id }) {
                                                    placedParts[idx].position = value.location
                                                }
                                            }
                                            .onEnded { _ in
                                                showConfirmation = true
                                            }
                                        : nil
                                    )
                            }
                            
                            // Aktif parça (henüz yerleştirilmemiş)
                            if let active = activePart {
                                let baseView = active.view
                                    .frame(width: sizeForPart(active, clockSize: clockSize),
                                           height: sizeForPart(active, clockSize: clockSize))
                                    .position(selectedPosition)
                                if case .number(_) = active.type {
                                    baseView.gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                selectedPosition = value.location
                                            }
                                            .onEnded { _ in
                                                showConfirmation = true
                                            }
                                    )
                                } else {
                                    baseView // hourHand, minuteHand draggable değil
                                }
                            }
                        }
                        .overlay(
                            Group {
                                if showConfirmation {
                                    confirmationDialog(center: clockCenter)
                                }
                            }
                        )
                        
                        Spacer()
                        
                        // Eğer tüm sayılar yerleştirildiyse, el ayarlama butonları
                        if allNumbersPlaced {
                            HStack(spacing: 10) {
                                Button(action: { adjustHand(rotationDelta: 1) }) {
                                    Image(systemName: "h.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                }
                                Button(action: { confirmHandAdjustment() }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.blue)
                                        .padding(8)
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                }
                                Button(action: { adjustHand(rotationDelta: 1) }) {
                                    Image(systemName: "m.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .background(Color.black)
                }
               
            }
        
        .sheet(isPresented: $showHelp) {
            ClockHelpView() // Yardım ekranınızı tanımladığınız view (örneğin ClockHelpView)
        }
        
        .sheet(isPresented: $showCompletionSheet) {
            NavigationView {
                TaskCompletionView {
                    DailyExercisesView()
                }
            }
        }
    }
    
    // MARK: - Helper Fonksiyonlar
    private func startGame(withCenter center: CGPoint) {
        randomTargetTime()
        loadNextPart(center: center)
    }
    
    private func randomTargetTime() {
        let minuteOptions = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
        targetHour = Int.random(in: 1...12)
        targetMinute = minuteOptions.randomElement() ?? 0
    }
    
    private func formattedTime(hour: Int, minute: Int) -> String {
        let hh = hour < 10 ? "0\(hour)" : "\(hour)"
        let mm = minute < 10 ? "0\(minute)" : "\(minute)"
        return "\(hh):\(mm)"
    }
    
    private func isNumber(_ part: ClockPart) -> Bool {
        if case .number(_) = part.type { return true }
        return false
    }
    
    private func sizeForPart(_ part: ClockPart, clockSize: CGSize) -> CGFloat {
        switch part.type {
        case .hourHand:
            return min(clockSize.width, clockSize.height) / 4
        case .minuteHand:
            return min(clockSize.width, clockSize.height) / 2
        case .number:
            return min(clockSize.width, clockSize.height) / 10
        }
    }
    
    private func finishClockConstruction() {
        // Burada target saat ile oluşturulan saat kontrol edilebilir
        showCompletionSheet = true
    }
    
    private func loadNextPart(center: CGPoint) {
        if partIndex < parts.count {
            activePart = parts[partIndex].withPosition(center)
            selectedPosition = center
            partIndex += 1
            
            if partIndex < parts.count {
                if case .hourHand = parts[partIndex].type {
                    isHandAdjusting = true
                } else {
                    isHandAdjusting = false
                }
            }
        } else {
            activePart = nil
            finishClockConstruction()
        }
    }
    
    private func adjustHand(rotationDelta: Int) {
        guard let active = activePart else { return }
        let newRotation = (active.rotation + rotationDelta + 12) % 12
        activePart = active.withRotation(newRotation)
    }
    
    private func confirmHandAdjustment() {
        if let active = activePart {
            placedParts.append(active)
            self.activePart = nil
            isHandAdjusting = false
            loadNextPart(center: selectedPosition)
        }
    }
    
    @ViewBuilder
    private func confirmationDialog(center: CGPoint) -> some View {
        VStack(spacing: 10) {
            Text("Do you want to confirm placement?")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            HStack(spacing: 6) {
                Button("Yes") {
                    if let active = activePart {
                        placedParts.append(active.withPosition(selectedPosition))
                        let placedNumbersCount = placedParts.filter {
                            if case .number(_) = $0.type { return true }
                            return false
                        }.count
                        if placedNumbersCount == 12 {
                            allNumbersPlaced = true
                        }
                        activePart = nil
                        loadNextPart(center: center)
                    }
                    showConfirmation = false
                }
                .buttonStyle(ADStandardButtonStyle())
                
                Button("No") {
                    selectedPosition = center
                    showConfirmation = false
                }
                .buttonStyle(ADStandardButtonStyle())
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(10)
        .frame(width: 180)
        .position(center)
    }
}

enum HelpStep: Int, Identifiable {
    case part1, part2
    var id: Int { self.rawValue }
}

struct ClockHelpView: View {
    // Saat yüzü boyutu
    @State private var circleSize: CGFloat = 150
    
    // Sayı "7" için konum
    @State private var numberPosition: CGPoint = CGPoint(x: -50, y: -50)  // Başlangıç: ekranın sol üstünde
    @State private var showNumber = true
    
    // El ikonu konumu
    @State private var handIconOffset: CGSize = CGSize(width: -70, height: -70)
    @State private var showHandIcon = false
    
    // Akrep ve yelkovan
    @State private var showHands = false
    @State private var hourRotation: Double = 0
    @State private var minuteRotation: Double = 0
    
    // Alt kısımda “+ / - / ✓” butonları
    @State private var showControls = false
    
    // Final mesaj
    @State private var showFinalMessage = false
    
    @State private var currentHelpStep: HelpStep? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("How to Construct the Clock")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ZStack {
                        // Saat yüzü
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: circleSize, height: circleSize)
                        
                        // Sayı "7" (tek sayı) - animasyonla doğru konuma sürüklenir
                        if showNumber {
                            Text("7")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .position(x: numberPosition.x, y: numberPosition.y)
                        }
                        
                        // Akrep
                        if showHands {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 4, height: circleSize * 0.3)
                                .offset(y: -circleSize * 0.15)
                                .rotationEffect(.degrees(hourRotation))
                        }
                        
                        // Yelkovan
                        if showHands {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: circleSize * 0.45)
                                .offset(y: -circleSize * 0.225)
                                .rotationEffect(.degrees(minuteRotation))
                        }
                        
                        // El ikonu
                        if showHandIcon {
                            Image(systemName: "hand.point.up.left.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .offset(handIconOffset)
                                .position(x: numberPosition.x, y: numberPosition.y)
                        }
                    }
                    .frame(width: circleSize, height: circleSize)
                    
                    // Alt kısımdaki butonlar (“+ / - / ✓”) - sadece belirli adımda göster
                    if showControls {
                        HStack(spacing: 20) {
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    hourRotation -= 30
                                }
                            }) {
                                Image(systemName: "h.circle")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                // “Check” butonu simülasyonu
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                            }
                            
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    minuteRotation += 30
                                }
                            }) {
                                Image(systemName: "m.circle")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                            }
                        }
                    }
                    
                    if showFinalMessage {
                        Text("First, place the numbers on the screen to the right positions. Then, adjust hour and minute hands of the clock using buttons below.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                    }
                                       
                        // Eğer demo akışı tamamlandıysa, "More Info" butonunu göster
                            if showFinalMessage && currentHelpStep == nil {
                                Button("More Info") {
                                    currentHelpStep = .part1
                                }
                                  .buttonStyle(ADStandardButtonStyle())
                            }
                                       Spacer()
                }
                .padding()
                .navigationTitle("Help")
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            runDemo()
        }
        
        .sheet(item: $currentHelpStep) { step in
            switch step {
            case .part1:
                HelpPart1View {
                    // "Next" butonuna basıldığında part2'ye geçiş yap
                    currentHelpStep = .part2
                }
            case .part2:
                HelpPart2View {
                    // "Done" butonuna basıldığında sheet kapanır
                    currentHelpStep = nil
                }
            }
        }
    }
    
    private func runDemo() {
        // 1) 1 saniye sonra el ikonu ve sayı görünsün
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showHandIcon = true
            // “7” sayısı saat yüzü merkezinde “yanlış” bir konumda başlasın
            numberPosition =  CGPoint(x : 70,y : 70)
        }
        
        // 2) 2 saniye sonra, el ikonu “7”yi doğru konuma sürüklüyor
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 1.0)) {
                // “7”yi saat yüzündeki ideal konuma yerleştirin
                numberPosition = CGPoint(x: 45, y: 120)
                // El ikonu da oraya yaklaşsın
                handIconOffset = CGSize(width: 0, height: 0)
            }
        }
        
        // 3) 3 saniye sonra akrep ve yelkovan belirsin
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showHands = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                   showControls = true
                   withAnimation(.easeInOut(duration: 1.0)) {
                       // El ikonu + butonu simüle ediyor (offset x, y butonun konumuna göre)
                       handIconOffset = CGSize(width: -5, height: 100)
                   }
               }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                   withAnimation(.easeInOut(duration: 1.0)) {
                       handIconOffset = CGSize(width: 65, height: 100)
                   }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeInOut(duration: 1.0)) {
                handIconOffset = CGSize(width: 125, height: 100)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                  showFinalMessage = true
              }
        
    }
}

// MARK: - HelpPart1View
struct HelpPart1View: View {
    let onNext: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("""
The numbers should be placed using drag and drop.
After placing a number, a confirmation page opens up.
Each placement should be confirmed before moving on.
""")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                Button("Next") {
                    onNext()
                }
                .buttonStyle(ADStandardButtonStyle())
                Spacer()
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

// MARK: - HelpPart2View
struct HelpPart2View: View {
    let onDone: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("""
The hour and minute hands should be arranged according to the target time.
'M' helps to adjust the minute hand and 'H' for the hour hand.
After clicking the tick icon, the clock construction is finished.
""")
                .font(.system(size: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                Button("Done") {
                    onDone()
                }
                .buttonStyle(ADStandardButtonStyle())
                Spacer()
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}
