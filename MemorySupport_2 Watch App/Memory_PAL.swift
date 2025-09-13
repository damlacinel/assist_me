//
//  Memory_MOT.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 26.01.25.
//
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

    @State private var testStarted: Bool = false       // >> Show intro until start
    @State private var showHelp: Bool = false          // >> Help sheet control

    // Available patterns (SF Symbols)
    let availablePatterns: [Pattern] = [
        Pattern(systemName: "star.fill"),
        Pattern(systemName: "circle.fill"),
        Pattern(systemName: "square.fill"),
        Pattern(systemName: "triangle.fill"),
        Pattern(systemName: "diamond.fill"),
        Pattern(systemName: "hexagon.fill")
    ]

    // Grid config
    let columns = 2
    let rows = 3
    let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                if !testStarted {
                    // Intro
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

                                Button(action: { showHelp = true }) {
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
                    // Test screen
                    let boxWidth = geometry.size.width / 2.75
                    let boxHeight = geometry.size.height / 2.75
                    let boxSize = min(boxWidth, boxHeight)

                    if isSelectionPhase, patternToFind != nil {
                        ScrollView {
                            VStack(spacing: 10) {
                                if let pattern = patternToFind {
                                    PatternDisplayView(pattern: pattern) // >> Target cue
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
            TaskCompletionView { DailyExercisesView() }
        }
        .sheet(isPresented: $showHelp) {
            HelpView() // >> Demo/tutorial flow
        }
    }

    // MARK: - Grid
    private func gridLayout(boxSize: CGFloat) -> some View {
        HStack(spacing: spacing) {
            VStack(spacing: spacing) {
                ForEach(leftBoxes()) { box in
                    BoxView(box: box, boxSize: boxSize)
                        .onTapGesture {
                            if isSelectionPhase { handleBoxSelection(box) }
                        }
                }
            }
            VStack(spacing: spacing) {
                ForEach(rightBoxes()) { box in
                    BoxView(box: box, boxSize: boxSize)
                        .onTapGesture {
                            if isSelectionPhase { handleBoxSelection(box) }
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
            showBoxesSequentially()      // >> Encoding phase: reveal then hide
        } else {
            isTestInProgress = false
            showCompletionSheet = true
        }
    }

    func createBoxes(count: Int) -> [Box] {
        (0..<count).map { Box(position: $0, pattern: nil) }
    }

    func assignPatternsToBoxes() {
        var shuffled = boxes.shuffled()
        let patterns = availablePatterns.shuffled()
        for i in 0..<min(patterns.count, shuffled.count) {
            shuffled[i].pattern = patterns[i]
        }
        boxes = shuffled
    }

    func showBoxesSequentially() {
        for index in boxes.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.5) {
                boxes[index].isOpened = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    boxes[index].isOpened = false
                    if index == boxes.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSelectionPhase = true         // >> Retrieval phase
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

    // MARK: - Helpers
    func leftBoxes() -> [Box]  { Array(boxes.prefix(3)) }
    func rightBoxes() -> [Box] { Array(boxes.suffix(3)) }

    // MARK: - Subviews
    struct BoxView: View {
        let box: Box
        let boxSize: CGFloat

        var body: some View {
            ZStack {
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .background(
                        Rectangle().fill(box.isOpened ? Color.white : Color.black)
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

// MARK: - Help / Tutorial
struct HelpView: View {
    struct HelpBox: Identifiable {
        let id = UUID()
        let systemName: String
        var isOpened: Bool
    }

    @State private var boxes: [HelpBox] = [
        HelpBox(systemName: "star.fill",     isOpened: false),
        HelpBox(systemName: "circle.fill",   isOpened: false),
        HelpBox(systemName: "square.fill",   isOpened: false),
        HelpBox(systemName: "triangle.fill", isOpened: false),
        HelpBox(systemName: "diamond.fill",  isOpened: false),
        HelpBox(systemName: "hexagon.fill",  isOpened: false)
    ]
    @State private var topIcon: String = "triangle.fill"
    @State private var stepIndex: Int = 0
    @State private var handOffset: CGSize = CGSize(width: 0, height: -60)
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

                Text("Cards open sequentially, then close. Match the top icon by tapping the correct card.")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                // Target cue (after reveal cycle)
                if stepIndex >= 7 {
                    Image(systemName: topIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                }

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
                    Image(systemName: "hand.point.up.left.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                        .offset(handOffset)
                        .opacity(stepIndex >= 8 ? 1 : 0)
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
        .onAppear { runSimulation() }
    }

    private func runSimulation() {
        // Open boxes one by one
        for i in boxes.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                withAnimation { boxes[i].isOpened = true }
            }
        }
        // Close all, show cue
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(boxes.count) * 1.0 + 1.0) {
            for i in boxes.indices { boxes[i].isOpened = false }
            stepIndex = 7
        }
        // Move hand icon to target
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(boxes.count) * 1.0 + 2.0) {
            withAnimation(.easeInOut(duration: 1.0)) {
                handOffset = CGSize(width: 50, height: 40) // >> demo position
            }
            stepIndex = 8
        }
        // Final hint
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(boxes.count) * 1.0 + 3.0) {
            showFinalMessage = true
        }
    }
}

struct HelpBoxView: View {
    let box: HelpView.HelpBox
    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(Rectangle().fill(box.isOpened ? Color.white : Color.gray))
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

