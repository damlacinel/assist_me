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
import Contacts

// MARK: - Entry Point
@main
struct MemorySupportApp: App {
    @StateObject private var appEnvironment = AppEnvironment()
    
    var body: some Scene {
        WindowGroup {
            // >> High-contrast UI (dark background, light text)
            NavigationView {
                ContentView()
                    .environmentObject(appEnvironment)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

// MARK: - App Environment
final class AppEnvironment: ObservableObject {
    // >> Global managers go here (e.g., Photobook, Health, etc.)
    @Published var photobookManager = PhotobookManager()
}

// MARK: - Main Menu View
struct ContentView: View {
    @EnvironmentObject var env: AppEnvironment
    @State private var showHelp = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Title
                Text("Assist Me!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 10)
                
                // Help button
                Button(action: { showHelp = true }) {
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
                .sheet(isPresented: $showHelp) { ButtonHelpView() }
                .buttonStyle(ADStandardButtonStyle()) // >> Single-tap friendly
                
                // Weekly Dashboard
                NavigationLink(destination: ConnectFourView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "circle.grid.cross.fill",
                        label: "Connect & Collect",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                // Memory Exercises
                NavigationLink(destination: DailyExercisesView().environmentObject(env)) {
                    MenuButtonView(
                        iconName: "brain.head.profile",
                        label: "Memory Exercises",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
                
                // Medication Tracking
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
        .background(Color.black.ignoresSafeArea()) // >> Full-screen dark background
    }
}

// MARK: - Custom Menu Button
// Large, single-tap friendly row with icon + text.
// >> Use inside NavigationLinks for primary menu actions.
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
        .frame(height: 44)                  // >> Comfortable tap target (~44–60pt)
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
                
                NavigationLink(destination: ClockGameView()) {
                    MenuButtonView(
                        iconName: "clock.circle",
                        label: "Clock Construction",
                        bgColor: .blue
                    )
                }
                .buttonStyle(MultipleChoiceButtonStyle())
            }
        }
        .padding()
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Button Help
struct ButtonHelpItem: Identifiable {
    let id = UUID()
    let iconText: String     // >> "h.circle.fill" or "Start"
    let description: String  // >> What the button does
    let useSFSymbol: Bool    // >> true -> treat iconText as SF Symbol
}

struct ButtonHelpView: View {
    private let helpItems: [ButtonHelpItem] = [
        ButtonHelpItem(iconText: "h.circle.fill",
                       description: "Shows system details for each activity.",
                       useSFSymbol: true),
        ButtonHelpItem(iconText: "list.bullet.rectangle",
                       description: "Displays all tasks with descriptions and earned disks (Connect & Collect only).",
                       useSFSymbol: true),
        ButtonHelpItem(iconText: "questionmark.circle",
                       description: "Opens a prompt to add extra questions for EuroTest.",
                       useSFSymbol: true),
        ButtonHelpItem(iconText: "Start",
                       description: "Starts tasks and resets the test.",
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
                    HStack(alignment: .top, spacing: 10) {
                        // Decorative example button
                        Button(action: {}) {
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
                        
                        // Description
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
