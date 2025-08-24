//
//  Memory_Eurotest.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 25.01.25.
//

//  EuroTestGameView.swift

import SwiftUI


struct EuroTestGameView: View {
    @State private var currentCurrency = ""
    @State private var options: [String] = []
    @State private var selectedOption: String? = nil
    @State private var testResults: [TestResult] = []
    @State private var showResults = false
    @State private var showCaregiverMessage = false
    @State private var showPasswordPrompt = false
    @State private var showAddQuestionPrompt = false
    @State private var showAddQuestionForm = false
    @State private var enteredPassword = ""
    @State private var startTestMessage = true
    @State private var showCountdown = false
    @State private var countdown = 3
    @State private var testStarted = false
    @State private var questionCount = 0
    @State private var maxQuestions = 6
    @State private var askedCurrencies: Set<String> = []
    @State private var newCurrency = ""
    @State private var newOptions = Array(repeating: "", count: 4)
    
    @State private var showHelp: Bool = false
    
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
                // Üst İkonlar
                HStack {
                   
                    Button(action: {
                        showAddQuestionPrompt = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    .sheet(isPresented: $showAddQuestionPrompt) {
                        ScrollView {
                            VStack(spacing: 16) {
                                Text("Do you want to challenge yourself and add more questions?")
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                                    .padding()

                                HStack(spacing: 10) {
                                    Button("Yes") {
                                        showCaregiverMessage = true
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
                    
                    Button(action: {
                            showHelp = true
                            }) {
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            startCountdown()
                        }
                    }
                } else if showCountdown {
                    Text("Starting in \(countdown)...")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                        .onAppear {
                            startCountdownTimer()
                        }
                } else if !testStarted {
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
                    TaskCompletionView{DailyExercisesView()}
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            Text("Currency: \(currentCurrency)")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(3)
                            
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
                                .buttonStyle(MultipleChoiceButtonStyle())
                            }
                        }
                    }
                        .padding()
                }
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .sheet(isPresented: $showResults) {
            TestResultsView(testResults: testResults)
        }
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
        .sheet(isPresented: $showAddQuestionForm) {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Add New Question")
                        .font(.headline)
                        .foregroundColor(.white)

                    TextField("Currency:", text: $newCurrency)
                        .padding()
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    ForEach(0..<4, id: \ .self) { index in
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
                        guard !newCurrency.isEmpty, newOptions.allSatisfy({ !$0.isEmpty }) else { return }
                        currencyData[newCurrency] = newOptions[0] // İlk seçeneği doğru cevap olarak ekle
                        newCurrency = ""
                        newOptions = Array(repeating: "", count: 4) // Yeni seçenekleri sıfırla
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

    private func startNewRound() {
        guard questionCount < maxQuestions else { return }
        questionCount += 1
        selectedOption = nil

        // Get a list of available currencies that have not been asked
        let availableCurrencies = currencyData.keys.filter { !askedCurrencies.contains($0) }
        guard let newCurrency = availableCurrencies.randomElement() else {
            print("No more available currencies to ask!")
            return
        }

        // Set the current currency
        currentCurrency = newCurrency
        askedCurrencies.insert(newCurrency)

        // Prepare options: 1 correct answer + 2 incorrect answers
        let correctAnswer = currencyData[currentCurrency] ?? ""
        let incorrectOptions = currencyData.values.filter { $0 != correctAnswer }.shuffled().prefix(2)

        // Shuffle the options
        options = ([correctAnswer] + incorrectOptions).shuffled()

        // Log for debugging
        print("New Round Started: Currency: \(currentCurrency), Options: \(options)")
    }

    private func checkAnswer(_ answer: String) {
        let correctAnswer = currencyData[currentCurrency] ?? ""
        let date = Date()

        testResults.append(TestResult(date: date, currency: currentCurrency, correctAnswer: correctAnswer))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            startNewRound()
        }
    }

    private func checkPassword() {
        if enteredPassword == "1234" {
            showPasswordPrompt = false
            enteredPassword = ""
            showAddQuestionForm = true
        } else {
            enteredPassword = ""
        }
    }
}

struct TestResult: Identifiable {
    let id = UUID()
    let date: Date
    let currency: String
    let correctAnswer: String
}

struct MultipleChoiceDemoView: View {
    // 0 = henüz görünmedi, 1 = Option 1’e dokundu, 2 = Next’e gidiyor, 3 = Final mesajlar
    @State private var step: Int = 0

    // El ikonunun x, y konumlarını manuel tanımlıyoruz
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
                        .padding(.top, 10)  // Sadece biraz üst boşluk
                    
                    // OPTION 1 butonu
                    Button(action: {}) {
                        Text("Option")
                            .font(.system(size: 14))
                            .foregroundColor(step >= 1 ? .yellow : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(step >= 1 ? Color.blue.opacity(0.7) : Color.blue)
                            .cornerRadius(10)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    .disabled(true)  // Demo amaçlı tıklanamaz
                    .padding(.top, 10)  // Butonlar arasında çok az boşluk

                    // NEXT butonu
                    Button("Next") {
                        // Otomatik tıklama simülasyonu yapılacak
                    }
                    .disabled(true)
                    .buttonStyle(ADStandardButtonStyle())
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    
                    // Final mesaj(lar)
                    if step == 3 {
                            Text("Clicking on 'Next' confirms the choice selection. After clicking on this button, next question appears on the screen, if any question is left. All the questions follow the same logic shown here.")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                }
                
                // El ikonu
                Image(systemName: "hand.point.up.left.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .offset(x: handX, y: handY)
                    .opacity(step == 0 ? 0 : 1)
                    // Animasyonlar
                    .animation(.easeInOut(duration: 0.5), value: handX)
                    .animation(.easeInOut(duration: 0.5), value: handY)
            }
        }
        .onAppear {
            // 1) 1 saniye sonra Option 1’e dokunma simülasyonu
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                step = 1
                withAnimation(.easeInOut(duration: 0.5)) {
                    handX = 0
                    handY = 80   // Option 1 butonuna göre ayarlayın
                }
            }
            // 2) 2 saniye sonra Next butonuna hareket
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                step = 2
                withAnimation(.easeInOut(duration: 0.5)) {
                    handY = 160  // Next butonuna göre ayarlayın
                }
            }
            // 3) 3 saniye sonra Next'e “otomatik tıklama” + final mesaj(lar)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                step = 3
            }
        }
    }
}
