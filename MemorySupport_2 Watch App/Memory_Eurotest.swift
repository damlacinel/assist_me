//
//  Memory_Eurotest.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 25.01.25.
//
import SwiftUI

struct EuroTestGameView: View {
    // MARK: - Game State
    @State private var currentCurrency = ""
    @State private var options: [String] = []
    @State private var selectedOption: String? = nil
    @State private var testResults: [TestResult] = []
    @State private var showResults = false

    // MARK: - Admin/Add-Question Flow
    @State private var showPasswordPrompt = false
    @State private var showAddQuestionPrompt = false
    @State private var showAddQuestionForm = false
    @State private var enteredPassword = ""
    @State private var newCurrency = ""
    @State private var newOptions = Array(repeating: "", count: 4)

    // MARK: - Intro & Countdown
    @State private var startTestMessage = true
    @State private var showCountdown = false
    @State private var countdown = 3

    // MARK: - Progress
    @State private var testStarted = false
    @State private var questionCount = 0
    @State private var maxQuestions = 6
    @State private var askedCurrencies: Set<String> = []

    // MARK: - Help
    @State private var showHelp: Bool = false

    // MARK: - Data (currency -> correct country)
    @State private var currencyData = [
        "Euro": "European Union",
        "Pound": "United Kingdom",
        "Franc": "Switzerland",
        "Krona": "Sweden",
        "Forint": "Hungary",
        "Zloty": "Poland",
        "Kuna": "Croatia"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {

                // Top actions: Add Question & Help
                HStack {
                    Button(action: { showAddQuestionPrompt = true }) {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    .sheet(isPresented: $showAddQuestionPrompt) {
                        // Simple gate before opening the password prompt
                        ScrollView {
                            VStack(spacing: 16) {
                                Text("Do you want to challenge yourself and add more questions?")
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                                    .padding()

                                HStack(spacing: 10) {
                                    Button("Yes") {
                                        // FIX: go to password prompt directly
                                        showPasswordPrompt = true
                                        showAddQuestionPrompt = false
                                    }
                                    .buttonStyle(ADStandardButtonStyle())

                                    Button("No") {
                                        showAddQuestionPrompt = false
                                    }
                                    .buttonStyle(ADStandardButtonStyle())
                                }
                            }
                            .padding()
                            .background(Color.black.edgesIgnoringSafeArea(.all))
                        }
                    }

                    Button(action: { showHelp = true }) {
                        Image(systemName: "h.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    .sheet(isPresented: $showHelp) {
                        MultipleChoiceDemoView()
                    }
                }
                .padding()

                // Intro → Countdown → Start → Questions → Completion
                if startTestMessage {
                    VStack(spacing: 10) {
                        Text("The Eurotest requires matching currencies to their corresponding countries.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Test will start soon, good luck!")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                    .onAppear {
                        // Delayed start: show intro for 10 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            startCountdown()
                        }
                    }

                } else if showCountdown {
                    Text("Starting in \(countdown)...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                        .onAppear { startCountdownTimer() }

                } else if !testStarted {
                    // Manual start fallback
                    VStack(spacing: 10) {
                        Text("EuroTest: Match the Currency")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Button(action: startTest) {
                            Text("Start")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .buttonStyle(ADStandardButtonStyle())
                    }

                } else if questionCount >= maxQuestions {
                    // Completion screen
                    TaskCompletionView { DailyExercisesView() }

                } else {
                    // Active question
                    VStack(spacing: 10) {
                        Text("Currency: \(currentCurrency)")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(3)

                        // NOTE: Keep custom background to show selection highlight
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selectedOption = option
                                checkAnswer(option)
                            }) {
                                Text(option)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedOption == option ? Color.yellow : Color.blue)
                                    .cornerRadius(10)
                                    .animation(.easeInOut, value: selectedOption)
                            }
                            // Intentionally NOT using MultipleChoiceButtonStyle here,
                            // so our selected state background remains visible.
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        // Results sheet
        .sheet(isPresented: $showResults) {
            TestResultsView(testResults: testResults)
        }
        // Caregiver password gate
        .sheet(isPresented: $showPasswordPrompt) {
            ScrollView {
                VStack(spacing: 14) {
                    Text("Caregiver Password")
                        .font(.headline)
                        .foregroundColor(.white)

                    SecureField("Enter Password", text: $enteredPassword)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                        .foregroundColor(.white)

                    Button("Submit") {
                        checkPassword()
                    }
                    .buttonStyle(ADStandardButtonStyle())

                    Button("Cancel") {
                        showPasswordPrompt = false
                        enteredPassword = ""
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
            }
        }
        // Add-question form
        .sheet(isPresented: $showAddQuestionForm) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Add New Question")
                        .font(.headline)
                        .foregroundColor(.white)

                    // New currency (question)
                    TextField("Currency:", text: $newCurrency)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    // New options (first is correct by convention here)
                    ForEach(0..<4, id: \.self) { index in
                        TextField("Option \(index + 1)", text: Binding(
                            get: { newOptions.indices.contains(index) ? newOptions[index] : "" },
                            set: { if newOptions.indices.contains(index) { newOptions[index] = $0 } }
                        ))
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }

                    Button("Add Question") {
                        // Minimal validation: require all fields
                        guard !newCurrency.isEmpty, newOptions.allSatisfy({ !$0.isEmpty }) else { return }
                        // Convention: first option is treated as the correct answer
                        currencyData[newCurrency] = newOptions[0]
                        newCurrency = ""
                        newOptions = Array(repeating: "", count: 4)
                        showAddQuestionForm = false
                    }
                    .buttonStyle(ADStandardButtonStyle())

                    Button("Cancel") {
                        showAddQuestionForm = false
                        newCurrency = ""
                        newOptions = Array(repeating: "", count: 4)
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
            }
        }
    }

    // MARK: - Flow: Intro → Countdown → Start
    private func startCountdown() {
        startTestMessage = false
        showCountdown = true
    }

    private func startCountdownTimer() {
        guard countdown > 0 else {
            showCountdown = false
            testStarted = true
            startNewRound()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            countdown -= 1
            startCountdownTimer()
        }
    }

    private func startTest() {
        testStarted = true
        startNewRound()
    }

    // MARK: - Round lifecycle
    private func startNewRound() {
        guard questionCount < maxQuestions else { return }
        questionCount += 1
        selectedOption = nil

        // Pick an unseen currency
        let unseen = currencyData.keys.filter { !askedCurrencies.contains($0) }
        guard let next = unseen.randomElement() else {
            // No more questions available
            return
        }
        currentCurrency = next
        askedCurrencies.insert(next)

        // 1 correct + 2 incorrect options
        let correct = currencyData[currentCurrency] ?? ""
        let incorrect = currencyData.values
            .filter { $0 != correct }
            .shuffled()
            .prefix(2)

        options = ([correct] + incorrect).shuffled()
    }

    private func checkAnswer(_ answer: String) {
        let correct = currencyData[currentCurrency] ?? ""
        let date = Date()

        testResults.append(TestResult(date: date, currency: currentCurrency, correctAnswer: correct))

        // Continue with the next question after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            startNewRound()
        }
    }

    // MARK: - Admin gate
    private func checkPassword() {
        if enteredPassword == "1234" {
            showPasswordPrompt = false
            enteredPassword = ""
            showAddQuestionForm = true
        } else {
            // Invalid password: simply clear the field (could show an error label)
            enteredPassword = ""
        }
    }
}

// MARK: - Models & Demo Views

struct TestResult: Identifiable {
    let id = UUID()
    let date: Date
    let currency: String
    let correctAnswer: String
}

struct MultipleChoiceDemoView: View {
    // 0 = idle, 1 = "Option" tapped, 2 = moving to "Next", 3 = final message
    @State private var step: Int = 0
    @State private var handX: CGFloat = 0
    @State private var handY: CGFloat = -50

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    Text("How to Perform the EuroTest")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    // OPTION button (disabled – demo only)
                    Button(action: {}) {
                        Text("Option")
                            .font(.system(size: 14))
                            .foregroundColor(step >= 1 ? .yellow : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(step >= 1 ? Color.blue.opacity(0.7) : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(true)
                    .buttonStyle(MultipleChoiceButtonStyle())
                    .padding(.top, 10)

                    // NEXT button (disabled – demo only)
                    Button("Next") {}
                        .disabled(true)
                        .buttonStyle(ADStandardButtonStyle())
                        .padding(.vertical, 10)

                    if step == 3 {
                        Text("Clicking on 'Next' confirms the selected choice. If more questions remain, the next one appears. All questions follow the same logic.")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }

                // Hand icon (demo pointer)
                Image(systemName: "hand.point.up.left.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .offset(x: handX, y: handY)
                    .opacity(step == 0 ? 0 : 1)
                    .animation(.easeInOut(duration: 0.5), value: handX)
                    .animation(.easeInOut(duration: 0.5), value: handY)
            }
        }
        .onAppear {
            // Step 1: tap "Option"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                step = 1
                withAnimation(.easeInOut(duration: 0.5)) {
                    handX = 0
                    handY = 80
                }
            }
            // Step 2: move to "Next"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                step = 2
                withAnimation(.easeInOut(duration: 0.5)) {
                    handY = 160
                }
            }
            // Step 3: final message
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                step = 3
            }
        }
    }
}
