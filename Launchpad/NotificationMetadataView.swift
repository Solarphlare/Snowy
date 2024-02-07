import SwiftUI

struct NotificationMetadataView: View {
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
                        HStack(spacing: 4) {
                            Text(notification.posted.formatted(
                                date: .numeric,
                                time: .omitted
                            ))
                            Text(notification.posted.formatted(
                                date: .omitted,
                                time: .shortened
                            ))
                        }
                    } label: {
                        Text("Creation Time")
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Identifier")
                        Text(notification.id.map { "\($0)\u{200b}"}.joined() )
                            .font(.system(size: 17))
                            .foregroundStyle(.gray)
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
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    NotificationMetadataView(notification: NotificationMetadata.sampleData[1])
}
