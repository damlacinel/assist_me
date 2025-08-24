//
//  MMSE_Testing.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 28.02.25.
//

import SwiftUI
import AVFoundation
import CoreML

// MARK: - Data Models

struct ExtendedMMSEQuestion: Identifiable {
    let id = UUID()
    
    let questionText: String
    let questionImageName: String?
    let questionAudioName: String?
    let isTextInput: Bool
    let correctTextAnswer: String?
    let choices: [ExtendedChoice]
    let correctAnswerIndex: Int?
    let isDrawingTask: Bool
    let shapeToDraw: String?

    init(
        questionText: String,
        questionImageName: String? = nil,
        questionAudioName: String? = nil,
        isTextInput: Bool = false,
        correctTextAnswer: String? = nil,
        choices: [ExtendedChoice] = [],
        correctAnswerIndex: Int? = nil,
        isDrawingTask: Bool = false,
        shapeToDraw: String? = nil
    ) {
        self.questionText = questionText
        self.questionImageName = questionImageName
        self.questionAudioName = questionAudioName
        self.isTextInput = isTextInput
        self.correctTextAnswer = correctTextAnswer
        self.choices = choices
        self.correctAnswerIndex = correctAnswerIndex
        self.isDrawingTask = isDrawingTask
        self.shapeToDraw = shapeToDraw
    }
}

struct ExtendedChoice {
    let text: String?
    let imageName: String?
}

struct ExtendedMMSEData {
    let memoryWord: String       // Memory word (not displayed on screen)
    let questions: [ExtendedMMSEQuestion]
}


// Version A
var extendedMMSEVersionA: [ExtendedMMSEQuestion] = [
    ExtendedMMSEQuestion(
        questionText: "What is the current year?",
        isTextInput: true,
        correctTextAnswer: "2025"
    ),
    ExtendedMMSEQuestion(
        questionText: "Listen and choose the correct match",
        questionAudioName: "apple pen table",
        choices: [
            ExtendedChoice(text: "banana-pencil-table", imageName: nil),
            ExtendedChoice(text: "apple-pen-table", imageName: nil),
            ExtendedChoice(text: "yellow-big-short", imageName: nil)
        ],
        correctAnswerIndex: 1
    ),
    ExtendedMMSEQuestion(
        questionText: "Count backwards from 100 by sevens.",
        choices: [
            ExtendedChoice(text: "100-93-86-79...", imageName: nil),
            ExtendedChoice(text: "100-91-84-77...", imageName: nil),
            ExtendedChoice(text: "100-90-80-70...", imageName: nil)
        ],
        correctAnswerIndex: 0
    ),
    ExtendedMMSEQuestion(
        questionText: "Before this quiz started, you listened to a word. Type it in.",
        isTextInput: true,
        correctTextAnswer: "John Brown"
    ),
    ExtendedMMSEQuestion(
        questionText: "Which animal do you see in the picture below?",
        questionImageName: "bee",
        isTextInput: true,
        correctTextAnswer: "Bee"
    ),
    ExtendedMMSEQuestion(
        questionText: "Please draw a circle",
        isDrawingTask: true,
        shapeToDraw: "circle"
    )
]

// Version B
var extendedMMSEVersionB: [ExtendedMMSEQuestion] = [
    ExtendedMMSEQuestion(
        questionText: "What country are you in?",
        isTextInput: true,
        correctTextAnswer: "Washington"
    ),
    ExtendedMMSEQuestion(
        questionText: "Listen to the words and choose the correct match.",
        questionAudioName: "three bear pineapple",
        choices: [
            ExtendedChoice(text: "Three-Bear-Pineapple", imageName: nil),
            ExtendedChoice(text: "Tree-Beer-Apple", imageName: nil),
            ExtendedChoice(text: "Three-Bear-Wine", imageName: nil)
        ],
        correctAnswerIndex: 0
    ),
    ExtendedMMSEQuestion(
        questionText: "Backwards spelling of WORLD?",
        choices: [
            ExtendedChoice(text: "D-O-L-W-R", imageName: nil),
            ExtendedChoice(text: "D-L-L-W-O-R", imageName: nil),
            ExtendedChoice(text: "D-L-R-O-W", imageName: nil)
        ],
        correctAnswerIndex: 2
    ),
    ExtendedMMSEQuestion(
        questionText: "What is the object shown in the picture below?",
        questionImageName: "pen",
        isTextInput: true,
        correctTextAnswer: "Pen"
    ),
    ExtendedMMSEQuestion(
        questionText: "Please draw a square",
        isDrawingTask: true,
        shapeToDraw: "square"
    )
]

// Version C
var extendedMMSEVersionC: [ExtendedMMSEQuestion] = [
    ExtendedMMSEQuestion(
        questionText: "What day of the week is it?",
        isTextInput: true,
        correctTextAnswer: "Long river" // example usage
    ),
    ExtendedMMSEQuestion(
        questionText: "Listen to words, choose the correct match.",
        questionAudioName: "cat crazy chair",
        choices: [
            ExtendedChoice(text: "Cat-Crawl-Chair", imageName: nil),
            ExtendedChoice(text: "Cat-Eye-Nail", imageName: nil),
            ExtendedChoice(text: "Cat-Crazy-Chair", imageName: nil)
        ],
        correctAnswerIndex: 2
    ),
    ExtendedMMSEQuestion(
        questionText: "Count upwards from 17 by fives.",
        choices: [
            ExtendedChoice(text: "17-22-27-32...", imageName: nil),
            ExtendedChoice(text: "17-20-25-30-35...", imageName: nil),
            ExtendedChoice(text: "17-22-28-32...", imageName: nil)
        ],
        correctAnswerIndex: 0
    ),
    ExtendedMMSEQuestion(
        questionText: "Which room do you see in the picture below?",
        questionImageName: "kitchen",
        isTextInput: true,
        correctTextAnswer: "Kitchen"
    ),
    ExtendedMMSEQuestion(
        questionText: "Please draw a triangle",
        isDrawingTask: true,
        shapeToDraw: "triangle"
    )
]

// Full Data Sets (memory words are predefined and are not shown on screen)
let mmseDataA = ExtendedMMSEData(memoryWord: "John Brown", questions: extendedMMSEVersionA)
let mmseDataB = ExtendedMMSEData(memoryWord: "Washington", questions: extendedMMSEVersionB)
let mmseDataC = ExtendedMMSEData(memoryWord: "Long river", questions: extendedMMSEVersionC)



// MARK: - ML Model Prediction (unchanged, except for your actual model class name)

func predictShapeWithML(drawnPoints: [CGPoint]) -> String {
    guard drawnPoints.count > 2 else { return "unknown" }
    
    let sumX = drawnPoints.map(\.x).reduce(0, +)
    let sumY = drawnPoints.map(\.y).reduce(0, +)
    let avgX = Double(sumX) / Double(drawnPoints.count)
    let avgY = Double(sumY) / Double(drawnPoints.count)
    
    do {
        let config = MLModelConfiguration()
        let model = try ml_model(configuration: config)
        let input = ml_modelInput(avg_x: avgX, avg_y: avgY)
        let output = try model.prediction(input: input)
        return output.prediction
    } catch {
        print("ML Prediction Error: \(error.localizedDescription)")
        return "unknown"
    }
}

// MARK: - Drawing Canvas

struct DrawingCanvas: View {
    @Binding var points: [CGPoint]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.black, lineWidth: 2)
            }
            .gesture(
                DragGesture(minimumDistance: 0.1)
                    .onChanged { value in
                        points.append(value.location)
                    }
            )
        }
    }
}

// MARK: - DrawingTaskView

struct DrawingTaskView: View {
    let expectedShape: String
    var onComplete: (Bool, String) -> Void
    
    @State private var drawnPoints: [CGPoint] = []
    @State private var showResultAlert = false
    @State private var resultMessage = ""
    @State private var showCompletionSheet : Bool = false
    
    @State private var navigate = false
    
    
    var body: some View {
        VStack {
            DrawingCanvas(points: $drawnPoints)
                .frame(width: 150, height: 150)
                .border(Color.gray, width: 1)
            
            // Butonlar yan yana: Clear Canvas ve Next
            HStack(spacing: 20) {
                Button("Clear Canvas") {
                    // drawnPoints bu view içinde tanımlı olduğu için temizleyebiliriz
                    drawnPoints = []
                }
                .buttonStyle(ADStandardButtonStyle())
                
                Button("Next") {
                    let predicted = predictShapeWithML(drawnPoints: drawnPoints)
                    let isCorrect = (predicted.lowercased() == expectedShape.lowercased())
                    onComplete(isCorrect, predicted)
                    navigate = true
                }
                .buttonStyle(ADStandardButtonStyle())
            }
            .padding(.top, 10)
            
            NavigationLink(destination: NavigationView {
                    TaskCompletionView() {
                        ContentView()
                    }
                        }, isActive: $navigate) {
                            EmptyView()
                        }
                        .hidden()
        }
    }
}

// MARK: - QuestionAudioView

struct QuestionAudioView: View {
    let audioText: String
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var hasPlayed = false
    
    var body: some View {
        Button(action: {
            let utterance = AVSpeechUtterance(string: audioText)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            synthesizer.speak(utterance)
            hasPlayed = true
        }) {
            Text(hasPlayed ? "Played" : "Play Audio")
        }
        .disabled(hasPlayed)
    }
}

// MARK: - MemoryIntroView

struct MemoryIntroView: View {
    let memoryWord: String
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var hasPlayedOnce = false
    
    var body: some View {
        VStack {
            Button(action: {
                let utterance = AVSpeechUtterance(string: memoryWord)
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                synthesizer.speak(utterance)
                hasPlayedOnce = true
            }) {
                Text(hasPlayedOnce ? "Played" : "Play Audio")
            }
            .padding()
            .disabled(hasPlayedOnce)
        }
    }
}

// MARK: - MMSEQuizView

struct MMSEQuizView: View {
    // Combine all data sets
    private var allVersions = [mmseDataA, mmseDataB, mmseDataC]
    private let selectedData: ExtendedMMSEData
    
    @State private var showMemoryIntro = true
    @State private var currentQuestionIndex = 0
    @State private var userInput = ""
    @State private var drawingTaskPassed: Bool? = nil
    @State private var selectedChoiceIndex: Int? = nil
    
    @State private var isQuizComplete = false
    @EnvironmentObject var env: AppEnvironment
    
    @State private var quizStarted: Bool = false
    @State private var showHelp: Bool = false
    
    
    
    init() {
            self.allVersions = [mmseDataA, mmseDataB, mmseDataC]
            self.selectedData = allVersions.randomElement() ?? mmseDataA
        }
    
    var body: some View {
        Group {
            if !quizStarted {
                // Başlangıç Ekranı: "Start Quiz" ve "Help" butonları, disk bilgisi
                ScrollView {
                    VStack(spacing: 20) {
                        Text("MMSE Quiz")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            Button("Start") {
                                quizStarted = true
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
                            .sheet(isPresented: $showHelp) {
                                MMSEQuizHelpView()
                            }
                            .buttonStyle(ADStandardButtonStyle())
                        }
                    }
                    
                    .padding()
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                }
            } else if showMemoryIntro {
                VStack {
                    MemoryIntroView(memoryWord: selectedData.memoryWord)
                    Button("Next") {
                        showMemoryIntro = false
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    .padding(.top, 20)
                }
            } else if isQuizComplete {
                TaskCompletionView{ContentView()}
            } else {
                quizContent
            }
        }
    }
    
    var quizContent: some View {
        let currentQuestion = selectedData.questions[currentQuestionIndex]
        return ScrollView {
            VStack {
                Text(currentQuestion.questionText)
                    .font(.headline)
                    .padding()
                    .fixedSize(horizontal: false, vertical: true)
                
                // TTS question
                if let audioText = currentQuestion.questionAudioName {
                    QuestionAudioView(audioText: audioText)
                        .padding(.bottom, 8)
                }
                
                // Text input
                if currentQuestion.isTextInput {
                    TextField("Enter your answer", text: $userInput)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .padding()
                }
                // Multiple choice
                if !currentQuestion.choices.isEmpty {
                    ForEach(0..<currentQuestion.choices.count, id: \.self) { index in
                        let choice = currentQuestion.choices[index]
                        Button(action: { selectedChoiceIndex = index }) {
                            HStack {
                                if let text = choice.text {
                                    Text(text)
                                        .padding(.horizontal, 8)
                                }
                                if let imageName = choice.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                }
                            }
                        }
                        .buttonStyle(MultipleChoiceButtonStyle())
                        .padding(.bottom, 4)
                    }
                }
                // Single image question
                if let imageName = currentQuestion.questionImageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    
                }
                // Drawing task
                if currentQuestion.isDrawingTask, let expectedShape = currentQuestion.shapeToDraw {
                    DrawingTaskView(expectedShape: expectedShape) { isCorrect, detected in
                        drawingTaskPassed = isCorrect
                    }
                }
                
                if !currentQuestion.isDrawingTask {
                    Button("Next") {
                        // Example: check correctness if needed
                        if currentQuestionIndex < selectedData.questions.count - 1 {
                            currentQuestionIndex += 1
                            userInput = ""
                            drawingTaskPassed = nil
                            selectedChoiceIndex = nil
                        } else {
                            isQuizComplete = true
                        }
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    .padding(.top, 10)
                }
            }
        }
        
    }
    
    
    // MARK: - MMSEQuizHelpView (Help Ekranı)
    enum MMSEHelpStep: Int, CaseIterable {
        case listeningPart1
        case listeningPart2
        case textInputPart
        case drawingPart
    }
    
    struct MMSEQuizHelpView: View {
        @Environment(\.dismiss) var dismiss
        @State private var currentStep: MMSEHelpStep = .listeningPart1
        
        var body: some View {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                switch currentStep {
                case .listeningPart1:
                    HelpListeningPart1View(onNext: goToNextStep)
                case .listeningPart2:
                    HelpListeningPart2View(onNext: goToNextStep)
                case .textInputPart:
                    HelpTextInputPartView(onNext: goToNextStep)
                case .drawingPart:
                    HelpDrawingPartView(onNext: goToNextStep)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Help")
        }
        
        private func goToNextStep() {
            // Sıradaki adım veya kapatma
            if let next = MMSEHelpStep(rawValue: currentStep.rawValue + 1),
               next.rawValue < MMSEHelpStep.allCases.count {
                currentStep = next
            } else {
                dismiss()
            }
        }
    }
    
    
    struct HelpListeningPart1View: View {
        @State private var hasPlayed: Bool = false
        @State private var showHand: Bool = false
        @State private var handOffset: CGSize = CGSize(width: -40, height: -40) // Başlangıç offset'i, butondan uzakta
        @State private var animateHand: Bool = false
        let onNext: () -> Void
        
        var body: some View {
            ScrollView {
                VStack(spacing: 10) {
                    Text("For Listening Task, please click on the 'Play Audio' button to listen. Be careful, you have only one chance!")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    ZStack {
                        Button(action: {}) {
                            Text(hasPlayed ? "Played" : "Play Audio")
                        }
                        .buttonStyle(MultipleChoiceButtonStyle())
                        
                        // El ikonu: Butonun üzerine doğru animasyonla gelecek
                        if showHand {
                            Image(systemName: "hand.point.up.left.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .offset(handOffset)
                                .transition(.move(edge: .leading))
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    Button("Next") {
                        onNext()
                    }
                    .padding(.bottom, 20)
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .navigationTitle("Help")
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.easeInOut(duration: 1)) {
                        showHand = true
                        handOffset = .zero
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        hasPlayed = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut(duration: 1)) {
                        // "Next" butonunun konumuna göre offset ayarlayın (deneme-yanılma ile)
                        // Örneğin, (0, 150) alt tarafa hareket etsin
                        handOffset = CGSize(width: 0, height: 110)
                    }
                }
            }
        }
    }
    
    struct HelpListeningPart2View: View {
        let onNext: () -> Void
        @State private var showHandIcon = false
        @State private var handOffset: CGSize = CGSize(width: -60, height: -60)
        @State private var hasPlayed: Bool = false
        @State private var selectedOption: Int? = nil
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Listen and choose the correct match.")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // "Play Audio" butonu + el ikonu (aynı ZStack içerisinde)
                    ZStack {
                        Button(action: {
                            // Gerçek kullanımda audio oynatma burada gerçekleşir.
                        }) {
                            Text(hasPlayed ? "Played" : "Play Audio")
                        }
                        .buttonStyle(MultipleChoiceButtonStyle())
                        
                        if showHandIcon {
                            Image(systemName: "hand.point.up.left.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .offset(handOffset)
                                .zIndex(1)
                        }
                    }
                    
                    // Multiple Choice seçenekleri
                    VStack(spacing: 10) {
                        multipleChoiceButton("Option 1", tag: 1)
                        multipleChoiceButton("Option 2", tag: 2)
                        multipleChoiceButton("Option 3", tag: 3)
                    }
                    
                    Button("Next") {
                        onNext()
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .navigationTitle("Help")
            }
            .onAppear {
                runDemo()
            }
        }
        
        private func multipleChoiceButton(_ text: String, tag: Int) -> some View {
            Button(action: {
                selectedOption = tag
            }) {
                Text(text)
                    .foregroundColor(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(selectedOption == tag ? Color.blue.opacity(0.3) : Color.clear)
                    .cornerRadius(8)
            }
            .buttonStyle(MultipleChoiceButtonStyle())
        }
        
        private func runDemo() {
            // Adım 1: 1 saniye sonra el ikonu "Play Audio" butonunun ortasına gelir.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    showHandIcon = true
                    handOffset = .zero  // "Play Audio" butonunun konumuna yakın
                }
            }
            
            // Adım 2: 1.5 saniye sonra, metin "Play Audio" yerine "Played" olur.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                hasPlayed = true
            }
            
            // Adım 3: 3 saniye sonra el ikonu, örneğin "Option 2" butonuna hareket eder.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    // Buradaki offset değerini, "Option 2" butonunun konumuna göre ayarlayın.
                    handOffset = CGSize(width: 0, height: 150)
                }
                selectedOption = 2
            }
            
            // Adım 4: 4.5 saniye sonra el ikonu "Next" butonuna gider.
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    // "Next" butonunun konumuna göre offset ayarlayın.
                    handOffset = CGSize(width: 0, height: 300)
                }
            }
        }
    }
    
    struct HelpTextInputPartView: View {
        let onNext: () -> Void
        // El ikonu görünümü ve konumunu yönetmek için state
        @State private var showHandIcon = false
        @State private var handOffset: CGSize = CGSize(width: -50, height: -50)
        
        // Metin girişi (demo amaçlı - gerçek input kilitli veya kısıtlı olabilir)
        @State private var userInput = ""
        
        var body: some View {
            ScrollView {
                VStack(spacing: 10) {
                    // Üstte açıklama
                    Text("For text input questions, tap the field to speak your answer, the system will write it down for you.")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // TextField + El ikonu
                    ZStack(alignment: .leading) {
                        // Metin girişi
                        TextField("Enter your answer", text: $userInput)
                            .textFieldStyle(DefaultTextFieldStyle())
                            .disabled(true) // Demo için pasif; gerçek kullanımda değişebilir.
                            .frame(width: 180)
                        
                        // El ikonu
                        if showHandIcon {
                            Image(systemName: "hand.point.up.left.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .offset(handOffset)
                                .zIndex(1)
                        }
                    }
                    
                    Spacer()
                    
                    // "Next" butonu
                    Button("Next") {
                        onNext()
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .navigationTitle("Help")
            }
            .onAppear {
                runDemo()
            }
        }
        
        private func runDemo() {
            // 1) 1 saniye sonra el ikonu TextField’in üzerine animasyonla gelir.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 1)) {
                    showHandIcon = true
                    handOffset = .zero  // TextField'in konumuna yakın
                }
            }
            // 2) 3 saniye sonra el ikonu "Next" butonuna doğru animasyonla kayar.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 1)) {
                    // Bu offset değerini, "Next" butonunun konumuna göre ayarlayın.
                    handOffset = CGSize(width: 65, height: 100)
                }
            }
        }
    }
    
    struct HelpDrawingPartView: View {
        let onNext: () -> Void
        // El ikonu konumu ve görünürlüğü
        @State private var showHandIcon = false
        @State private var handOffset: CGSize = CGSize(width: -60, height: -60)
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    // Açıklama metni
                    Text("For drawing tasks, use the canvas to draw the shape requested. Please keep in mind that you should not leave your fingertip from the device while drawing.")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // Basit bir beyaz "canvas" simülasyonu
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 150, height: 150)
                        
                        // El ikonu, bu canvas üzerine doğru hareket ederek
                        // kullanıcının buraya çizmesi gerektiğini simüle eder
                        if showHandIcon {
                            Image(systemName: "hand.point.up.left.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.black)
                                .offset(handOffset)
                                .zIndex(1)
                        }
                    }
                    
                    Spacer()
                    
                    // "Next" butonu
                    Button("Next") {
                        onNext()
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .navigationTitle("Help")
            }
            .onAppear {
                runDemo()
            }
        }
        
        private func runDemo() {
            // 1 saniye sonra el ikonu görünür ve canvas ortasına doğru animasyonla ilerler
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    showHandIcon = true
                    handOffset = .zero
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    showHandIcon = true
                    handOffset = CGSize(width: 0, height: 300)
                }
            }
        }
    }
}


