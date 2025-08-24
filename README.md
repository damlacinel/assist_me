# Assist Me!

This repository contains the source code of **Assist Me!**, a smartwatch-based digital support system developed as part of a **Bachelor’s Thesis in Informatics** at the **Technical University of Munich (TUM)**.  
The project explores how gamification and digital support can improve the daily lives of individuals living with **Alzheimer’s disease**, while also supporting caregivers and healthcare professionals .

---

## Project Context

Alzheimer’s disease is a progressive neurodegenerative disorder that impacts memory, behavior, and daily functioning.  
Traditional care places a heavy burden on families and healthcare systems, creating a need for **innovative, technology-based interventions** .

**Assist Me!** addresses this challenge by providing a **wearable support tool** that combines:
- **Cognitive training activities**
- **Daily assistance tools**
- **Gamification-based motivation systems**
- **Continuous monitoring features**

The application is designed primarily for **early to mid-stage Alzheimer’s patients**, aiming to maintain independence, improve quality of life, and assist with early intervention strategies .

---

## Features

- **AI-Generated Photobook**: Reminiscence therapy through personalized digital photo stories.  
- **Cognitive Games**: Includes EuroTest, Paired Associate Learning (PAL), and Clock Construction.  
- **Medication Tracking**: Smart reminders powered by Bluetooth beacons for adherence support.  
- **MMSE Cognitive Assessment**: Weekly monitoring of disease progression.  
- **Gamification (Click & Connect system)**: Reward-based engagement to sustain motivation.  
- **iOS Companion App**: Integration for data handling, caregiver support, and cloud synchronization .  

---

## Technologies

- **SwiftUI** and **WatchKit** for Apple Watch & iOS interface  
- **CoreData & CloudKit** for local and cloud storage  
- **Bluetooth Beacons** for medication tracking and room-level navigation  
- **OpenAI API integration** for story generation in the photobook module   

---

## Evaluation

The usability of **Assist Me!** was evaluated through an online survey with **38 participants** (caregivers and patients).  
- The **System Usability Scale (SUS)** yielded an average score of **78.2**, indicating high user satisfaction.  
- Feedback highlighted strengths in accessibility and engagement, and suggested improvements such as multilingual support and advanced customization .  

---


## Getting Started

### Requirements
- macOS 13.0 or later  
- Xcode 15.0 or later  
- Swift 5.9 or later  
- Apple Watch (watchOS 10 or later) or Apple Watch Simulator  
- Apple Developer account (required for testing Bluetooth beacons and CloudKit synchronization)  

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/<damlacinel>/assist_me.git
   cd assist_me

2. Open the project in XCode:
   ```bash
    open AssistMe.xcodeproj

4. Select a target:
•	Apple Watch Simulator for initial testing
•	Physical Apple Watch (paired with an iPhone) for full functionality

5. Build and run the application:
•	Use the play button in Xcode
•	Ensure that the iOS companion app is also installed if running on a real device
