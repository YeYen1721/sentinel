//
//  SentinelApp.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct SentinelApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - App Delegate for Firebase Configuration

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configure Firebase with error handling
        do {
            // Check if GoogleService-Info.plist exists and is valid
            if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
               let plistData = FileManager.default.contents(atPath: path),
               let plist = try PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
               let googleAppId = plist["GOOGLE_APP_ID"] as? String,
               let apiKey = plist["API_KEY"] as? String,
               let projectId = plist["PROJECT_ID"] as? String {

                // Check if this is a valid production config (not demo/template)
                let isDemoConfig = googleAppId.contains("YOUR_") ||
                                   googleAppId.contains("DEMO") ||
                                   apiKey.contains("DEMO") ||
                                   apiKey.contains("YOUR_") ||
                                   projectId.contains("demo") ||
                                   projectId.contains("template")

                if !isDemoConfig {
                    // Valid production configuration found
                    FirebaseApp.configure()

                    // Configure Firestore settings
                    let db = Firestore.firestore()
                    let settings = FirestoreSettings()
                    settings.cacheSettings = MemoryCacheSettings()
                    db.settings = settings

                    print("✅ Firebase initialized successfully")
                } else {
                    print("⚠️ Running in DEMO mode - Firebase not configured")
                    print("ℹ️  Detected demo/template credentials in GoogleService-Info.plist")
                    print("ℹ️  The app will use local data only")
                    print("ℹ️  To enable Firebase:")
                    print("   1. Create a Firebase project at https://console.firebase.google.com")
                    print("   2. Download GoogleService-Info.plist from Firebase Console")
                    print("   3. Replace the existing file in your project")
                }
            } else {
                print("⚠️ Running in DEMO mode - Firebase not configured")
                print("ℹ️  The app will use local data only")
                print("ℹ️  To enable Firebase: Add a valid GoogleService-Info.plist")
            }
        } catch {
            print("⚠️ Firebase configuration error: \(error.localizedDescription)")
            print("ℹ️  Running in DEMO mode with local data")
        }

        return true
    }
}
