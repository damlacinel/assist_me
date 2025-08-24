//
//  Memory_MOT.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 26.01.25.
//
import SwiftUI

import SwiftUI

struct PalContentView: View {
    // MARK: - Data Models
    struct Box: Identifiable {
        let id = UUID()
        let position: Int
        var pattern: Pattern?
        var isOpened: Bool = false
    }
    
    struct Pattern: Identifiable {
        let id = UUID()
        let systemName: String
    }
    
    // MARK: - State
    @State private var boxes: [Box] = []
    @State private var patternToFind: Pattern? = nil
    @State private var isSelectionPhase: Bool = false
    @State private var currentRound: Int = 1
    @State private var maxRounds: Int = 6
    @State private var isTestInProgress: Bool = false
    @State private var showCompletionSheet = false
    
    // Giriş ekranı kontrolü (test başlamadıysa giriş ekranı görünsün)
    @State private var testStarted: Bool = false
    
    // Yardım ekranını kontrol eden state
    @State private var showHelp: Bool = false
    
    // Kullanılacak desenler
    let availablePatterns: [Pattern] = [
        Pattern(systemName: "star.fill"),
        Pattern(systemName: "circle.fill"),
        Pattern(systemName: "square.fill"),
        Pattern(systemName: "triangle.fill"),
        Pattern(systemName: "diamond.fill"),
        Pattern(systemName: "hexagon.fill")
    ]
    
    // Grid ayarları
    let columns = 2
    let rows = 3
    let spacing: CGFloat = 8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if !testStarted {
                    // GİRİŞ EKRANI (ScrollView ile kaydırılabilir içerik)
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Match the Icons!")
                                .font(.title)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                Button("Start") {
                                    testStarted = true
                                    resetTest()
                                }
                                .buttonStyle(ADStandardButtonStyle())
                                
                                Button(action: {
                                    showHelp = true
                                }) {
                                    Image(systemName: "h.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                        .padding(4)
                                }
                                .buttonStyle(ADStandardButtonStyle())
                            }
                        }
                        .padding()
                    }
                } else {
                    // TEST EKRANI
                    let boxWidth = (geometry.size.width) / 2.75
                    let boxHeight = (geometry.size.height) / 2.75
                    let boxSize = min(boxWidth, boxHeight)
                    
                    if isSelectionPhase, patternToFind != nil {
                        ScrollView {
                            VStack(spacing: 10) {
                                if let pattern = patternToFind {
                                    PatternDisplayView(pattern: pattern)
                                }
                                gridLayout(boxSize: boxSize)
                            }
                            .padding()
                        }
                    } else {
                        gridLayout(boxSize: boxSize)
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
            TaskCompletionView {
                DailyExercisesView()
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()  // Burada oyunun oynanış simülasyonunu gösterebilirsiniz
        }
    }
    
    // MARK: - Grid Layout
    private func gridLayout(boxSize: CGFloat) -> some View {
        HStack(spacing: spacing) {
            VStack(spacing: spacing) {
                ForEach(leftBoxes()) { box in
                    BoxView(box: box, boxSize: boxSize)
                        .onTapGesture {
                            if isSelectionPhase {
                                handleBoxSelection(box)
                            }
                        }
                }
            }
            VStack(spacing: spacing) {
                ForEach(rightBoxes()) { box in
                    BoxView(box: box, boxSize: boxSize)
                        .onTapGesture {
                            if isSelectionPhase {
                                handleBoxSelection(box)
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Test Logic
    func resetTest() {
        currentRound = 1
        isTestInProgress = true
        startTest()
    }
    
    func startTest() {
        if currentRound <= maxRounds {
            isSelectionPhase = false
            boxes = createBoxes(count: 6)
            patternToFind = availablePatterns.randomElement()
            assignPatternsToBoxes()
            showBoxesSequentially()
        } else {
            // Test bitti
            isTestInProgress = false
            showCompletionSheet = true
        }
    }
    
    func createBoxes(count: Int) -> [Box] {
        (0..<count).map { Box(position: $0, pattern: nil) }
    }
    
    func assignPatternsToBoxes() {
        var shuffledBoxes = boxes.shuffled()
        let patterns = availablePatterns.shuffled()
        for i in 0..<min(patterns.count, shuffledBoxes.count) {
            shuffledBoxes[i].pattern = patterns[i]
        }
        boxes = shuffledBoxes
    }
    
    func showBoxesSequentially() {
        for (index, _) in boxes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.5) {
                boxes[index].isOpened = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    boxes[index].isOpened = false
                    if index == boxes.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSelectionPhase = true
                        }
                    }
                }
            }
        }
    }
    
    func handleBoxSelection(_ box: Box) {
        if isSelectionPhase {
            currentRound += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                startTest()
            }
        }
    }
    
    // MARK: - Helper
    func leftBoxes() -> [Box] {
        Array(boxes.prefix(3))
    }
    
    func rightBoxes() -> [Box] {
        Array(boxes.suffix(3))
    }
    // MARK: - Subviews
    struct BoxView: View {
        let box: Box
        let boxSize: CGFloat
        
        var body: some View {
            ZStack {
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .background(
                        Rectangle()
                            .fill(box.isOpened ? Color.white : Color.black)
                    )
                    .frame(width: boxSize, height: boxSize)
                
                if box.isOpened, let pattern = box.pattern {
                    Image(systemName: pattern.systemName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: boxSize * 0.8, height: boxSize * 0.8)
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    struct PatternDisplayView: View {
        let pattern: Pattern
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 60, height: 60)
                    .cornerRadius(10)
                
                Image(systemName: pattern.systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
            }
        }
    }
}


struct HelpView: View {
    // 6 kutu (2x3) için basit veri modeli
    struct HelpBox: Identifiable {
        let id = UUID()
        let systemName: String
        var isOpened: Bool
    }
    
    // Yardım simülasyonunda kullanılan state’ler
    @State private var boxes: [HelpBox] = [
        HelpBox(systemName: "star.fill", isOpened: false),
        HelpBox(systemName: "circle.fill", isOpened: false),
        HelpBox(systemName: "square.fill", isOpened: false),
        HelpBox(systemName: "triangle.fill", isOpened: false),
        HelpBox(systemName: "diamond.fill", isOpened: false),
        HelpBox(systemName: "hexagon.fill", isOpened: false)
    ]
    @State private var topIcon: String = "triangle.fill"  // Eşleştirilecek ikon
    @State private var stepIndex: Int = 0                 // Animasyon adımlarını takip eden index
    @State private var handOffset: CGSize = CGSize(width: 0, height: -60)  // Elin başlangıç konumu
    @State private var showFinalMessage = false
    
    let columns = 2
    let rows = 3
    let spacing: CGFloat = 8
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("How to Play")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Each card is opened one by one, then closed. A top icon is shown, and you must tap the matching card below.")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                
                // Üst ikonu (patternToFind benzeri)
                if stepIndex >= 7 {
                    // Kart açma-kapama bittiğinde üst ikonu gösteriyoruz
                    Image(systemName: topIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                }
                
                // 2x3 grid
                ZStack {
                    VStack(spacing: spacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: spacing) {
                                ForEach(0..<columns, id: \.self) { col in
                                    let index = row * columns + col
                                    HelpBoxView(box: boxes[index])
                                }
                            }
                        }
                    }
                    // El ikonu (en üstte)
                    Image(systemName: "hand.point.up.left.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .offset(handOffset)
                        .opacity(stepIndex >= 8 ? 1 : 0) // El ikonu en sonda görünüyor
                        .zIndex(1)
                }
                .padding()
                
                if showFinalMessage {
                    Text("After matching the icon, you proceed to the next round.")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Help")
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            runSimulation()
        }
    }
    
    // Yardım simülasyonu adımlarını sırasıyla çalıştıran fonksiyon
    private func runSimulation() {
        // 1) Kutuları sırayla aç
        for i in 0..<boxes.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                withAnimation {
                    boxes[i].isOpened = true
                }
            }
        }
        // 2) Tüm kutular açıldıktan 1 saniye sonra hepsini kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(boxes.count) * 1.0 + 1.0) {
            for i in 0..<boxes.count {
                boxes[i].isOpened = false
            }
            stepIndex = 7 // Üst ikonu göster
        }
        // 3) 1 saniye sonra el ikonunu gösterip doğru kutuya doğru animasyonla taşı
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(boxes.count) * 1.0 + 2.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                // “triangle.fill” 4. kutu diyelim (0-based: star, circle, square, triangle, diamond, hexagon)
                // Indeks 3 => triangle
                // Elin offsetini, bu kutunun konumuna göre ayarlıyoruz (deneme yanılma)
                handOffset = CGSize(width: 50, height: 40)
            }
            stepIndex = 8
        }
        // 4) 1 saniye sonra final mesaj
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(boxes.count) * 1.0 + 3.0) {
            showFinalMessage = true
        }
    }
}

// Yardımda kullanılan basit kutu view
struct HelpBoxView: View {
    let box: HelpView.HelpBox
    
    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(
                    Rectangle()
                        .fill(box.isOpened ? Color.white : Color.gray)
                )
                .frame(width: 50, height: 50)
            
            if box.isOpened {
                Image(systemName: box.systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
            }
        }
    }
}
struct CardView: View {
    let content: String
    let isRevealed: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isRevealed ? Color.white : Color.gray)
                .frame(width: 50, height: 70)
                .shadow(radius: 3)
            if isRevealed {
                Text(content)
                    .font(.largeTitle)
                    .foregroundColor(.black)
            }
        }
    }
}

struct TestResultsView: View {
    let testResults: [TestResult]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Previous Test Results")
                    .font(.headline)
                    .padding(.bottom, 10)
                ForEach(testResults) { result in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date: \(dateFormatter.string(from: result.date))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("Correct Answer: \(result.correctAnswer)")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
