import Foundation
import SwiftUI
import Combine

class DataStore: ObservableObject {
    @Published var activities: [Activity] = []
    @Published var userProfile: UserProfile
    
    private let activitiesSaveKey = "SavedActivities"
    private let profileSaveKey = "UserProfile"
    
    init() {
        // デフォルトのユーザープロファイルを作成
        self.userProfile = UserProfile(
            name: "ユーザー",
            goals: [],
            badges: [
                Badge(name: "初めての記録", description: "最初のアクティビティを記録", iconName: "star.fill", isAchieved: false, requiredValue: 1, activityType: .walking),
                Badge(name: "ウォーキングマスター", description: "1週間で5万歩達成", iconName: "figure.walk", isAchieved: false, requiredValue: 50000, activityType: .walking),
                Badge(name: "スクワットチャレンジャー", description: "1日で100回のスクワット", iconName: "figure.strengthtraining.traditional", isAchieved: false, requiredValue: 100, activityType: .squats)
            ],
            preferredActivityTypes: [.walking, .running, .squats],
            notificationsEnabled: true,
            weeklyReportEnabled: true,
            weekStartsOnMonday: true,
            homeCircleTypes: [.distance, .steps, .overall, .squats]  // デフォルト順序
        )
        
        loadData()
        setupDefaultGoalsIfNeeded()
    }
    
    func addActivity(_ activity: Activity) {
        activities.append(activity)
        saveActivities()
        checkBadgeAchievements()
    }
    
    func updateActivity(_ activity: Activity) {
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
            saveActivities()
            checkBadgeAchievements()
        }
    }
    
    // DataStoreクラスに削除用のメソッドを追加
    func deleteActivity(id: UUID) {
        activities.removeAll { $0.id == id }
        saveActivities()
    }

    func deleteActivity(at indexSet: IndexSet) {
        activities.remove(atOffsets: indexSet)
        saveActivities()
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = userProfile.goals.firstIndex(where: { $0.id == goal.id }) {
            userProfile.goals[index] = goal
        } else {
            userProfile.goals.append(goal)
        }
        saveProfile()
    }
    
    func deleteGoal(_ goalID: UUID) {
        userProfile.goals.removeAll(where: { $0.id == goalID })
        saveProfile()
    }
    
    // MARK: - Private Methods
    
    private func loadData() {
        loadActivities()
        loadProfile()
    }
    
    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: activitiesSaveKey)
        }
    }
    
    private func loadActivities() {
        if let savedActivities = UserDefaults.standard.data(forKey: activitiesSaveKey) {
            if let decodedActivities = try? JSONDecoder().decode([Activity].self, from: savedActivities) {
                activities = decodedActivities
                return
            }
        }
        activities = []
    }
    
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(encoded, forKey: profileSaveKey)
        }
    }
    
    private func loadProfile() {
        if let savedProfile = UserDefaults.standard.data(forKey: profileSaveKey) {
            if let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: savedProfile) {
                userProfile = decodedProfile
                return
            }
        }
        // プロファイルが読み込めない場合は既存のままを使用
    }
    
    private func setupDefaultGoalsIfNeeded() {
        if userProfile.goals.isEmpty {
            // デフォルトの目標を設定
            let defaultGoals = [
                Goal(activityType: .walking, weeklyTarget: 70000, unit: "歩", startDate: Date()),
                Goal(activityType: .squats, weeklyTarget: 100, unit: "回", startDate: Date())
            ]
            
            userProfile.goals.append(contentsOf: defaultGoals)
            saveProfile()
        }
    }
    
    private func checkBadgeAchievements() {
        for (index, badge) in userProfile.badges.enumerated() {
            if !badge.isAchieved {
                // バッジの達成条件をチェック
                switch badge.name {
                case "初めての記録":
                    if !activities.isEmpty {
                        userProfile.badges[index].isAchieved = true
                        userProfile.badges[index].achievedDate = Date()
                    }
                    
                case "ウォーキングマスター":
                    let calendar = Calendar.current
                    let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
                    
                    let weeklyWalkingCount = activities
                        .filter { $0.type == .walking && $0.date >= oneWeekAgo }
                        .reduce(0) { $0 + $1.count }
                    
                    if weeklyWalkingCount >= 50000 {
                        userProfile.badges[index].isAchieved = true
                        userProfile.badges[index].achievedDate = Date()
                    }
                    
                case "スクワットチャレンジャー":
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    
                    let dailySquatCount = activities
                        .filter { $0.type == .squats && calendar.isDate($0.date, inSameDayAs: today) }
                        .reduce(0) { $0 + $1.count }
                    
                    if dailySquatCount >= 100 {
                        userProfile.badges[index].isAchieved = true
                        userProfile.badges[index].achievedDate = Date()
                    }
                    
                default:
                    break
                }
            }
        }
        
        saveProfile()
    }
    
    // MARK: - Computed Properties
    
    func weeklyActivitiesSummary() -> [Activity.ActivityType: Int] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        var summary: [Activity.ActivityType: Int] = [:]
        
        for activity in activities where activity.date >= oneWeekAgo {
            summary[activity.type, default: 0] += activity.count
        }
        
        return summary
    }
    
    func weeklyProgressForActivity(type: Activity.ActivityType) -> Double {
        let goal = userProfile.goals.first(where: { $0.activityType == type })
        let weeklySummary = weeklyActivitiesSummary()
        let achieved = weeklySummary[type] ?? 0
        
        guard let goal = goal else { return 0 }
        return min(Double(achieved) / Double(goal.weeklyTarget), 1.0)
    }
    
    func getActivitiesForDate(_ date: Date) -> [Activity] {
        let calendar = Calendar.current
        return activities.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    func getActivitiesForWeek(containing date: Date) -> [Activity] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        
        return activities.filter { $0.date >= weekStart && $0.date < weekEnd }
    }
    
    func getActivitiesForMonth(containing date: Date) -> [Activity] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return []
        }
        
        return activities.filter { $0.date >= monthStart && $0.date < monthEnd }
    }
    
    // 週の開始日を計算するヘルパーメソッド
    func getWeekStart(for date: Date = Date()) -> Date {
        var calendar = Calendar.current
        
        // 週の開始日を設定
        calendar.firstWeekday = userProfile.weekStartsOnMonday ? 2 : 1  // 2=月曜日、1=日曜日
        
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }
    
    // 週の終わりも取得できるようにする
    func getWeekEnd(for date: Date = Date()) -> Date {
        var calendar = Calendar.current
        
        // 週の開始日を設定
        calendar.firstWeekday = userProfile.weekStartsOnMonday ? 2 : 1  // 2=月曜日、1=日曜日
        
        let weekStart = getWeekStart(for: date)
        return calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date
    }
    // DataStore.swift に追加
    func calculateProgress(for goal: Goal, activityType: Activity.ActivityType) -> Double {
        let weekStart = getWeekStart()
        let weekEnd = getWeekEnd()
        
        let weekActivities = activities.filter {
            $0.type == activityType && $0.date >= weekStart && $0.date <= weekEnd
        }
        
        let achieved = weekActivities.reduce(0) { $0 + $1.count }
        return min(Double(achieved) / Double(goal.weeklyTarget), 1.0)
    }
    
}
