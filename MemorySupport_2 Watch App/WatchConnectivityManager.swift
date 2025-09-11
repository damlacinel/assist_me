//
//  WatchConnectivityManager.swift
//  Memory Support
//
//  Created by Damla Cinel on 14.03.25.
//

import SwiftUI
import WatchConnectivity
import UIKit

// MARK: - WatchConnectivityManager (watchOS)
// >> Singleton class to manage data exchange with iOS via WCSession
final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var receivedImage: [UIImage] = []
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("Watch: WCSession activation error: \(error.localizedDescription)")
        } else {
            print("Watch: WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Watch: Received application context: \(applicationContext)")
        if let base64String = applicationContext["imageBase64"] as? String,
           let imageData = Data(base64Encoded: base64String),
           let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.receivedImage.append(image)
                print("Watch: Image successfully received and decoded from Base64!")
            }
        } else {
            print("Watch: Failed to decode image from Base64")
        }
    }
    
    // MARK: - Optional message handling
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch: Received message: \(message)")
    }
}
