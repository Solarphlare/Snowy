import Foundation

/// A class that groups NotificationMetadata objects with the same month together.
struct NotificationMetadataGroup: Identifiable {
    /// The calendar date of all the NotificationMetadata objects in this group.
    let date: Date
    /// The NotificationMetadata objects in this group.
    var notifications: [NotificationMetadata]
    /// The ID of this object.
    let id = UUID()
    
    /// Creates a NotificationMetadataGroup object, using the provided notification as the first element in the group.
    /// - Parameter notification: The first element of the group.
    init(_ notification: NotificationMetadata) {
        self.date = notification.posted
        self.notifications = [notification]
    }
}

/// Sorts an array of NotificationMetadata objects, and returns them in sub-arrays, grouped by month.
/// - Parameter array: The array to sort.
/// - Returns: An array of NotificationMetadata sub-arrays, each grouped by month.
func sortNotificationMetadataArray(_ array: [NotificationMetadata]) -> [NotificationMetadataGroup] {
    var result: [NotificationMetadataGroup] = []
    
    array.forEach { i in
        if result.isEmpty {
            result.append(NotificationMetadataGroup(i))
            return
        }
        
        let groupComponents = Calendar.current.dateComponents([.month, .year], from: result.last!.date)
        let notificationComponents = Calendar.current.dateComponents([.month, .year], from: i.posted)
        
        if (groupComponents.month == notificationComponents.month && groupComponents.year == notificationComponents.year) {
            result[result.count - 1].notifications.append(i)
        }
        else {
            result.append(NotificationMetadataGroup(i))
        }
    }
    
    return result
}
