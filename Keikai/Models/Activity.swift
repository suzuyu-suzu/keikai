import Foundation

struct Activity: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: ActivityType
    var count: Int
    var distance: Double?
    var duration: Int? // 分単位（オプション）
    var caloriesBurned: Int?
    var date: Date
    var notes: String?
    var fromHealthKit: Bool = false  // HealthKitからのデータかどうか
    
    enum ActivityType: String, Codable, CaseIterable {
        case walking = "ウォーキング"
        case running = "ランニング"
        case cycling = "サイクリング"
        case swimming = "水泳"
        case squats = "スクワット"
        case pushups = "腕立て伏せ"
        case situps = "腹筋"
        case weightTraining = "筋トレ"
        case yoga = "ヨガ"
        case other = "その他"
    }
}
