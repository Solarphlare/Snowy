import Foundation
import UIKit

#if targetEnvironment(simulator)
let deviceType = "simulator"
#elseif targetEnvironment(macCatalyst) || os(macOS)
let deviceType = "mac"
#else
let deviceType = UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : "ipad"
#endif

/// Update the APNs token for the device with a newly-generated one. This function should be run every time the app launches.
/// - Parameter token: The newly-generated token to use.
/// - Throws `RequestError.failed` if the request fails for any reason.
func updateRemoteToken(token: String) async throws -> Void {
    var request = URLRequest(url: URL(string: "\(HISTORY_ENDPOINT_DOMAIN)/apns/update-token")!)
    request.httpMethod = "PATCH"
    request.setValue("Token \(HISTORY_AUTH_TOKEN)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try! JSONEncoder().encode(["target": deviceType, "token": token])
    
    let (_, responseData) = try await URLSession.shared.data(for: request)
    let response = responseData as! HTTPURLResponse
    
    if response.statusCode != 204 {
        NSLog("\(response.statusCode)")
        throw RequestError.failed
    }
}
