import Foundation
import UIKit

enum RequestError: Error {
    case failed
}

/// Fetch the notification history for the device.
/// - Parameter after: Used to only return history entries after the specified date.
/// - Returns: An array of NotificationMetadata objects. The array will be empty if there isn't any notification history yet, or if there is no history after the Date specified in the `after` parameter.
func fetchNotificationHistory(after: Date?) async throws -> [NotificationMetadata] {
    #if targetEnvironment(simulator)
    let device = "simulator"
    #elseif targetEnvironment(macCatalyst) || os(macOS)
    let device = "mac"
    #else
    let device = await UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : "ipad"
    #endif
    
    
    var request = URLRequest(url: URL(string: "\(HISTORY_ENDPOINT_DOMAIN)/notifications/history?device=\(device)\(after != nil ? String(format: "&after=%.0f", after!.timeIntervalSince1970) : "")")!)
    
    request.setValue("Token \(HISTORY_AUTH_TOKEN)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    let httpResponse = response as! HTTPURLResponse
    
    if (httpResponse.statusCode != 200) {
        throw RequestError.failed
    }
    
    return try JSONDecoder().decode([NotificationMetadata].self, from: data)
}
