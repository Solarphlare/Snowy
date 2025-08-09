import Foundation

struct NotificationPayload: Codable, Hashable {
    let title: String
    let body: String
}

struct NotificationMetadata: Identifiable, Codable, Hashable, Equatable {
    let topic: String
    let posted: Date
    let category: String?
    let id: String
    let payload: NotificationPayload
    
    enum CodingKeys: String, CodingKey {
        case topic, posted, category, id, payload
    }
    
    private init(topic: String, posted: Date, category: String?, id: String, payload: NotificationPayload) {
        self.topic = topic
        self.posted = posted
        self.category = category
        self.id = id
        self.payload = payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topic = try container.decode(String.self, forKey: .topic)
        self.id = try container.decode(String.self, forKey: .id)
        self.category = try container.decodeIfPresent(String.self, forKey: .category)
        self.payload = try container.decode(NotificationPayload.self, forKey: .payload)

        let postedString = try container.decode(Double.self, forKey: .posted)
        self.posted = Date(timeIntervalSince1970: postedString)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.topic, forKey: .topic)
        try container.encode(self.posted.timeIntervalSince1970, forKey: .posted)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.payload, forKey: .payload)
    }
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    static let sampleData = [
        NotificationMetadata(
            topic: "Server Maintenance",
            posted: Date(timeIntervalSince1970: 1707061300),
            category: nil,
            id: "24efe19f-d86d-443f-a208-e8ae21292dfb",
            payload: NotificationPayload(
                title: "Server Update Complete",
                body: "debian-aws-useast2 has successfully been upgraded to kernel 6.2."
            )
        ),
        NotificationMetadata(
            topic: "Parcel Update",
            posted: Date(timeIntervalSince1970: 1706950300),
            category: nil,
            id: "24efe19f-d86d-443f-a608-e8ae21292dfc",
            payload: NotificationPayload(
                title: "Parcel Received",
                body: "A parcel is available for pickup at the front desk."
            )
        ),
        NotificationMetadata(
            topic: "Server Status",
            posted: Date(timeIntervalSince1970: 1706640100),
            category: "URL_NOTIFICATION",
            id: "19efe19f-d86d-443f-a608-e8ae21292dfc",
            payload: NotificationPayload(
                title: "Server Offline",
                body: "debian-aws-useast2 has not been responsive for 5 minutes."
            )
        )
    ]
}
