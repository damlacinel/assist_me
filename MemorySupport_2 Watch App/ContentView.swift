//
//  ContentView.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 25.01.25.
//

import SwiftUI
import HealthKit
import CoreLocation
import UserNotifications
import WatchKit
import WatchConnectivity
import AVFoundation // For potential TTS
import Foundation
import CoreLocation
import Contacts


// MARK: - Entry Point
@main
struct MemorySupportApp: App {
    
    @StateObject private var appEnvironment = AppEnvironment()
    
    var body: some Scene {
        WindowGroup {
            // Use dark mode for high contrast
            NavigationView {
                ContentView()
                    .environmentObject(appEnvironment)
                    .preferredColorScheme(.dark) // Force dark for black background & white text
            }
        }
        
    }
}

// MARK: - App Environment
class AppEnvironment: ObservableObject {
    // Sağlık verileri yönetimi
    @Published var photobookManager = PhotobookManager()
}

// MARK: - Main Menu View / `ContentView`
struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var showHelp: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                
             // Title
                Text("Assist Me!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                Button(action: {
                    showHelp = true
                }) {
                    Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "h.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                        )
                            .padding(8)
                    }
                        .sheet(isPresented: $showHelp) {
                            ButtonHelpView()
                    }
                        .buttonStyle(ADStandardButtonStyle())
                
                //Weekly Dashboard
                NavigationLink(destination: ConnectFourView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "circle.grid.cross.fill",
                        label: "Connect & Collect",
                        bgColor: .blue)
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                // Memory Exercises
                NavigationLink(destination: DailyExercisesView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "brain.head.profile", // SF Symbol
                        label: "Memory Exercises",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                //Physical Activities
                NavigationLink(destination: MedicationIntroView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "pills.circle.fill",
                        label: "Medication Tracking",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                // MMSE Quiz
                NavigationLink(destination: MMSEQuizView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "questionmark.circle.fill",
                        label: "MMSE Testing",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                
                // Photobook
                NavigationLink(destination: PhotobookIntroView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "photo.stack.fill",
                        label: "My Photobook",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())

            }
            .padding(.horizontal, 8)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all)) // Black background
    }
}

// MARK: - Custom Menu Button View
/// Large, single-touch friendly button style with icon + text.
struct MenuButtonView: View {
    let iconName: String
    let label: String
    let bgColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.system(size: 25, weight: .medium))
                .foregroundColor(.white)
                .padding(.leading, 10)
            
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .padding(.leading, 6)
            
            Spacer()
        }
        .frame(height: 44) // ~44-60 pts for comfortable tapping
        .padding(.horizontal, 4)
        .background(bgColor.opacity(0.8))
        .cornerRadius(10)
    }
}



// MARK: - Daily Exercises View
struct DailyExercisesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Memory Games")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                NavigationLink(destination: EuroTestGameView()) {
                    MenuButtonView(
                        iconName: "eurosign.circle",
                        label: "EuroTest Game",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                NavigationLink(destination: PalContentView()) {
                    MenuButtonView(
                        iconName: "rectangle.on.rectangle.circle",
                        label: "Match the Icons!",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                NavigationLink(destination: ClockGameView()){
                    MenuButtonView(iconName: "clock.circle",
                                   label: "Clock Construction",
                                   bgColor: .blue)
                }
                .buttonStyle(MultipleChoiceButtonStyle())
            }
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}




// MARK: - ButtonHelpItem Model
struct ButtonHelpItem: Identifiable {
    let id = UUID()
    let iconText: String  // e.g. "h.circle.fill" or "Start"
    let description: String
    let useSFSymbol: Bool // if true, interpret iconText as an SF Symbol name
}

// MARK: - ButtonHelpView
struct ButtonHelpView: View {
    let helpItems: [ButtonHelpItem] = [
        ButtonHelpItem(iconText: "h.circle.fill",
                       description: "Shows system details for each activity.",
                       useSFSymbol: true),
        ButtonHelpItem(iconText: "list.bullet.rectangle",
                       description: "Displays all tasks with descriptions and earned disks, only used in 'Connect & Collect'.",
                       useSFSymbol: true),
        ButtonHelpItem(iconText: "questionmark.circle",
                       description: "Opens a prompt to add extra questions for Eurotest.",
                       useSFSymbol: true),
        ButtonHelpItem(iconText: "Start",
                       description: "Starts the tasks and resets the test.",
                       useSFSymbol: false)
    ]
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("How to interpret buttons?")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                ForEach(helpItems) { item in
                    // Each row: a decorative button on the left, text on the right
                    HStack(alignment: .top, spacing: 10) {
                        
                        // Decorative button
                        Button(action: {
                            // No-op: purely decorative
                        }) {
                                if item.useSFSymbol {
                                    Image(systemName: item.iconText)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                } else {
                                    Text(item.iconText)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            
                        }
                        .buttonStyle(ADStandardButtonStyle())
                        
                        // Description text
                        Text(item.description)
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                        
                 
                    }
                    .padding(.vertical, 6)
                }
                
            }
            .padding(.horizontal, 8)
        }
        .background(Color.black)
    }
}
