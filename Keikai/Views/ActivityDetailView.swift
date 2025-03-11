import SwiftUI


struct ActivityDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    let activityType: Activity.ActivityType
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case year = "年間"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 期間選択セグメント
                periodSelector
                
                // ヘッダー情報
                headerView
                
                // サマリー情報
                summaryView
                
                // 履歴
                historyView
            }
            .padding(.vertical)
        }
        .navigationTitle("アクティビティ詳細")
    }
    
    // 期間選択部分
    private var periodSelector: some View {
        Picker("期間", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // ヘッダー部分
    private var headerView: some View {
        HStack {
            Image(systemName: activityIcon(for: activityType))
                .font(.system(size: 40))
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(activityType.rawValue)
                    .font(.title)
                    .fontWeight(.bold)
                
                goalProgressView
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // 目標進捗表示部分
    private var goalProgressView: some View {
        Group {
            if let goal = dataStore.userProfile.goals.first(where: { $0.activityType == activityType }) {
                let progress = calculateProgress(for: goal)
                
                HStack {
                    Text("週間目標: \(goal.weeklyTarget) \(goal.unit)")
                    Spacer()
                    Text("\(Int(progress * 100))% 達成")
                        .foregroundColor(progress >= 1.0 ? .green : .primary)
                }
                .font(.subheadline)
            } else {
                Text("目標未設定")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // サマリー情報
    private var summaryView: some View {
        HStack(spacing: 20) {
            SummaryCard(
                title: "合計",
                value: "\(totalCount())",
                unit: unitFor(activityType),
                icon: "sum"
            )
            
            SummaryCard(
                title: "平均 / 日",
                value: String(format: "%.1f", averagePerDay()), // ここを修正
                unit: unitFor(activityType),
                icon: "chart.bar"
            )
            
            SummaryCard(
                title: "消費カロリー",
                value: "\(totalCalories())",
                unit: "kcal",
                icon: "flame"
            )
        }
        .padding(.horizontal)
    }
    
    // 履歴部分
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("履歴")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button("最新順", action: {})
                    Button("古い順", action: {})
                    Button("回数順", action: {})
                } label: {
                    Label("並び替え", systemImage: "arrow.up.arrow.down")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            // 履歴リスト
            activityHistoryList
        }
    }
    
    // 履歴リスト
    private var activityHistoryList: some View {
        Group {
            let activities = filteredActivities()
            
            if activities.isEmpty {
                Text("この期間の記録はありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(activities) { activity in
                    ActivityHistoryRow(activity: activity)
                }
            }
        }
    }
    
    private func activityIcon(for type: Activity.ActivityType) -> String {
        switch type {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .squats: return "figure.strengthtraining.traditional"
        case .pushups: return "figure.strengthtraining.functional"
        case .situps: return "figure.core.training"
        case .weightTraining: return "dumbbell"
        case .yoga: return "figure.mind.and.body"
        case .other: return "star"
        }
    }
    
    private func unitFor(_ type: Activity.ActivityType) -> String {
        switch type {
        case .walking, .running: return "歩"
        case .cycling, .swimming: return "m"
        case .squats, .pushups, .situps: return "回"
        case .weightTraining, .yoga: return "分"
        case .other: return ""
        }
    }
    
    private func filteredActivities() -> [Activity] {
        let calendar = Calendar.current
        let today = Date()
        
        let activities = dataStore.activities.filter { $0.type == activityType }
        
        switch selectedTimeRange {
        case .week:
            let weekStart = dataStore.getWeekStart()
            let weekEnd = dataStore.getWeekEnd()
            return activities.filter { $0.type == activityType && $0.date >= weekStart && $0.date <= weekEnd }
            
        case .month:
            let components = calendar.dateComponents([.year, .month], from: today)
            guard let monthStart = calendar.date(from: components) else {
                return []
            }
            return activities.filter { $0.date >= monthStart && $0.date <= today }
            
        case .year:
            let components = calendar.dateComponents([.year], from: today)
            guard let yearStart = calendar.date(from: components) else {
                return []
            }
            return activities.filter { $0.date >= yearStart && $0.date <= today }
        }
    }
    
    private func totalCount() -> Int {
        return filteredActivities().reduce(0) { $0 + $1.count }
    }
    
    private func totalCalories() -> Int {
        return filteredActivities().reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
    }
    
    private func averagePerDay() -> Double {
        let activities = filteredActivities()
        guard !activities.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let uniqueDays = Set(activities.map { calendar.startOfDay(for: $0.date) })
        
        let totalCount = activities.reduce(0) { $0 + $1.count }
        return uniqueDays.count > 0 ? Double(totalCount) / Double(uniqueDays.count) : 0
    }
    
    private func calculateProgress(for goal: Goal) -> Double {
        let weekStart = dataStore.getWeekStart()
            let weekEnd = dataStore.getWeekEnd()
            
            let weekActivities = dataStore.activities.filter {
                $0.type == activityType && $0.date >= weekStart && $0.date <= weekEnd
            }
            
            let achieved = weekActivities.reduce(0) { $0 + $1.count }
            return min(Double(achieved) / Double(goal.weeklyTarget), 1.0)
    }
}

// MARK: - サポートビュー

struct SummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

