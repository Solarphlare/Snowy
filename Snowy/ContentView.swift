import SwiftUI
import PushKit
import UserNotifications

struct ContentView: View {
    @AppStorage("last_registered") var lastRegistered: Double?
    @EnvironmentObject var delegateStateBridge: DelegateStateBridge
    @EnvironmentObject var historyStore: NotificationHistoryStore
    @State private var isAlertPresented = false
    @State private var isNotificationPermissionAlertPresented = false
    @State private var notificationHistorySubtext: String?
    @State private var attemptedFetch = false
    @State private var timer: Timer?
    @State private var hasRunInitBefore = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent {
                        HStack {
                            #if os(macOS)
                            Button(action: {
                                Task { await registrationButtonAction() }
                            }) {
                                Text(delegateStateBridge.isRegisteredWithAPNS ? "Re-register with APNs" : "Request APNs Registration")
                            }
                            #else
                            Text(delegateStateBridge.isRegisteredWithAPNS ? "Registered" : "Unregistered")
                            #endif
                        }
                    } label: {
                        Text("APNs Registration")
                        #if os(macOS)
                        if (delegateStateBridge.isRegisteredWithAPNS) {
                            Text("Re-register with APNs to receiving a new token. Use this only if notifications aren't being received by your device.")
                        }
                        #endif
                    }
                    if let lastRegistered {
                        if delegateStateBridge.isRegisteredWithAPNS {
                            LabeledContent {
                                HStack(spacing: 4) {
                                    Text(Date(timeIntervalSince1970: lastRegistered).formatted(date: .numeric, time: .omitted))
                                    Text(Date(timeIntervalSince1970: lastRegistered).formatted(date: .omitted, time: .shortened))
                                }
                            } label: {
                                Text("Registration Date")
                            }
                        }
                    }
                    #if os(iOS)
                    Button(action: {
                        Task { await registrationButtonAction() }
                    }) {
                        Text(delegateStateBridge.isRegisteredWithAPNS ? "Re-register with APNs" : "Request APNs Registration")
                    }
                    #endif
                } header: {
                    Text("APNs")
                } footer: {
                    #if os(iOS)
                    if (delegateStateBridge.isRegisteredWithAPNS) {
                        Text("Re-register with APNs, receiving a new token in the process. Use this only if notifications aren't being received by your device.")
                    }
                    #endif
                }
                Section {
                    LabeledContent {
                        ShareLink(item: UserDefaults.standard.string(forKey: "apns_token") ?? "No value provided") {
                            Text("Export APNs Token")
                        }
                        .disabled(!delegateStateBridge.isRegisteredWithAPNS)
                    } label: {
                        #if os(macOS)
                        Text("Export APNs Token")
                        Text("The APNs token can be used to send notifications to your device. Make sure to keep it a secret.")
                        #endif
                    }
                } header: {
                    Text("Token")
                } footer: {
                    #if os(iOS)
                    Text("The APNs token can be used to send notifications to your device. Make sure to keep it a secret.")
                    #endif
                }
                Section {
                    if attemptedFetch {
                        NavigationLink(destination: NotificationHistoryView()) {
                            VStack(alignment: .leading) {
                                Text("Notification History")
                                if let notificationHistorySubtext {
                                    Text(notificationHistorySubtext)
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                }
                            }
                        }
                        .disabled(historyStore.history.isEmpty)
                    }
                    else {
                        HStack {
                            Text("Notification History")
                            Spacer()
                            ProgressView()
                        }
                    }
                } header: { Text("Notifications") }
            }
            .formStyle(.grouped)
            .navigationTitle("Snowy")
            .onChange(of: delegateStateBridge.didRegistrationSucceed) { _, newValue in
                NSLog("onChange listener notified of change, got value of \(newValue?.description ?? "nil")")
                isAlertPresented = newValue == false
            }
            .alert(isPresented: $isAlertPresented) {
                Alert(title: Text("Failed to Register with APNs"), message: Text("An error occured while trying to register with APNs. Give it another shot, or try again later."))
            }
            .alert(isPresented: $isNotificationPermissionAlertPresented) {
                Alert(
                    title: Text("Notifications Disabled"),
                    message: Text("We can't register with APNs until you grant the notification permission in Settings. Please enable the permission in order to continue."),
                    primaryButton: .default(Text("Open Settings")) {
                        #if os(macOS)
                        NSWorkspace().open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
                        #else
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        #endif
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                loadStore()
            }
        }
    }
}

struct ContentView_macOS_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationHistoryStore())
            .environmentObject(DelegateStateBridge(isRegisteredWithAPNS: false))
            .onAppear {
                UserDefaults.standard.setValue(15700000, forKey: "last_registered")
            }
            .previewDevice("My Mac")
    }
}

struct ContentView_iPhone_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationHistoryStore())
            .environmentObject(DelegateStateBridge(isRegisteredWithAPNS: false))
            .onAppear {
                UserDefaults.standard.setValue(15700000, forKey: "last_registered")
            }
            .previewDevice("iPhone 16 Pro")
    }
}

extension ContentView {
    func loadStore() {
        if (ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    historyStore.history = NotificationMetadata.sampleData
                    let relativeFormatter = RelativeDateTimeFormatter()
                    notificationHistorySubtext = "Last notification posted \(relativeFormatter.localizedString(for: historyStore.history[0].posted, relativeTo: .now))"
                    
                    attemptedFetch = true
                }
            }
            
            return
        }
        
        if (!hasRunInitBefore && ApplicationType.shared.isRegisteredForRemoteNotifications) {
            NSLog("Running init block")
            ApplicationType.shared.registerForRemoteNotifications()
            
            hasRunInitBefore = true
        }
        
        Task {
            timer?.invalidate()
            timer = nil
            
            try? await historyStore.load()
            
            let isHistoryStreEmpty = historyStore.history.isEmpty
//                    let after = isHistoryStreEmpty ? nil : historyStore.history[0].posted
            let history = try? await fetchNotificationHistory(after: nil)
            guard let history else {
                DispatchQueue.main.async {
                    if (isHistoryStreEmpty) {
                        notificationHistorySubtext = "No notifications posted yet"
                    }
                    else {
                        notificationHistorySubtext = "Last known notification posted \(RelativeDateTimeFormatter().localizedString(for: historyStore.history[0].posted, relativeTo: .now))"
                    }
                    withAnimation {
                        attemptedFetch = true
                    }
                }
                return
            }
            
            if history.isEmpty && historyStore.history.isEmpty {
                notificationHistorySubtext = "No notifications posted yet"
            }
            else {
                notificationHistorySubtext = "Last notification posted \(RelativeDateTimeFormatter().localizedString(for: history[0].posted, relativeTo: .now))"
                
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    DispatchQueue.main.async {
                        let relativeFormatter = RelativeDateTimeFormatter()
                        notificationHistorySubtext = "Last notification posted \(relativeFormatter.localizedString(for: history[0].posted, relativeTo: .now))"
                    }
                }
            }
            
            withAnimation {
                attemptedFetch = true
                historyStore.history = history
            }
            
            historyStore.write()
        }
    }
    
    func registrationButtonAction() async {
        NSLog("APNs registration requested by user")
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
            let settings = await center.notificationSettings()
            
            if (settings.authorizationStatus == .authorized) {
                NSLog("Registering for remote notifications...")
                ApplicationType.shared.registerForRemoteNotifications()
            }
            else {
                NSLog("Failed to register for remote notifications as user did not grant notification permissions")
                isNotificationPermissionAlertPresented = true
            }
        }
       catch {
           NSLog("Failed to request notification permission")
       }
    }
}
