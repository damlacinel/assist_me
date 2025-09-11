//
//  ContentView.swift
//  WatchCompanion
//
//  Created by Damla Cinel on 14.03.25.
//
import SwiftUI
import WatchConnectivity
import UIKit

// MARK: - WCSessionDelegateHandler (iOS)
// >> iOS companion: manages WCSession lifecycle & inbound messages from watch
final class WCSessionDelegateHandler: NSObject, WCSessionDelegate {
    static let shared = WCSessionDelegateHandler()
    private override init() { super.init() }

    // NOTE: On iOS this exists but the "activationDidComplete" callback is primarily relevant on watchOS.
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("iOS: WCSession activation error: \(error.localizedDescription)")
        } else {
            print("iOS: WCSession activated with state: \(activationState.rawValue)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("iOS: WCSession did become inactive")
    }
    func sessionDidDeactivate(_ session: WCSession) {
        print("iOS: WCSession did deactivate")
        WCSession.default.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("iOS: Received message: \(message)")
    }
}

// MARK: - ImagePicker (UIKit bridge)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked(image) // callback to send
            }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
}

// MARK: - Compression
func compressImage(_ image: UIImage, targetSize: CGSize, quality: CGFloat) -> Data? {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: targetSize)) }
    return resized.jpegData(compressionQuality: quality) // >> choose HEIC if desired, but Base64 expects Data anyway
}

// MARK: - Send Image via ApplicationContext (last known state)
func sendImageAsBase64(_ image: UIImage) {
    guard let data = compressImage(image,
                                   targetSize: CGSize(width: 100, height: 100),
                                   quality: 0.1) else {
        print("iOS: Failed to compress image")
        return
    }
    print("iOS: Compressed size = \(data.count) bytes")
    let payload: [String: Any] = ["imageBase64": data.base64EncodedString()]

    // Optional: guard session state before sending
    guard WCSession.isSupported() else { print("iOS: WCSession not supported"); return }
    let session = WCSession.default
    // Tip: You can also check session.isPaired and session.isWatchAppInstalled if needed.

    do {
        try session.updateApplicationContext(payload)
        print("iOS: updateApplicationContext sent")
    } catch {
        print("iOS: updateApplicationContext error: \(error.localizedDescription)")
    }
}

// MARK: - ContentView (iOS companion UI)
struct ContentView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Text("No photo selected").foregroundColor(.gray)
            }

            Button("Select Photo") { showImagePicker = true }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage) { image in
                self.selectedImage = image
                sendImageAsBase64(image) // auto-send when picked
            }
        }
        .onAppear {
            if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = WCSessionDelegateHandler.shared
                session.activate()
            }
        }
    }
}

