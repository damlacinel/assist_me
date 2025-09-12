//
//  Memory_Clock.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 27.01.25.
//

//Some improvements needed for the user interface
//>> E.g.: hour/minute hand replacements
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
    /// 12 o'clock = 0. Hour hand: 0->12, 1->1, ... Minute hand: each unit = 5 minutes
    var rotation: Int = 0
    
    @ViewBuilder
    var view: some View {
        switch type {
        case .hourHand:
            // >> Simplified hour hand (white rectangle), rotated by 30° * rotation
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 150 * 0.3)
                .offset(y: (-150) * 0.15)
                .rotationEffect(.degrees(Double(rotation) * 30))
        case .minuteHand:
            // >> Simplified minute hand (thinner), rotated by 30° * rotation (5 min steps)
            Rectangle()
                .fill(Color.white)
                .frame(width: 2, height: 150 * 0.45)
                .offset(y: (-150) * 0.225)
                .rotationEffect(.degrees(Double(rotation) * 30))
        case .number(let value):
            // >> Draggable numeric label
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
    // Flow control: false -> intro, true -> canvas
    @State private var showGame = false
    @State private var showHelp: Bool = false
    
    // Random target time (5-minute increments)
    @State private var targetHour: Int = 12
    @State private var targetMinute: Int = 0

    // Parts: 12 numbers + hour/minute hands
    let parts: [ClockPart] = {
        let numbers = (1...12).map { ClockPart(type: .number($0)) }
        let hands = [ClockPart(type: .hourHand), ClockPart(type: .minuteHand)]
        return numbers.shuffled() + hands
    }()

    // State
    @State private var placedParts: [ClockPart] = []
    @State private var activePart: ClockPart? = nil
    @State private var partIndex = 0
    @State private var selectedPosition: CGPoint = .zero
    @State private var showConfirmation = false
    @State private var allNumbersPlaced = false
    @State private var isHandAdjusting = false

    // Completion
    @State private var showCompletionSheet = false

    var body: some View {
        GeometryReader { geometry in
            let screenWidth  = geometry.size.width
            let screenHeight = geometry.size.height
            let clockSize = CGSize(width: screenWidth * 1.0, height: screenHeight * 1.0)
            let clockCenter = CGPoint(x: screenWidth / 2, y: screenHeight / 2)
            
            if !showGame {
                // Intro
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Start the Clock Construction")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Text("Arrange the clock parts to set the correct time.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                        
                        Text("Set the time to: \(formattedTime(hour: targetHour, minute: targetMinute))")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        
                        HStack(spacing: 20) {
                            Button("Start") {
                                showGame = true
                                startGame(withCenter: clockCenter)
                            }
                            .buttonStyle(ADStandardButtonStyle())
                            
                            Button(action: { showHelp = true }) {
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
                // Canvas
                ScrollView {
                    ZStack {
                        // Dial
                        Circle()
                            .stroke(Color.white, lineWidth: 5)
                            .frame(width: clockSize.width, height: clockSize.height)
                            .position(clockCenter)
                        
                        // Placed parts
                        ForEach(placedParts) { part in
                            part.view
                                .frame(width: sizeForPart(part, clockSize: clockSize),
                                       height: sizeForPart(part, clockSize: clockSize))
                                .position(part.position)
                                .gesture(
                                    // Only numbers are draggable after placement
                                    isNumber(part) ? DragGesture()
                                        .onChanged { value in
                                            if let idx = placedParts.firstIndex(where: { $0.id == part.id }) {
                                                placedParts[idx].position = value.location
                                            }
                                        }
                                        .onEnded { _ in showConfirmation = true }
                                    : nil
                                )
                        }
                        
                        // Active (not yet placed)
                        if let active = activePart {
                            let baseView = active.view
                                .frame(width: sizeForPart(active, clockSize: clockSize),
                                       height: sizeForPart(active, clockSize: clockSize))
                                .position(selectedPosition)
                            if case .number = active.type {
                                baseView.gesture(
                                    DragGesture()
                                        .onChanged { value in selectedPosition = value.location }
                                        .onEnded { _ in showConfirmation = true }
                                )
                            } else {
                                baseView // hands are adjusted via buttons, not dragged
                            }
                        }
                    }
                    .overlay(
                        Group { if showConfirmation { confirmationDialog(center: clockCenter) } }
                    )
                    
                    Spacer()
                    
                    // Hand adjust controls (after all numbers)
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
        // Help & Completion
        .sheet(isPresented: $showHelp) {
            ClockHelpView()
        }
        .sheet(isPresented: $showCompletionSheet) {
            NavigationView {
                TaskCompletionView { DailyExercisesView() }
            }
        }
    }
    
    // MARK: - Helpers
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
        if case .number = part.type { return true }
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
        // >> Compare constructed clock with target time, score/persist if needed
        showCompletionSheet = true
    }
    
    private func loadNextPart(center: CGPoint) {
        if partIndex < parts.count {
            activePart = parts[partIndex].withPosition(center)
            selectedPosition = center
            partIndex += 1
            
            // Simple flag to toggle hand-adjust UI
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
                            if case .number = $0.type { return true }
                            return false
                        }.count
                        if placedNumbersCount == 12 { allNumbersPlaced = true }
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

// MARK: - Help Flow (demo)
enum HelpStep: Int, Identifiable { case part1, part2; var id: Int { rawValue } }

struct ClockHelpView: View {
    @State private var circleSize: CGFloat = 150
    @State private var numberPosition: CGPoint = CGPoint(x: -50, y: -50)
    @State private var showNumber = true
    @State private var handIconOffset: CGSize = CGSize(width: -70, height: -70)
    @State private var showHandIcon = false
    @State private var showHands = false
    @State private var hourRotation: Double = 0
    @State private var minuteRotation: Double = 0
    @State private var showControls = false
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
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: circleSize, height: circleSize)
                        
                        if showNumber {
                            Text("7")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .position(x: numberPosition.x, y: numberPosition.y)
                        }
                        if showHands {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 4, height: circleSize * 0.3)
                                .offset(y: -circleSize * 0.15)
                                .rotationEffect(.degrees(hourRotation))
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: circleSize * 0.45)
                                .offset(y: -circleSize * 0.225)
                                .rotationEffect(.degrees(minuteRotation))
                        }
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
                    
                    if showControls {
                        HStack(spacing: 20) {
                            Button(action: {
                                withAnimation(.easeInOut) { hourRotation -= 30 }
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
                                // Check action demo
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
                                withAnimation(.easeInOut) { minuteRotation += 30 }
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
                    
                    if showFinalMessage && currentHelpStep == nil {
                        Button("More Info") { currentHelpStep = .part1 }
                            .buttonStyle(ADStandardButtonStyle())
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle("Help")
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .onAppear { runDemo() }
        .sheet(item: $currentHelpStep) { step in
            switch step {
            case .part1: HelpPart1View { currentHelpStep = .part2 }
            case .part2: HelpPart2View { currentHelpStep = nil }
            }
        }
    }
    
    private func runDemo() {
        // Step 1: show hand icon & number
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showHandIcon = true
            numberPosition = CGPoint(x: 70, y: 70)
        }
        // Step 2: drag number to the correct position
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 1.0)) {
                numberPosition = CGPoint(x: 45, y: 120)
                handIconOffset = .zero
            }
        }
        // Step 3: reveal hands
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showHands = true
        }
        // Step 4–6: simulate control usage
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showControls = true
            withAnimation(.easeInOut(duration: 1.0)) { handIconOffset = CGSize(width: -5, height: 100) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeInOut(duration: 1.0)) { handIconOffset = CGSize(width: 65, height: 100) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            withAnimation(.easeInOut(duration: 1.0)) { handIconOffset = CGSize(width: 125, height: 100) }
        }
        // Step 7: final message
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
                Button("Next") { onNext() }
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
                Button("Done") { onDone() }
                    .buttonStyle(ADStandardButtonStyle())
                Spacer()
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}
