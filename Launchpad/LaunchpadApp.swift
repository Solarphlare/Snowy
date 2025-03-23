import Foundation
import UserNotifications
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if os(macOS)
typealias ApplicationDelegate = NSApplicationDelegate
typealias ApplicationType = NSApplication
#else
typealias ApplicationDelegate = UIApplicationDelegate
typealias ApplicationType = UIApplication
#endif

@main
struct LaunchpadApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #else
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    @ObservedObject var delegateStateBridge = DelegateStateBridge(isRegisteredWithAPNS: ApplicationType.shared.isRegisteredForRemoteNotifications)
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
                            delegateStateBridge.isRegisteredWithAPNS = ApplicationType.shared.isRegisteredForRemoteNotifications
                        }
                    }
                }
        }
    }
}

class AppDelegate: NSObject, ApplicationDelegate, UNUserNotificationCenterDelegate {
    var delegateStateBridge: DelegateStateBridge?
    
    func application(_ application: ApplicationType, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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
    
    func application(_ application: ApplicationType, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Failed to register with APNS")
        NSLog(String(describing: error))
        delegateStateBridge?.didRegistrationSucceed = false
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        NSLog("didRecieve called with action identifier: \(response.actionIdentifier)")
        let userInfo = response.notification.request.content.userInfo
        let aps = userInfo["aps"] as! [String : Any]
        
        if ([UNNotificationDefaultActionIdentifier, "OPEN_URL"].contains(response.actionIdentifier) && aps["category"] as? String == "URL_NOTIFICATION") {
            guard let launchUrl = response.notification.request.content.userInfo["launch_url"] as? String else {
                return
            }
            
            NSLog("Got launch URL: \(launchUrl)")
            
            #if os(macOS)
            NSWorkspace().open(URL(string: launchUrl)!)
            #else
            await UIApplication.shared.open(URL(string: launchUrl)!)
            #endif
        }
    }
}
