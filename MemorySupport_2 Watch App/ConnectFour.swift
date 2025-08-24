//
//  File.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 19.02.25.
//

import SwiftUI

// MARK: - Game Logic and Player
enum Player {
    case none
    case human
    case computer
}

struct ConnectFourGame {
    var board: [[Player]]
    var currentPlayer: Player
    var gameOver: Bool
    var winner: Player?
    
    init() {
        board = Array(repeating: Array(repeating: .none, count: 4), count: 4)
        currentPlayer = .human
        gameOver = false
        winner = nil
    }
    
    mutating func reset() {
        board = Array(repeating: Array(repeating: .none, count: 4), count: 4)
        currentPlayer = .human
        gameOver = false
        winner = nil
    }
    
    mutating func dropToken(in column: Int) -> Bool {
        guard column >= 0 && column < 4, !gameOver else { return false }
        for row in (0..<4).reversed() {
            if board[row][column] == .none {
                board[row][column] = currentPlayer
                
                if checkWin(for: currentPlayer) {
                    gameOver = true
                    winner = currentPlayer
                } else if checkDraw() {
                    gameOver = true
                    winner = Player.none
                } else {
                    currentPlayer = (currentPlayer == .human ? .computer : .human)
                }
                return true
            }
        }
        return false
    }
    
    func checkWin(for player: Player) -> Bool {
        for row in 0..<4 {
            if board[row].allSatisfy({ $0 == player }) { return true }
        }
        for col in 0..<4 {
            if (0..<4).allSatisfy({ board[$0][col] == player }) { return true }
        }
        let diag1 = (0..<4).allSatisfy({ board[$0][$0] == player })
        let diag2 = (0..<4).allSatisfy({ board[$0][3 - $0] == player })
        return diag1 || diag2
    }
    
    func checkDraw() -> Bool {
        return !board.flatMap({ $0 }).contains(.none)
    }
    
    mutating func computerMove() {
        guard !gameOver else { return }
        let validColumns = (0..<4).filter { board[0][$0] == .none }
        if let chosen = validColumns.randomElement() {
            _ = dropToken(in: chosen)
        }
    }
}

// MARK: - ConnectFourView
struct ConnectFourView: View {
    @State private var game = ConnectFourGame()
    @State private var showAlert = false
    @State private var alertMessage = ""
    // Görev durumlarını tutan state; burada örnek değerler veriliyor
    @State private var completedTasks: [String: Bool] = [
        "Complete Clock Construction in Memory Games!": true,
        "Complete PAL Test in Memory Games!": false,
        "Complete Eurotest in Memory Games!": false,
        "Take your medications on time!" : true,
        "Add 2 new Photos to your Digital Photobook!": false,
        "Complete the weekly MMSE Test!": false
    ]
    
    // Yeni state'ler: Giriş ekranı ve help butonu
    @State private var gameStarted: Bool = false
    @State private var showHelp: Bool = false
    @State private var showCompletionSheet: Bool = false
    @State private var showTasks: Bool = false
    
    // Computed property: tamamlanan disk sayısı
    var completedDisks: Int {
        completedTasks.values.filter { $0 }.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            if !gameStarted {
                // Giriş Ekranı
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Connect & Collect")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        // Disk sayısı bilgisi
                        Text("You have currently \(completedDisks) disks")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.yellow)
                        
                        Text("Collect 8 disks by completing tasks described at the bottom of this page, in the right button. Then click on 'Start Game' to play the game. If you need any instructions, click on the middle button below.")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                        
                        HStack(spacing: 5) {
                            Button("Start") {
                                game.reset()
                                gameStarted = true
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
                            
                            Button(action: {
                                   showTasks = true
                               }) {
                                   Image(systemName: "list.bullet.rectangle")
                                       .resizable()
                                       .frame(width: 50, height: 50)
                                       .foregroundColor(.white)
                               }
                               .buttonStyle(ADStandardButtonStyle())
                               .sheet(isPresented: $showTasks) {
                                   TaskTableView(completedTasks: $completedTasks)
                               }
                        }
                        
                    }
                    .padding()
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                }
            } else {
                // Oyun Ekranı
                ScrollView {
                    VStack {
                        VStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { row in
                                HStack(spacing: 6) {
                                    ForEach(0..<4, id: \.self) { col in
                                        CellView(player: game.board[row][col])
                                            .onTapGesture {
                                                if game.currentPlayer == .human && !game.gameOver {
                                                    if game.dropToken(in: col) {
                                                        checkGameStatus()
                                                        if game.currentPlayer == .computer && !game.gameOver {
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                                game.computerMove()
                                                                checkGameStatus()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        
                    }
                    .padding()
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Game Over"),
                              message: Text(alertMessage),
                              dismissButton: .default(Text("OK")))
                    }
                }
            }
        }
        .sheet(isPresented: $showHelp) {
            ConnectFourDemoHelpView()
        }
        .sheet(isPresented: $showCompletionSheet) {
            NavigationView {
                // Eğer user kazandıysa isWin true, aksi halde false
                TaskCompletion(resultMessage: alertMessage, onContinue: {
                    ContentView()
                }, isWin: (game.winner == .human))
            }
        }
    }
    
    func checkGameStatus() {
        if game.gameOver {
            if let winner = game.winner {
                if winner == .human {
                    alertMessage = "You win! You need to show this page to your caregiver to collect your reward for this week!"
                } else if winner == .computer {
                    alertMessage = "Computer wins! Unfortunately, there is not any rewards this week."
                } else {
                    alertMessage = "It's a draw! Unfortunately, there is not any rewards this week. "
                }
            }
            showCompletionSheet = true
        }
    }
}

// MARK: - CellView
struct CellView: View {
    var player: Player
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .cornerRadius(5)
            if player == .human {
                Circle()
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
            } else if player == .computer {
                Circle()
                    .foregroundColor(.red)
                    .frame(width: 30, height: 30)
            }
        }
    }
}

// MARK: - TaskTableView
struct TaskTableView: View {
    @Binding var completedTasks: [String: Bool]
    
    let taskRewards: [String: Int] = [
        "Complete Clock Construction in Memory Games!": 1,
        "Complete PAL Test in Memory Games!": 1,
        "Complete Eurotest in Memory Games!": 1,
        "Take your medications on time!" : 2,
        "Add 2 new Photos to your Digital Photobook!": 2,
        "Complete the weekly MMSE Test!": 1
    ]
    
    var body: some View {
        VStack {
            List {
                ForEach(taskRewards.keys.sorted(), id: \.self) { task in
                    HStack {
                        Image(systemName: completedTasks[task]! ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(completedTasks[task]! ? .green : .gray)
                        Text(task)
                            .font(.system(size: 15))
                            .foregroundColor(completedTasks[task]! ? .green : .white)
                        
                        Spacer()
                        
                        Text("\(taskRewards[task]!) Disk")
                            .font(.system(size: 15))
                            .foregroundColor(.yellow)
                            .bold()
                    }
                    .padding(.vertical, 2)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

// MARK: - ConnectFourHelpView (Help Ekranı)
struct ConnectFourHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    Text("""
1. Tap on a column to drop your token.
2. Your token will fall to the lowest available position, and is colored blue.
3. After your move, the computer will play for one move with a red colored disk.
4. The goal is to connect four tokens in a row, vertically, horizontally, or diagonally.
""")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 5)
                    
                    Text("Note: Discuss with your caregiver on the reward you want for this week, before playing!")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 5)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
                .navigationTitle("Help")
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
}

struct ConnectFourDemoHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    // Demo için 4x4'lük board
    @State private var gameDemo = ConnectFourGame()
    @State private var handPosition: CGPoint = .zero
    @State private var showHand = false
    
    // İkinci yardım sayfasını sheet ile sunmak için state
    @State private var showSecondHelpSheet = false
    
    // Sabit değerler (örnek)
    let gridWidth: CGFloat = 160
    let cellSize: CGFloat = 40
    let spacing: CGFloat = 6
    
    var body: some View {
        ZStack {
            // 4x4 Grid
            VStack(spacing: spacing) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<4, id: \.self) { col in
                            CellView(player: gameDemo.board[row][col])
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .frame(width: gridWidth, height: cellSize * 4 + spacing * 3)
            
            // El ikonu
            if showHand {
                Image(systemName: "hand.point.up.left.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .position(handPosition)
                    .animation(.easeInOut(duration: 1.0), value: handPosition)
            }
        }
        .onAppear {
            // Başlangıç konumu
            handPosition = .zero
            showHand = true
            
            // 1 saniye sonra ilk insan hamlesi (sütun 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let targetPos1 = CGPoint(x: cellSize * 2, y: 20)
                withAnimation {
                    handPosition = targetPos1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dropTokenDemo(column: 1, for: .human)
            }
            
            // 3 saniye sonra bilgisayar hamlesi (sütun 2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                dropTokenDemo(column: 2, for: .computer)
            }
            
            // 5 saniye sonra ikinci insan hamlesi (sütun 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                let targetPos2 = CGPoint(x: cellSize, y: 20)
                withAnimation {
                    handPosition = targetPos2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                dropTokenDemo(column: 0, for: .human)
            }
            
            // 7 saniye sonra ikinci yardım sayfasını sheet ile açalım
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.5) {
                showSecondHelpSheet = true
            }
        }
        .sheet(isPresented: $showSecondHelpSheet) {
            // İkinci yardım sayfası (örneğin ConnectFourHelpView)
            ConnectFourHelpView()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    private func dropTokenDemo(column: Int, for player: Player) {
        for row in (0..<4).reversed() {
            if gameDemo.board[row][column] == .none {
                gameDemo.board[row][column] = player
                return
            }
        }
    }
}

// MARK: - TaskCompletionView
struct TaskCompletion<NextView: View>: View {
    let resultMessage: String
    let onContinue: () -> NextView
    @State private var navigate = false
    let isWin: Bool
    
    var body: some View {
        ScrollView {
            ZStack {
                
                if isWin {
                    FireworksAnimationView()
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                }
                
                VStack(spacing: 10) {
                    // Sonuç mesajı her zaman ekranda görünür.
                    Text(resultMessage)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // "Continue" butonuna basıldığında navigate true oluyor.
                    Button("Close") {
                        navigate = true
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    
                    // NavigationLink görünmez; yalnızca "Continue" butonuyla tetiklenir.
                    NavigationLink(destination: onContinue(), isActive: $navigate) {
                        EmptyView()
                    }
                    .frame(width: 0, height: 0)
                    .hidden()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


