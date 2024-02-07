import Foundation
import Alamofire

enum RequestError: Error {
    case failed
}

func fetchNotificationHistory(after: Double?) async throws -> Data {
    let request = AF.request("http://\(HISTORY_ENDPOINT_DOMAIN)/notification-history\(after != nil ? "?after=\(after!)" : "")", headers: ["Authorization": "Token \(HISTORY_AUTH_TOKEN)"])
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
