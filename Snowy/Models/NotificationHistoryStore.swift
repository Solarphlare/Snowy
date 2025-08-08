import Foundation

/// A class for saving a local cache of the Notification History to disk.
class NotificationHistoryStore: ObservableObject {
    @Published var history: [NotificationMetadata] = []
    
    /// Gets the URL for the cache file.
    /// - Returns: The URL for the cache file.
    static func getFileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("history.json", conformingTo: .json)
    }
    
    /// Reads the cached notification history from the file returned from `getFileURL()`, and stores it in `history`.
    /// - Throws: Throws an error if the function is unable to get the file URL, unable to read the file, or unable to parse the file.
    func load() async throws {
        let task = Task<[NotificationMetadata], Error> {
            let fileURL = try Self.getFileURL()
            let data = try Data(contentsOf: fileURL)
            let history = try JSONDecoder().decode([NotificationMetadata].self, from: data)
            NSLog("Retrieved %d history items from notification history store", history.count)
            
            return history
        }
        
        let history = try await task.value
        await MainActor.run {
            self.history = history
        }
    }
    
    /// Writes the contents of `history` to the file returned from `getFileURL()`.
    func write() {
        Task {
            do {
                let data = try JSONEncoder().encode(history)
                let outFile = try Self.getFileURL()
                try data.write(to: outFile)
                
                NSLog("Wrote %d history items to notification history store", history.count)
            }
            catch {
                NSLog(error.localizedDescription)
            }
        }
    }
}
