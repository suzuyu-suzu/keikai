import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var userName: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var notificationsEnabled: Bool = true
    @State private var weeklyReportEnabled: Bool = true
    @State private var reminderTime = Date()
    @FocusState private var focusedField: FocusField?
    
    enum FocusField {
            case name, age, height, weight
        }
    
    var body: some View {
        NavigationView {
            Form {
                // ユーザー情報
                Section(header: Text("プロファイル情報")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            TextField("名前", text: $userName)
                                .font(.headline)
                                .focused($focusedField, equals: .name)
                            
                            Text("目標達成率: \(overallProgress(), specifier: "%.0f")%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text("年齢")
                        Spacer()
                        TextField("年齢", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .age)
                    }
                    
                    HStack {
                        Text("身長")
                        Spacer()
                        TextField("cm", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .height)
                    }
                    
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("kg", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .weight)
                    }
                }
                
                // 目標と実績
                Section(header: Text("目標と実績")) {
                    NavigationLink(destination: GoalSettingView()) {
                        Label("目標設定", systemImage: "target")
                    }
                    
                    NavigationLink(destination: BadgesView()) {
                        Label("実績とバッジ", systemImage: "medal")
                    }
                }
                
                // アプリ設定
                Section(header: Text("アプリ設定")) {
                    NavigationLink(destination: CustomizeView()) {
                        Label("ホーム画面のカスタマイズ", systemImage: "slider.horizontal.3")
                    }
                    
                    Toggle("通知", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker("リマインダー時間", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Toggle("週間レポート", isOn: $weeklyReportEnabled)
                }
                
                // アプリ情報
                Section(header: Text("アプリについて")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // アプリの評価
                    }) {
                        Label("アプリを評価する", systemImage: "star")
                    }
                    
                    Button(action: {
                        // プライバシーポリシー
                    }) {
                        Label("プライバシーポリシー", systemImage: "lock.shield")
                    }
                }
                
                // データ管理
                Section(header: Text("データ管理")) {
                    Button(action: {
                        // データエクスポート
                    }) {
                        Label("データをエクスポート", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // データをリセット
                        showResetConfirmation()
                    }) {
                        Label("データをリセット", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("完了") {
                        focusedField = nil  // キーボードを閉じる
                    }
                }
            }
            // ここにタップジェスチャーを追加
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear {
                loadUserProfile()
            }
            .onDisappear {
                saveUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        userName = dataStore.userProfile.name
        
        if let age = dataStore.userProfile.age {
            self.age = "\(age)"
        }
        
        if let height = dataStore.userProfile.height {
            self.height = "\(height)"
        }
        
        if let weight = dataStore.userProfile.weight {
            self.weight = "\(weight)"
        }
        
        notificationsEnabled = dataStore.userProfile.notificationsEnabled
        weeklyReportEnabled = dataStore.userProfile.weeklyReportEnabled
        
        if let reminderTime = dataStore.userProfile.reminderTime {
            self.reminderTime = reminderTime
        }
    }
    
    private func saveUserProfile() {
        dataStore.userProfile.name = userName
        
        if let age = Int(age) {
            dataStore.userProfile.age = age
        }
        
        if let height = Double(height) {
            dataStore.userProfile.height = height
        }
        
        if let weight = Double(weight) {
            dataStore.userProfile.weight = weight
        }
        
        dataStore.userProfile.notificationsEnabled = notificationsEnabled
        dataStore.userProfile.weeklyReportEnabled = weeklyReportEnabled
        dataStore.userProfile.reminderTime = notificationsEnabled ? reminderTime : nil
        
        // UserDefaultsに保存
        if let encoded = try? JSONEncoder().encode(dataStore.userProfile) {
            UserDefaults.standard.set(encoded, forKey: "UserProfile")
        }
    }
    
    private func showResetConfirmation() {
        // 実際のアプリではアラートを表示
        print("データリセットの確認ダイアログを表示")
    }
    
    private func overallProgress() -> Double {
        // 全ての設定した目標の平均進捗率を計算
        let goals = dataStore.userProfile.goals
        if goals.isEmpty { return 0 }
        
        var totalProgress = 0.0
        
        for goal in goals {
            let activityType = goal.activityType
            let thisWeekActivities = dataStore.getActivitiesForWeek(containing: Date())
            
            let achieved = thisWeekActivities
                .filter { $0.type == activityType }
                .reduce(0) { $0 + $1.count }
            
            let progress = min(Double(achieved) / Double(goal.weeklyTarget), 1.0)
            totalProgress += progress
        }
        
        return (totalProgress / Double(goals.count)) * 100
    }
}
