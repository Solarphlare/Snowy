import Foundation
import UserNotifications
import SwiftUI

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
