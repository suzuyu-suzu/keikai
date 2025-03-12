import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedWeekOffset = 0
    @State private var showingAddActivity = false
    @State private var isLoadingHealthData = false
    @State private var selectedCircleIndex = 0
    @State private var currentTime = Date()
     // タイマーでの時間更新
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    // スワイプ可能な円形進捗ビュー
                    if !dataStore.userProfile.homeCircleTypes.isEmpty {
                        TabView(selection: $selectedCircleIndex) {
                            ForEach(0..<dataStore.userProfile.homeCircleTypes.count, id: \.self) { index in
                                let circleType = dataStore.userProfile.homeCircleTypes[index]
                                VStack {
                                    CircularProgressView(
                                        progress: progressForCircleType(circleType),
                                        title: circleType.rawValue,
                                        subtitle: subtitleForCircleType(circleType),
                                        color: colorForCircleType(circleType)
                                    )
                                    .padding(.horizontal, 20)
                                    .frame(height: UIScreen.main.bounds.width - 40)  // 画面幅一杯に
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        .frame(height: UIScreen.main.bounds.width + 40)  // タブインジケータ用の余白
                        .onAppear {
                            // デフォルトでは距離の進捗を表示
                            if let distanceIndex = dataStore.userProfile.homeCircleTypes.firstIndex(of: .distance) {
                                selectedCircleIndex = distanceIndex
                            }
                        }
                    }
                    // 週間の進捗状況
                    WeeklyProgressView(weekOffset: selectedWeekOffset)
                        .frame(height: 200)
                        .padding(.horizontal)
                    
                    // 日付セレクター
                    HStack {
                        Button(action: {
                            withAnimation {
                                selectedWeekOffset -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(weekDateRangeString())
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                selectedWeekOffset = min(selectedWeekOffset + 1, 0)
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(selectedWeekOffset < 0 ? .blue : .gray)
                        }
                        .disabled(selectedWeekOffset >= 0)
                    }
                    .padding(.horizontal)
                    
                    // アクティビティのサマリー
                    VStack(alignment: .leading, spacing: 10) {
                        Text("今週のアクティビティ")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(dataStore.userProfile.preferredActivityTypes, id: \.self) { activityType in
                            NavigationLink(destination: ActivityDetailView(activityType: activityType)) {
                                ActivitySummaryCard(activityType: activityType, weekOffset: selectedWeekOffset)
                            }
                        }
                        
                        NavigationLink(destination: GoalSettingView()) {
                            AddGoalButton()
                        }
                    }
                    
                    // 最近の記録
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近の記録")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        RecentActivitiesView()
                    }
                }
                .padding(.vertical)
                
                // HealthKitデータ同期ボタンを追加
                    if healthKitManager.isAuthorized {
                        Button(action: {
                            syncHealthKitData()
                        }) {
                            HStack {
                                if isLoadingHealthData {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text("健康データを同期")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(isLoadingHealthData)
                    } else {
                        Button(action: {
                            requestHealthKitAuthorization()
                        }) {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("健康データへのアクセスを許可")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
            }
            .navigationTitle("Keikai 〜軽快〜")
            .onReceive(timer) { _ in
                            currentTime = Date()
                        }
//            .navigationBarItems(trailing: Button(action: {
//                showingAddActivity = true
//            }) {
//                Image(systemName: "plus.circle.fill")
//                    .font(.title2)
//            })
//            .sheet(isPresented: $showingAddActivity) {
//                ActivityInputView()
//            }
        }
    }
    
    // ヘッダービュー
        private var headerView: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(dateFormatter.string(from: currentTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(timeFormatter.string(from: currentTime))
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    // 天気アイコンなど追加したい場合はここに
                }
                
                Text(motivationalMessage())
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.vertical, 5)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        
        // フォーマッター
        private var dateFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            return formatter
        }
        
        private var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter
        }
        
        // モチベーションメッセージ
        private func motivationalMessage() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        // 週の開始日と終了日を取得
        let weekStart = dataStore.getWeekStart(for: today)
        let weekEnd = dataStore.getWeekEnd(for: today)
        
        // 週の始まりからの経過日数を計算
        let daysSinceWeekStart = calendar.dateComponents([.day], from: weekStart, to: today).day ?? 0
        
        // 週の進捗を計算 (0.0 - 1.0)
        let weekProgress = Double(daysSinceWeekStart) / 7.0
        
        // 週の進捗から適切なメッセージを返す
        if weekProgress < 0.3 {
            return "今週も頑張りましょう！新たな目標に向かって！"
        } else if weekProgress < 0.7 {
            // 週の中盤
            let overallProgress = calculateOverallProgress()
            if overallProgress < 0.5 {
                return "目標達成のためには今日も活動的に過ごしましょう！"
            } else {
                return "調子が良いですね！このまま続けましょう！"
            }
        } else {
            // 週末
            let overallProgress = calculateOverallProgress()
            if overallProgress < 0.7 {
                return "週末です。目標達成に向けて頑張りましょう！"
            } else {
                return "素晴らしい一週間でした！目標達成まであと少し！"
            }
        }
    }
        
    
    private func requestHealthKitAuthorization() {
        healthKitManager.requestAuthorization { success in
            // 成功メッセージなどをここに追加できます
        }
    }

    private func syncHealthKitData() {
        isLoadingHealthData = true
        
        // 週間データを取得する期間
        let calendar = Calendar.current
        let today = Date()
        
        var weekStart: Date
        
        if dataStore.userProfile.weekStartsOnMonday {
            // 月曜始まり
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            weekStart = calendar.date(from: components)!
        } else {
            // 日曜始まり
            let weekday = calendar.component(.weekday, from: today)
            let daysToSubtract = weekday - 1
            weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: today))!
        }
        
        // 歩数を取得
        healthKitManager.fetchSteps(startDate: weekStart, endDate: today) { steps in
            // 歩行距離を取得
            self.healthKitManager.fetchDistance(startDate: weekStart, endDate: today) { distance in
                // 歩行アクティビティを作成または更新
                let walkingActivity = Activity(
                    id: UUID(),
                    name: "HealthKit歩行データ",
                    type: .walking,
                    count: steps,
                    distance: distance,
                    duration: nil,
                    caloriesBurned: Int(distance * 60), // 距離からカロリーを概算
                    date: today,
                    notes: "HealthKitから同期",
                    fromHealthKit: true
                )
                
                // HealthKitフラグが付いた既存のアクティビティを削除
                self.dataStore.activities.removeAll { $0.fromHealthKit }
                
                // 新しいアクティビティを追加
                self.dataStore.addActivity(walkingActivity)
                
                self.isLoadingHealthData = false
            }
        }
    }
    
    private func weekDateRangeString() -> String {
        let today = Date()
        // selectedWeekOffsetを使って基準日を計算
        let referenceDate = Calendar.current.date(byAdding: .day, value: selectedWeekOffset * 7, to: today) ?? today
        
        // DataStoreの週計算メソッドを使用
        let weekStart = dataStore.getWeekStart(for: referenceDate)
        let weekEnd = dataStore.getWeekEnd(for: referenceDate)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        return "\(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))"
    }
    
    // 各円タイプの進捗率を計算
        private func progressForCircleType(_ type: UserProfile.CircleType) -> Double {
            switch type {
            case .overall:
                return calculateOverallProgress()
            case .steps, .distance:
                return calculateStepsOrDistanceProgress(type)
            default:
                if let activityType = type.activityType(),
                   let goal = dataStore.userProfile.goals.first(where: { $0.activityType == activityType }) {
                    return calculateActivityProgress(activityType, goal)
                }
                return 0
            }
        }
        
        // 円タイプごとのサブタイトル
        private func subtitleForCircleType(_ type: UserProfile.CircleType) -> String {
            switch type {
            case .overall:
                return "全目標の平均達成率"
            case .steps:
                if let goal = dataStore.userProfile.goals.first(where: { $0.activityType == .walking }) {
                    let achieved = totalStepsForCurrentWeek()
                    return "\(achieved) / \(goal.weeklyTarget) 歩"
                }
                return "目標未設定"
            case .distance:
                if let goal = dataStore.userProfile.goals.first(where: { $0.activityType == .walking }) {
                    // 距離目標を仮定（例: 週間35km）
                    let distance = totalDistanceForCurrentWeek()
                    // 距離目標
                    let distanceGoal = 35.0  // 仮の値
                    return String(format: "%.1f / %.1f km", distance, distanceGoal)
                }
                return "目標未設定"
            default:
                if let activityType = type.activityType(),
                   let goal = dataStore.userProfile.goals.first(where: { $0.activityType == activityType }) {
                    let achieved = totalCountForActivity(activityType)
                    return "\(achieved) / \(goal.weeklyTarget) \(goal.unit)"
                }
                return "目標未設定"
            }
        }
        
        // 円タイプごとの色
        private func colorForCircleType(_ type: UserProfile.CircleType) -> Color {
            switch type {
            case .overall: return .purple
            case .steps: return .blue
            case .distance: return .green
            case .squats: return .orange
            case .pushups: return .red
            case .situps: return .pink
            default: return .blue
            }
        }
        
        // 全体の進捗を計算
        private func calculateOverallProgress() -> Double {
            let goals = dataStore.userProfile.goals
            if goals.isEmpty { return 0 }
            
            var totalProgress = 0.0
            var goalCount = 0
            
            for goal in goals {
                let activityType = goal.activityType
                
                // 特別に歩行距離を計算
                if activityType == .walking && dataStore.userProfile.homeCircleTypes.contains(.distance) {
                    let distance = totalDistanceForCurrentWeek()
                    let distanceGoal = 35.0  // 仮の値
                    let progress = min(distance / distanceGoal, 1.0)
                    totalProgress += progress
                    goalCount += 1
                }
                
                // 通常のアクティビティ
                let progress = calculateActivityProgress(activityType, goal)
                totalProgress += progress
                goalCount += 1
            }
            
            return goalCount > 0 ? totalProgress / Double(goalCount) : 0
        }
        
        // 歩数または歩行距離の進捗を計算
        private func calculateStepsOrDistanceProgress(_ type: UserProfile.CircleType) -> Double {
            if type == .steps {
                if let goal = dataStore.userProfile.goals.first(where: { $0.activityType == .walking }) {
                    let steps = totalStepsForCurrentWeek()
                    return min(Double(steps) / Double(goal.weeklyTarget), 1.0)
                }
            } else if type == .distance {
                // 距離目標（例: 35km/週）
                let distance = totalDistanceForCurrentWeek()
                let distanceGoal = 35.0  // 仮の値
                return min(distance / distanceGoal, 1.0)
            }
            return 0
        }
        
        // 特定のアクティビティの進捗を計算
        private func calculateActivityProgress(_ activityType: Activity.ActivityType, _ goal: Goal) -> Double {
            let count = totalCountForActivity(activityType)
            return min(Double(count) / Double(goal.weeklyTarget), 1.0)
        }
        
        // 現在の週の合計歩数
        private func totalStepsForCurrentWeek() -> Int {
            let weekStart = dataStore.getWeekStart()
            let weekEnd = dataStore.getWeekEnd()
    
            return dataStore.activities
                .filter { $0.type == .walking && $0.date >= weekStart && $0.date <= weekEnd }
                .reduce(0) { $0 + $1.count }
        }
        
        // 現在の週の合計歩行距離
        private func totalDistanceForCurrentWeek() -> Double {
            let weekStart = dataStore.getWeekStart()
                let weekEnd = dataStore.getWeekEnd()
                
                return dataStore.activities
                    .filter { $0.type == .walking && $0.date >= weekStart && $0.date <= weekEnd }
                    .reduce(0.0) { $0 + ($1.distance ?? 0.0) }
        }
        
        // 特定のアクティビティの合計回数
        private func totalCountForActivity(_ activityType: Activity.ActivityType) -> Int {
            let weekStart = dataStore.getWeekStart()
               let weekEnd = dataStore.getWeekEnd()
               
               return dataStore.activities
                   .filter { $0.type == activityType && $0.date >= weekStart && $0.date <= weekEnd }
                   .reduce(0) { $0 + $1.count }
        }
}

// MARK: - サブビュー

struct WeeklyProgressView: View {
    @EnvironmentObject var dataStore: DataStore
    let weekOffset: Int
    
    var body: some View {
        VStack {
            ZStack {
                // 円形進捗表示
                Circle()
                    .stroke(lineWidth: 20)
                    .opacity(0.3)
                    .foregroundColor(Color.blue)
                
                Circle()
                    .trim(from: 0.0, to: overallProgress())
                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                    .foregroundColor(Color.blue)
                    .rotationEffect(Angle(degrees: 270.0))
                    .animation(.linear, value: overallProgress())
                
                VStack {
                    Text("\(Int(overallProgress() * 100))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    Text("週間目標")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func overallProgress() -> Double {
        // 全ての設定した目標の平均進捗率を計算
        let goals = dataStore.userProfile.goals
        if goals.isEmpty { return 0 }
        
        var totalProgress = 0.0
        
        for goal in goals {
            let activityType = goal.activityType
            let thisWeekActivities = getThisWeekActivities()
            
            let achieved = thisWeekActivities
                .filter { $0.type == activityType }
                .reduce(0) { $0 + $1.count }
            
            let progress = min(Double(achieved) / Double(goal.weeklyTarget), 1.0)
            totalProgress += progress
        }
        
        return totalProgress / Double(goals.count)
    }
    
    private func getThisWeekActivities() -> [Activity] {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: today) else {
            return []
        }
        
        return dataStore.getActivitiesForWeek(containing: weekStart)
    }
    
    
}

struct ActivitySummaryCard: View {
    @EnvironmentObject var dataStore: DataStore
    let activityType: Activity.ActivityType
    let weekOffset: Int
    
    var body: some View {
        HStack {
            // アイコン
            Image(systemName: activityIcon(for: activityType))
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activityType.rawValue)
                    .font(.headline)
                
                if let goal = dataStore.userProfile.goals.first(where: { $0.activityType == activityType }) {
                    HStack {
                        let achieved = getAchievedCount()
                        Text("\(achieved) / \(goal.weeklyTarget) \(goal.unit)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        // 進捗バー
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 6)
                                    .opacity(0.3)
                                    .foregroundColor(Color.blue)
                                
                                Rectangle()
                                    .frame(width: min(CGFloat(achieved) / CGFloat(goal.weeklyTarget) * geometry.size.width, geometry.size.width), height: 6)
                                    .foregroundColor(Color.blue)
                            }
                            .cornerRadius(3)
                        }
                        .frame(height: 6)
                    }
                } else {
                    Text("目標未設定")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
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
    
    private func getAchievedCount() -> Int {
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.date(byAdding: .day, value: weekOffset * 7, to: today) else {
            return 0
        }
        
        let thisWeekActivities = dataStore.getActivitiesForWeek(containing: weekStart)
        
        return thisWeekActivities
            .filter { $0.type == activityType }
            .reduce(0) { $0 + $1.count }
    }
}

struct AddGoalButton: View {
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            Text("目標を追加/編集")
                .font(.headline)
                .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct RecentActivitiesView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        let activities = Array(dataStore.activities.sorted(by: { $0.date > $1.date }).prefix(5))
        
        if activities.isEmpty {
            Text("最近の記録はありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
        } else {
            ForEach(activities) { activity in
                NavigationLink(destination: ActivityDetailView(activityType: activity.type)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.name)
                                .font(.headline)
                            
                            Text(activity.type.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formattedDate(activity.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(activity.count) \(unitFor(activity.type))")
                                .font(.headline)
                            
                            if let calories = activity.caloriesBurned, calories > 0 {
                                Text("\(calories) kcal")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
}
