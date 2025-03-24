import SwiftUI

struct NotificationMetadataView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var notification: NotificationMetadata
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Metadata")) {
                    LabeledContent {
                        Text(notification.topic)
                    } label: {
                        Text("Topic")
                    }
                    LabeledContent {
                            Text(notification.posted.formatted(
                                date: .numeric,
                                time: .omitted
                            )) + Text(" ") +
                            Text(notification.posted.formatted(
                                date: .omitted,
                                time: .shortened
                            ))
                    } label: {
                        Text("Creation Time")
                    }
                    if let category = notification.category {
                        LabeledContent {
                            Text(category)
                        } label: {
                            Text("Category")
                        }
                    }
                    if horizontalSizeClass == .compact {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Identifier")
                            Text(notification.id.map { "\($0)\u{200b}" }.joined() )
                                .foregroundStyle(.gray)
                        }
                    }
                    else {
                        LabeledContent {
                            Text(notification.id.map { "\($0)\u{200b}" }.joined() )
                        } label: {
                            Text("Identifier")
                        }
                    }
                }
                Section(header: Text("Payload")) {
                    LabeledContent {
                        Text(notification.payload.title)
                    } label: {
                        Text("Title")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Message")
                        Text(notification.payload.body)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("Notification Details")
            .formStyle(.grouped)
            #if targetEnvironment(macCatalyst) || os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    NotificationMetadataView(notification: NotificationMetadata.sampleData[2])
}
