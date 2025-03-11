import Foundation

struct UserProfile: Codable {
    var name: String
    var age: Int?
    var height: Double?
    var weight: Double?
    var goals: [Goal]
    var badges: [Badge]
    var preferredActivityTypes: [Activity.ActivityType]
    var notificationsEnabled: Bool
    var reminderTime: Date?
    var weeklyReportEnabled: Bool
    var weekStartsOnMonday: Bool = true  // デフォルトは月曜始まり
    
    var homeCircleTypes: [CircleType]  // 表示する円のタイプの順序
        
        enum CircleType: String, Codable, CaseIterable {
            case overall = "全体の進捗"
            case steps = "歩数"
            case distance = "歩行距離"
            case squats = "スクワット"
            case pushups = "腕立て"
            case situps = "腹筋"
            case running = "ランニング"
            case cycling = "サイクリング"
            case swimming = "水泳"
            case weightTraining = "筋トレ"
            case yoga = "ヨガ"
            
            func activityType() -> Activity.ActivityType? {
                switch self {
                case .overall: return nil
                case .steps: return .walking
                case .distance: return .walking
                case .squats: return .squats
                case .pushups: return .pushups
                case .situps: return .situps
                case .running: return .running
                case .cycling: return .cycling
                case .swimming: return .swimming
                case .weightTraining: return .weightTraining
                case .yoga: return .yoga
                }
            }
        }
}
