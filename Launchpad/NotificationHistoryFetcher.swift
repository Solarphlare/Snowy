import Foundation
import UIKit

enum RequestError: Error {
    case failed
}

func fetchNotificationHistory(after: Double?) async throws -> Data {
    let device = await UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : "ipad"
    
    var request = URLRequest(url: URL(string: "\(HISTORY_ENDPOINT_DOMAIN)/notifications/history?device=\(device)\(after != nil ? String(format: "&after=%.0f", after!) : "")")!)
    
    request.setValue("Token \(HISTORY_AUTH_TOKEN)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    let httpResponse = response as! HTTPURLResponse
    
    if (httpResponse.statusCode != 200) {
        throw RequestError.failed
    }
    
    return data
}
