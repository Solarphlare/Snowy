import SwiftUI

@main
struct LaunchpadApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @ObservedObject var delegateStateBridge = DelegateStateBridge(isRegisteredWithAPNS: UIApplication.shared.isRegisteredForRemoteNotifications)
    @Environment(\.scenePhase) var scenePhase
    @StateObject var historyStore = NotificationHistoryStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyStore)
                .environmentObject(delegateStateBridge)
                .onAppear {
                    appDelegate.delegateStateBridge = delegateStateBridge
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        withAnimation {
                            delegateStateBridge.isRegisteredWithAPNS = UIApplication.shared.isRegisteredForRemoteNotifications
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var delegateStateBridge: DelegateStateBridge?
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenAsHex = deviceToken.map { String(format: "%02x", $0) }.joined()
        
        // Don't update anything if the new token is the same as the old one
        if let previousToken = UserDefaults.standard.string(forKey: "apns_token") {
            if previousToken == tokenAsHex { return }
        }
        
        Task {
            do {
                try await updateRemoteToken(token: tokenAsHex)
                NSLog("Successfully updated APNs token.")
            }
            catch {
                NSLog(error.localizedDescription)
                return
            }
        }
        
        NSLog("Successfully registered with APNS")
        NSLog("Got token: \(tokenAsHex)")
        UserDefaults.standard.setValue(tokenAsHex, forKey: "apns_token")
        UserDefaults.standard.setValue(Date.now.timeIntervalSince1970, forKey: "last_registered")
        delegateStateBridge?.didRegistrationSucceed = true
        withAnimation {
            delegateStateBridge?.isRegisteredWithAPNS = true
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Failed to register with APNS")
        NSLog(error.localizedDescription)
        delegateStateBridge?.didRegistrationSucceed = false
    }
}
