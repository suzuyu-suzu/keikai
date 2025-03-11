import Foundation

struct Badge: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var iconName: String // SFSymbolの名前
    var isAchieved: Bool
    var achievedDate: Date?
    var requiredValue: Int
    var activityType: Activity.ActivityType
}
