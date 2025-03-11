import Foundation

struct Goal: Identifiable, Codable {
    var id = UUID()
    var activityType: Activity.ActivityType
    var weeklyTarget: Int
    var unit: String // 回数、分、km など
    var startDate: Date
}
