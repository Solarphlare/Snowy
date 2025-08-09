import SwiftUI

struct NotificationHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var searchQuery = ""
    @State private var selection: NotificationMetadata? = nil
    @EnvironmentObject var historyStore: NotificationHistoryStore
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df
    }
    
    var body: some View {
        if horizontalSizeClass == .compact {
            NotificationList()
                .navigationTitle("Notification History")
                #if targetEnvironment(macCatalyst) || os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .searchable(text: $searchQuery)
        }
        else {
            NavigationSplitView {
                NotificationList()
                    .toolbar {
                        ToolbarItem(placement: .navigation) {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                            }
                        }
                    }
            } detail: {
                if let selection {
                    NotificationMetadataView(notification: selection)
                }
                else {
                    Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
                }
            }
            .searchable(text: $searchQuery)
            .navigationBarBackButtonHidden()
            .onAppear {
                selection = searchResults.first?.notifications.first
            }
        }
    }
    
    var searchResults: [NotificationMetadataGroup] {
        if searchQuery.isEmpty {
            return sortNotificationMetadataArray(historyStore.history)
        }
        else {
            return sortNotificationMetadataArray(historyStore.history.filter { $0.topic.lowercased().contains(searchQuery.lowercased()) })
        }
    }
    
    @ViewBuilder
    func NotificationList() -> some View {
        List(selection: $selection) {
            if searchResults.isEmpty && !searchQuery.isEmpty {
                ContentUnavailableView.search
            }
            else if !searchResults.isEmpty {
                ForEach(searchResults) { group in
                    Section {
                        ForEach(group.notifications) { notification in
                            if horizontalSizeClass == .compact {
                                NavigationLink(destination: NotificationMetadataView(notification: notification)) {
                                    VStack(alignment: .leading) {
                                        Text(notification.topic)
                                        HStack(spacing: 4) {
                                            Text(notification.posted.formatted(
                                                date: .abbreviated,
                                                time: .omitted
                                            ))
                                            Text(notification.posted.formatted(
                                                date: .omitted,
                                                time: .shortened
                                            ))
                                        }
                                        .font(.caption)
                                        .opacity(0.4)
                                    }
                                }
                            }
                            else {
                                VStack(alignment: .leading) {
                                    Text(notification.topic)
                                    HStack(spacing: 4) {
                                        Text(notification.posted.formatted(
                                            date: .abbreviated,
                                            time: .omitted
                                        ))
                                        Text(notification.posted.formatted(
                                            date: .omitted,
                                            time: .shortened
                                        ))
                                    }
                                    .font(.caption)
                                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                                }
                                .tag(notification)
                            }
                        }
                    } header: {
                        Text(dateFormatter.string(from: group.date))
                    }
                }
            }
            else {
                // This should NEVER occur, but exists just in case
                VStack(alignment: .center, spacing: 6) {
                    Image(systemName: "bell.badge.slash.fill")
                        .font(.system(size: 48))
                        .padding(.bottom, 8)
                        .opacity(0.5)
                    Text("No Notifications")
                        .fontWeight(.bold)
                        .font(.title)
                    Text("No notifications have been posted yet.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .opacity(0.5)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    if UIDevice.current.userInterfaceIdiom == .phone {
        NavigationStack {
            NotificationHistoryView()
                .environmentObject({
                    let store = NotificationHistoryStore()
                    store.history = NotificationMetadata.sampleData
                    return store
                }())
        }
    }
    else {
        NotificationHistoryView()
            .environmentObject({
                let store = NotificationHistoryStore()
                store.history = NotificationMetadata.sampleData
                return store
            }())
    }
}
