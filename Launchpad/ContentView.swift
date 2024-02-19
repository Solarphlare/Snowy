import SwiftUI
import PushKit

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
                        VStack(alignment: .trailing) {
                            Text(delegateStateBridge.isRegisteredWithAPNS ? "Registered" : "Unregistered")
                        }
                    } label: {
                        Text("APNs State")
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
                    Button(action: {
                        let center = UNUserNotificationCenter.current()
                        Task {
                            do {
                                try await center.requestAuthorization(options: [.alert, .sound, .badge])
                                let settings = await center.notificationSettings()
                                
                                if (settings.authorizationStatus == .authorized) {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                                else {
                                    isNotificationPermissionAlertPresented = true
                                }
                            }
                           catch {
                               NSLog("Failed to request notification permission")
                           }
                        }
                    }) {
                        Text(delegateStateBridge.isRegisteredWithAPNS ? "Re-register with APNs" : "Request APNs Registration")
                    }
                } header: {
                    Text("APNs")
                } footer: {
                    if (delegateStateBridge.isRegisteredWithAPNS) {
                        Text("Re-register with APNs, receiving a new token in the process. Use this only if notifications aren't being received by your device.")
                    }
                }
                Section {
                    ShareLink(item: UserDefaults.standard.string(forKey: "apns_token") ?? "No value provided") {
                        Text("Export APNs Token")
                    }
                    .disabled(!delegateStateBridge.isRegisteredWithAPNS)
                } header: {
                    Text("Token")
                } footer: {
                    Text("The APNs token can be used to send notifications to your device. Make sure to keep it a secret.")
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
            .navigationTitle("Launchpad")
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
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
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
                
                if (!hasRunInitBefore && UIApplication.shared.isRegisteredForRemoteNotifications) {
                    NSLog("Running init block")
                    UIApplication.shared.registerForRemoteNotifications()
                    
                    hasRunInitBefore = true
                }
                
                Task {
                    timer?.invalidate()
                    timer = nil
                    
                    try? await historyStore.load()
                    
                    let isHistoryStreEmpty = historyStore.history.isEmpty
                    let after = isHistoryStreEmpty ? nil : historyStore.history[0].posted
                    let history = try? await fetchNotificationHistory(after: nil)
                    guard let history else {
                        DispatchQueue.main.async {
                            if (isHistoryStreEmpty) {
                                notificationHistorySubtext = "Unable to get notification history"
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
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NotificationHistoryStore())
        .environmentObject(DelegateStateBridge(isRegisteredWithAPNS: false))
        .onAppear {
            UserDefaults.standard.setValue(15700000, forKey: "last_registered")
        }
}
