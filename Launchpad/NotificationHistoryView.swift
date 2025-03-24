import SwiftUI

struct NotificationHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery = ""
    @EnvironmentObject var historyStore: NotificationHistoryStore
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if searchResults.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView.search
                }
                else if !searchResults.isEmpty {
                    ForEach(searchResults) { group in
                        Section {
                            ForEach(group.notifications) { notification in
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
                                        .foregroundStyle(.gray)
                                    }
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
            .navigationTitle("Notification History")
            #if targetEnvironment(macCatalyst) || os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchQuery)
            .formStyle(.grouped)
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
}

#Preview {
    NotificationHistoryView()
        .environmentObject({
            let store = NotificationHistoryStore()
            store.history = NotificationMetadata.sampleData
            return store
        }())
}
