import UserNotifications
import Foundation
import SwiftUI

#if os(macOS)
typealias ApplicationDelegate = NSApplicationDelegate
typealias ApplicationType = NSApplication
#else
typealias ApplicationDelegate = UIApplicationDelegate
typealias ApplicationType = UIApplication
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

class AppDelegate: NSObject, ApplicationDelegate, UNUserNotificationCenterDelegate {
    var delegateStateBridge: DelegateStateBridge?
    
    #if !os(macOS)
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let _ = UserDefaults.standard.string(forKey: "apns_token") {
            UIApplication.shared.registerForRemoteNotifications()
        }
        return true
    }
    #else
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let _ = UserDefaults.standard.string(forKey: "apns_token") {
            NSApplication.shared.registerForRemoteNotifications()
        }
    }
    #endif
    
    
    func application(_ application: ApplicationType, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("application(_:didRegisterForRemoteNotificationsWithDeviceToken:) called")
        UNUserNotificationCenter.current().delegate = self
        
        let openUrlAction = UNNotificationAction(identifier: "OPEN_URL", title: "Open Link", options: [.foreground])
        let urlCategory = UNNotificationCategory(identifier: "URL_NOTIFICATION", actions: [openUrlAction], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([urlCategory])
        
        let tokenAsHex = deviceToken.map { String(format: "%02x", $0) }.joined()
        NSLog("Got token: \(tokenAsHex)")
        
        // Don't update anything if the new token is the same as the old one
        if let previousToken = UserDefaults.standard.string(forKey: "apns_token") {
            if previousToken != tokenAsHex {
                UserDefaults.standard.setValue(tokenAsHex, forKey: "apns_token")
                UserDefaults.standard.setValue(Date.now.timeIntervalSince1970, forKey: "last_registered")
            }
        }
        
        NSLog("Successfully registered with APNs.")
        
        Task {
            do {
                NSLog("Submitting token to server...")
                try await updateRemoteToken(token: tokenAsHex)
                NSLog("Successfully updated APNs token.")
            }
            catch {
                NSLog(error.localizedDescription)
                return
            }
        }

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
