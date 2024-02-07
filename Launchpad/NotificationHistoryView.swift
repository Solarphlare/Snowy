//
//  NotificationHistoryView.swift
//  Launchpad
//
//  Created by William Martin on 2/4/24.
//

import SwiftUI

struct NotificationHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchQuery = ""
    @EnvironmentObject var historyStore: NotificationHistoryStore
    
    var body: some View {
        NavigationStack {
            Form {
                if searchResults.isEmpty {
                    ContentUnavailableView.search
                }
                else {
                    ForEach(searchResults) { notification in
                        NavigationLink(destination: NotificationMetadataView(notification: notification)) {
                            VStack(alignment: .leading) {
                                Text(notification.topic)
                                HStack(spacing: 4) {
                                    Text(notification.posted.formatted(
                                        date: .abbreviated,
                                        time: .omitted
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    
                                    Text(notification.posted.formatted(
                                        date: .omitted,
                                        time: .shortened
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notification History")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery)
        }
    }
    
    var searchResults: [NotificationMetadata] {
        if searchQuery.isEmpty {
            return historyStore.history
        }
        else {
            return historyStore.history.filter { $0.topic.lowercased().contains(searchQuery.lowercased()) }
        }
    }
}

#Preview {
    NotificationHistoryView()
        .environmentObject(NotificationHistoryStore())
}
