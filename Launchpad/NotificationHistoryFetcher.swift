import Foundation
import Alamofire
import UIKit

enum RequestError: Error {
    case failed
}

func fetchNotificationHistory(after: Double?) async throws -> Data {
    let device = await UIDevice.current.userInterfaceIdiom == .phone ? "iphone" : "ipad"

    let request = AF.request("\(HISTORY_ENDPOINT_DOMAIN)/notifications/history?device=\(device)\(after != nil ? String(format: "&after=%.0f", after!) : "")", headers: ["Authorization": "Token \(HISTORY_AUTH_TOKEN)"])
    let response = await request.serializingString().response
    
    if let error = response.error {
        NSLog(error.localizedDescription)
        throw RequestError.failed
    }
    
    guard let serverResponse = response.response else { throw RequestError.failed }
    
    if (serverResponse.statusCode != 200) {
        throw RequestError.failed
    }
    
    guard let responseData = response.data else { throw RequestError.failed }
    
    return responseData
}
