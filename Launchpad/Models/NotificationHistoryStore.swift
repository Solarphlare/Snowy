import Foundation

class NotificationHistoryStore: ObservableObject {
    @Published var history: [NotificationMetadata] = []
    static func getFileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("history.json", conformingTo: .json)
    }
    
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
