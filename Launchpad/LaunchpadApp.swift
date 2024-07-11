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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var delegateStateBridge: DelegateStateBridge?
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UNUserNotificationCenter.current().delegate = self
        
        let openUrlAction = UNNotificationAction(identifier: "OPEN_URL", title: "Open Link", options: [.foreground])
        let urlCategory = UNNotificationCategory(identifier: "URL_NOTIFICATION", actions: [openUrlAction], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([urlCategory])
        
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        NSLog("didRecieve called with action identifier: \(response.actionIdentifier)")
        
        if ([UNNotificationDefaultActionIdentifier, "OPEN_URL"].contains(response.actionIdentifier)) {
            guard let launchUrl = response.notification.request.content.userInfo["launch_url"] as? String else {
                return
            }
            
            NSLog("Got launch URL: \(launchUrl)")
            
            await UIApplication.shared.open(URL(string: launchUrl)!)
        }
    }
}
