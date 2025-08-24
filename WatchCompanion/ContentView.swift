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
class WCSessionDelegateHandler: NSObject, WCSessionDelegate {
    static let shared = WCSessionDelegateHandler()
    
    private override init() { super.init() }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("WCSession activation error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession did deactivate")
        WCSession.default.activate()
    }
    #endif
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message on iOS: \(message)")
    }
}

// MARK: - ImagePicker
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
                parent.onImagePicked(image)
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

// MARK: - Compression Function
func compressImage(_ image: UIImage, targetSize: CGSize, quality: CGFloat) -> Data? {
    // Görüntüyü yeniden boyutlandırıyoruz.
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    return resizedImage.jpegData(compressionQuality: quality)
}

// MARK: - Send Image as Base64 using updateApplicationContext
func sendImageAsBase64(_ image: UIImage) {
    // İstenen boyut ve kalite ile sıkıştırıyoruz.
    // Bu değeri, veri boyutunu uygun seviyeye düşürecek şekilde ayarlayın.
    guard let compressedData = compressImage(image, targetSize: CGSize(width: 100, height: 100), quality: 0.1) else {
        print("Failed to compress image")
        return
    }
    print("Compressed image data size: \(compressedData.count) bytes")
    let base64String = compressedData.base64EncodedString()
    let payload: [String: Any] = ["imageBase64": base64String]
    
    do {
        try WCSession.default.updateApplicationContext(payload)
        print("updateApplicationContext sent successfully")
    } catch {
        print("Error updating application context: \(error.localizedDescription)")
    }
}

// MARK: - ContentView (iOS Companion)
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
                Text("No photo selected")
                    .foregroundColor(.gray)
            }
            
            Button("Select Photo") {
                showImagePicker = true
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage) { image in
                self.selectedImage = image
                // Otomatik gönderim: Fotoğraf seçilir seçilmez, resmi Base64 string olarak gönder.
                sendImageAsBase64(image)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
