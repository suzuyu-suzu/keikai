import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedPeriod: Period = .week
    @State private var selectedActivityType: Activity.ActivityType?
    
    enum Period: String, CaseIterable {
        case week = "週間"
        case month = "月間"
        case year = "年間"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択セグメント
                    Picker("期間", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // アクティビティタイプ選択
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Activity.ActivityType.allCases, id: \.self) { type in
                                ActivityTypeButton(type: type, isSelected: selectedActivityType == type) {
                                    if selectedActivityType == type {
                                        selectedActivityType = nil
                                    } else {
                                        selectedActivityType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 統計グラフ
                    VStack(alignment: .leading, spacing: 10) {
                        Text("アクティビティの推移")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if #available(iOS 16.0, *) {
                           ActivityLineChart(period: selectedPeriod, activityType: selectedActivityType, dataStore: dataStore)
                                .frame(height: 250)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        } else {
                            Text("グラフ表示にはiOS 16以上が必要です")
                                .frame(height: 250)
                                .frame(maxWidth: .infinity)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    
                    // サマリー統計
                    VStack(alignment: .leading, spacing: 10) {
                        Text("統計サマリー")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        StatisticsSummaryView(period: selectedPeriod, activityType: selectedActivityType)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // 目標達成状況
                    if selectedActivityType == nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("目標達成状況")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            GoalProgressView()
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("統計")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // シェア機能
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

struct ActivityTypeButton: View {
    let type: Activity.ActivityType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: activityIcon(for: type))
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 50, height: 50)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
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
}

@available(iOS 16.0, *)
struct ActivityLineChart: View {
    let period: StatisticsView.Period
    let activityType: Activity.ActivityType?
    let dataStore: DataStore
    
    var body: some View {
        let data = prepareChartData()
        
        Chart {
            ForEach(data, id: \.date) { item in
                LineMark(
                    x: .value("日付", item.date),
                    y: .value("数値", item.value)
                )
                .foregroundStyle(item.activityType == nil ? Color.purple : colorForActivity(item.activityType!))
                .symbol(Circle().strokeBorder(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatAxisDate(date))
                    }
                }
            }
        }
    }
    
    // データ準備
    private func prepareChartData() -> [ChartDataPoint] {
        var result: [ChartDataPoint] = []
        
        var dates: [Date]
        
        switch period {
        case .week:
            dates = getWeekDates()
        case .month:
            dates = getMonthDates()
        case .year:
            dates = getYearDates()
        }
        
        if let specificType = activityType {
            // 特定のアクティビティタイプ
            for date in dates {
                let value = totalValueForDate(date, activityType: specificType)
                result.append(ChartDataPoint(date: date, value: value, activityType: specificType))
            }
        } else {
            // すべてのアクティビティタイプ
            for type in Activity.ActivityType.allCases {
                if dataStore.userProfile.preferredActivityTypes.contains(type) {
                    for date in dates {
                        let value = totalValueForDate(date, activityType: type)
                        if value > 0 {  // 値がある場合のみ追加
                            result.append(ChartDataPoint(date: date, value: value, activityType: type))
                        }
                    }
                }
            }
        }
        
        return result
    }
    
    // 日付の取得（週）
    private func getWeekDates() -> [Date] {
        let calendar = Calendar.current
        let weekStart = dataStore.getWeekStart()
        var result: [Date] = []
    
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: weekStart) {
                result.append(date)
            }
        }
    
    return result
    }
    
    // 日付の取得（月）
    private func getMonthDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var result: [Date] = []
        
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let monthStart = calendar.date(from: components) else { return [] }
        
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(date)
            }
        }
        
        return result
    }
    
    // 日付の取得（年）
    private func getYearDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var result: [Date] = []
        
        let components = calendar.dateComponents([.year], from: today)
        guard let yearStart = calendar.date(from: components) else { return [] }
        
        for month in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: month, to: yearStart) {
                result.append(date)
            }
        }
        
        return result
    }
    
    // 特定の日付とアクティビティタイプの合計値
    private func totalValueForDate(_ date: Date, activityType: Activity.ActivityType) -> Double {
        let calendar = Calendar.current
        
        let activities = dataStore.activities.filter { activity in
            activity.type == activityType && calendar.isDate(activity.date, inSameDayAs: date)
        }
        
        if activityType == .walking && period != .year {
            // 歩行距離の場合はdistanceを使用
            return activities.reduce(0.0) { $0 + ($1.distance ?? 0.0) }
        } else {
            // それ以外はcountを使用
            return Double(activities.reduce(0) { $0 + $1.count })
        }
    }
    
    // X軸のラベルフォーマット
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .week:
            formatter.dateFormat = "E"  // 曜日
        case .month:
            formatter.dateFormat = "d"  // 日付
        case .year:
            formatter.dateFormat = "MMM"  // 月
        }
        
        return formatter.string(from: date)
    }
    
    // アクティビティタイプによる色分け
    private func colorForActivity(_ type: Activity.ActivityType) -> Color {
        switch type {
        case .walking: return .blue
        case .running: return .green
        case .cycling: return .orange
        case .swimming: return .cyan
        case .squats: return .red
        case .pushups: return .pink
        case .situps: return .purple
        case .weightTraining: return .brown
        case .yoga: return .indigo
        case .other: return .gray
        }
    }
}

// グラフデータポイント
struct ChartDataPoint {
    let date: Date
    let value: Double
    let activityType: Activity.ActivityType?
}

struct StatisticsSummaryView: View {
    @EnvironmentObject var dataStore: DataStore
    let period: StatisticsView.Period
    let activityType: Activity.ActivityType?
    
    var body: some View {
        VStack(spacing: 16) {
            // 合計カウント
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("総アクティビティ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalCount())")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("総消費カロリー")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(totalCalories()) kcal")
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            
            Divider()
            
            // アクティブ日数
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("アクティブ日数")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(activeDays()) 日")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("平均活動量")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let avgCount = averageCount() {
                        Text("\(avgCount, specifier: "%.1f")")
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("-")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    private func activitiesForPeriod() -> [Activity] {
        var activities = dataStore.activities
        
        if let activityType = activityType {
            activities = activities.filter { $0.type == activityType }
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        switch period {
        case .week:
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
                return []
            }
            return activities.filter { $0.date >= weekStart && $0.date <= today }
            
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
        return activitiesForPeriod().reduce(0) { $0 + $1.count }
    }
    
    private func totalCalories() -> Int {
        return activitiesForPeriod().reduce(0) { $0 + ($1.caloriesBurned ?? 0) }
    }
    
    private func activeDays() -> Int {
        let calendar = Calendar.current
        let activities = activitiesForPeriod()
        
        let uniqueDays = Set(activities.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    private func averageCount() -> Double? {
        let activities = activitiesForPeriod()
        guard !activities.isEmpty else { return nil }
        
        let totalCount = activities.reduce(0) { $0 + $1.count }
        let days = activeDays()
        
        return days > 0 ? Double(totalCount) / Double(days) : nil
    }
}

struct GoalProgressView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        goalsList
    }
    
    // リストを別のプロパティに分割
    private var goalsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dataStore.userProfile.goals.isEmpty {
                emptyGoalsMessage
            } else {
                ForEach(dataStore.userProfile.goals) { goal in
                    goalProgressRow(for: goal)
                }
            }
        }
    }
    
    // 目標がない場合のメッセージ
    private var emptyGoalsMessage: some View {
        Text("目標が設定されていません")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
    }
    
    // 個別の目標行
    private func goalProgressRow(for goal: Goal) -> some View {
        HStack {
            goalInfo(for: goal)
            
            Spacer()
            
            // 円形進捗インジケータ
            progressCircle(for: goal)
        }
    }
    
    // 目標情報
    private func goalInfo(for goal: Goal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.activityType.rawValue)
                .font(.headline)
            
            let progress = calculateProgress(for: goal)
            let achieved = Int(progress * Double(goal.weeklyTarget))
            
            Text("\(achieved) / \(goal.weeklyTarget) \(goal.unit)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // 進捗円
    private func progressCircle(for goal: Goal) -> some View {
        let progress = calculateProgress(for: goal)
        
        return ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.blue)
            
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
            
            Text("\(Int(progress * 100))%")
                .font(.system(.footnote, design: .rounded))
                .fontWeight(.bold)
        }
        .frame(width: 60, height: 60)
    }
    
    // 進捗計算
    private func calculateProgress(for goal: Goal) -> Double {
        // DataStoreの共通メソッドを使用
        return dataStore.calculateProgress(for: goal, activityType: goal.activityType)
    }
}
