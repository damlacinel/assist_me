//
//  Photobook.swift
//  Memory Support Watch App
//
//  Created by Damla Cinel on 01.02.25.
//
import SwiftUI
import AVFoundation
import PhotosUI

// MARK: - Photobook Manager: Handles storage, TTS, and AI-generated stories
class PhotobookManager: ObservableObject {
    @Published var photos: [PhotobookEntry] = []            // Published list of saved photos
    private let synthesizer = AVSpeechSynthesizer()         // For text-to-speech playback
    private let openAIAPIKey = "your_api_key"               // OpenAI API key
    
    let sampleImages: [String] = [                          // Example images (demo)
        "sample_1",
        "sample_2",
        "sample_3"
    ]
    
    init() {
        self.photos = loadPhotos()                          // Load saved photos at init
    }

    // Add a photo: save image locally, generate story, and append entry
    func addPhoto(image: UIImage, people: String, location: String, action: String) {
        // Generate unique filename
        let fileName = UUID().uuidString + ".jpg"
        if let data = image.jpegData(compressionQuality: 0.8) {
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                try data.write(to: url)
                print("Image saved to disk: \(fileName)")
            } catch {
                print("Failed to save image: \(error)")
            }
        }
        
        // Generate AI story and add new entry
        generateStory(people: people, location: location, action: action) { story in
            let newEntry = PhotobookEntry(id: UUID(), imageName: fileName, story: story, date: Date())
            DispatchQueue.main.async {
                self.photos.append(newEntry)
                self.photos.sort { $0.date > $1.date }
                self.savePhotos()
                print("Photo Added & Saved: \(fileName)")
            }
        }
    }

    // Return Documents directory URL
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Play a story aloud using TTS
    func playStory(_ story: String) {
        print("Playing Story: \(story)")
        let utterance = AVSpeechUtterance(string: story)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    // Generate a short story using OpenAI API
    private func generateStory(people: String, location: String, action: String, completion: @escaping (String) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        // Chat messages for OpenAI API
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are an AI assistant that generates creative short stories based on user-provided photo details."],
            ["role": "user", "content": "Create a short engaging story in English based on the following details: People: \(people), Location: \(location), Action: \(action). Make it imaginative and interesting."]
        ]
        
        // Request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 150
        ]
        
        // Build POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("JSON Serialization Error: \(error)")
            completion("An unexpected memory was created.")
            return
        }
        
        print("Sending API Request: \(requestBody)")
        
        // API call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Request Error: \(error.localizedDescription)")
                completion("An unexpected memory was created.")
                return
            }
            
            guard let data = data else {
                print("API Response Error: No Data Received")
                completion("An unexpected memory was created.")
                return
            }
            
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("📩 Raw OpenAI Response: \(rawJSON)")
            }
            
            // Decode response
            do {
                let result = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                if let generatedStory = result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines), !generatedStory.isEmpty {
                    print("Story Generated: \(generatedStory)")
                    completion(generatedStory)
                } else {
                    print("Empty story response from OpenAI")
                    completion("An unexpected memory was created.")
                }
            } catch {
                print("JSON Decoding Error: \(error)")
                completion("An unexpected memory was created.")
            }
        }.resume()
    }

    // Save current photos array to UserDefaults
    private func savePhotos() {
        if let encoded = try? JSONEncoder().encode(photos) {
            UserDefaults.standard.set(encoded, forKey: "savedPhotos")
        }
    }
    
    /// Load saved photos from UserDefaults
    private func loadPhotos() -> [PhotobookEntry] {
        if let savedData = UserDefaults.standard.data(forKey: "savedPhotos"),
           let decoded = try? JSONDecoder().decode([PhotobookEntry].self, from: savedData) {
            return decoded
        }
        return []
    }
}

// MARK: - Codable Models for API Responses

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let text: String
}

struct PhotobookEntry: Identifiable, Codable {
    let id: UUID
    let imageName: String
    let story: String
    let date: Date
}

struct OpenAIChatResponse: Codable {
    let choices: [ChatChoice]
}

struct ChatChoice: Codable {
    let message: ChatMessage
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Help Screens

struct HelpViewPhotobook: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Help")
                        .font(.system(size:16))
                        .padding(.top)
                    
                    Text("""
    This Photobook app lets you:
    • Add Photo: Capture and add a new memory.
    • View My Photobook: See all your saved memories.
    """)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 5)
                    
                    Text("Tap 'Next' to learn how to add details.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 5)
                    
                    NavigationLink(destination: PhotobookHelpPageTwo()) {
                        Text("Next")
                            .padding()
                            .foregroundColor(.white)
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Help")
        }
    }
}

struct PhotobookHelpPageTwo: View {
    @Environment(\.dismiss) var dismiss
    @State private var navigate = false
    @State private var handPosition: CGPoint = .zero
    @State private var showDoneButton = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    Text("How to add details to the photo")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    GeometryReader { geo in
                        ZStack {
                            Image("examplePhoto")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                            // Hand icon demo overlay
                            Image(systemName: "hand.point.up.left.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                                .position(handPosition)
                        }
                        .frame(width: 200, height: 200)
                        .onAppear {
                            // Start animation of hand icon
                            handPosition = CGPoint(x: 0, y: 0)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    let frame = geo.frame(in: .local)
                                    handPosition = CGPoint(x: frame.midX, y: frame.midY)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    showDoneButton = true
                                }
                            }
                        }
                    }
                    .frame(width: 200, height: 200)
                    
                    Text("When you tap on a photo, the details screen will open so you can add additional information to your memory.")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    Button("Done") { navigate = true }
                        .buttonStyle(ADStandardButtonStyle())
                        .disabled(!showDoneButton)
                    
                    NavigationLink(destination: PhotobookIntroView(), isActive: $navigate) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Help")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Intro Screen

struct PhotobookIntroView: View {
    @StateObject private var photobookManager = PhotobookManager()
    @State private var selectedImage: String?
    @State private var showHelp: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // Help button
                    Button(action: { showHelp = true }) {
                        Image(systemName: "h.circle.fill")
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(ADStandardButtonStyle())
                    .sheet(isPresented: $showHelp) {
                        HelpViewPhotobook()
                    }
                    
                    // View photobook
                    NavigationLink(destination: ViewPhotobookView().environmentObject(photobookManager)) {
                        Text("View My Photobook")
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                    
                    // Add new photo
                    NavigationLink(destination: RootView()) {
                        Text("Add Photo")
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(MultipleChoiceButtonStyle())
                }
                .padding()
                .background(Color.black.edgesIgnoringSafeArea(.all))
            }
        }
    }
}

// Helper to load UIImage from saved filename
func loadImageFromDisk(fileName: String) -> UIImage? {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    return UIImage(contentsOfFile: fileURL.path)
}

// MARK: - Photobook List View

struct ViewPhotobookView: View {
    @EnvironmentObject var photobookManager: PhotobookManager

    var body: some View {
        ScrollView {
            VStack {
                Text("My Photobook")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                
                if !photobookManager.photos.isEmpty {
                    VStack(spacing: 15) {
                        ForEach(photobookManager.photos) { entry in
                            VStack {
                                if let uiImage = loadImageFromDisk(fileName: entry.imageName) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(10)
                                        .onTapGesture {
                                            photobookManager.playStory(entry.story)
                                        }
                                } else {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: 150, height: 150)
                                }
                                Text(entry.date, style: .date)
                                    .foregroundColor(.white)
                                    .font(.footnote)
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("No Photos Yet")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .padding()
                }
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

// MARK: - Photo Selection Flow (from WatchConnectivity)

struct PhotoSelectionView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var photobookManager = PhotobookManager()
    
    @State private var showQuestionnaire = false
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing:10) {
                if connectivityManager.receivedImage.isEmpty {
                    Text("Waiting for photo from iPhone...")
                        .foregroundColor(.white)
                        .padding(.top, 40)
                } else {
                    ForEach(connectivityManager.receivedImage, id: \.self) { image in
                        Button {
                            selectedImage = image
                            showQuestionnaire = true
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showQuestionnaire) {
            if let selected = selectedImage {
                QuestionnaireView(image: selected, photobookManager: photobookManager) {
                    if let idx = connectivityManager.receivedImage.firstIndex(where: { $0.pngData() == selected.pngData() }) {
                        connectivityManager.receivedImage.remove(at: idx)
                    }
                    showQuestionnaire = false
                }
            } else {
                Text("No image available")
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

extension PhotobookManager {
    // Check if a given image is already stored (compare PNG data)
    func containsPhoto(_ image: UIImage) -> Bool {
        for entry in photos {
            if let savedImage = loadImageFromDisk(fileName: entry.imageName),
               let savedData = savedImage.pngData(),
               let newData = image.pngData(),
               savedData == newData {
                return true
            }
        }
        return false
    }
    
    // Load an image from Documents directory
    func loadImageFromDisk(fileName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
}

// MARK: - Root Navigation

struct RootView: View {
    var body: some View {
        NavigationStack {
            PhotoSelectionView()
        }
    }
}

// MARK: - Questionnaire for Adding Details

struct QuestionnaireView: View {
    let image: UIImage
    @ObservedObject var photobookManager: PhotobookManager
    
    @State private var people: String = ""
    @State private var location: String = ""
    @State private var action: String = ""
    
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var showCompletion = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Who are in the picture?")
                        .foregroundColor(.white)
                    TextField("Enter names", text: $people)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Where are you in the picture?")
                        .foregroundColor(.white)
                    TextField("Enter location", text: $location)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("What are you doing in the picture?")
                        .foregroundColor(.white)
                    TextField("Enter activity", text: $action)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    
                    Button("Save Photo") {
                        photobookManager.addPhoto(image: image, people: people, location: location, action: action)
                        onSave()
                        showCompletion = true
                    }
                    .buttonStyle(ADStandardButtonStyle())
                }
                .padding()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Add Details")
            
            NavigationLink(
                destination: TaskCompletionView(onContinue: { PhotobookIntroView() }),
                isActive: $showCompletion
            ) { EmptyView() }
            .hidden()
        }
    }
}
