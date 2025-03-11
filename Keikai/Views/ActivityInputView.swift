import SwiftUI

struct ActivityInputView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @Binding var isTabActive: Bool
    
    // 初期化時にisTabActiveの初期値を設定
        init(isTabActive: Binding<Bool> = .constant(false)) {
            self._isTabActive = isTabActive
        }
    
    @State private var activityName = ""
    @State private var selectedType = Activity.ActivityType.walking
    @State private var count = ""
    @State private var distance = ""
    @State private var duration = ""
    @State private var caloriesBurned = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var showingTemplates = false
    @State private var timerActive = false
    @State private var timerSeconds = 0
    
    // クイックテンプレート
    let templates = [
        ("ウォーキング", Activity.ActivityType.walking, 5000),
        ("スクワット", Activity.ActivityType.squats, 20),
        ("ランニング", Activity.ActivityType.running, 3000),
        ("腕立て伏せ", Activity.ActivityType.pushups, 15)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // クイックテンプレート
                Section(header: Text("クイックテンプレート")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(templates, id: \.0) { template in
                                Button(action: {
                                    applyTemplate(template)
                                }) {
                                    VStack {
                                        Image(systemName: activityIcon(for: template.1))
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .frame(width: 50, height: 50)
                                            .background(Color.blue)
                                            .clipShape(Circle())
                                        
                                        Text(template.0)
                                            .font(.caption)
                                        
                                        Text("\(template.2)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 80)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 基本情報
                Section(header: Text("基本情報")) {
                    TextField("アクティビティ名", text: $activityName)
                    
                    Picker("種類", selection: $selectedType) {
                        ForEach(Activity.ActivityType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("回数/歩数")
                        TextField("", text: $count)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    // 歩行距離フィールドを追加
                        if selectedType == .walking || selectedType == .running {
                            HStack {
                                Text("距離 (km)")
                                TextField("", text: $distance)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    
                    HStack {
                        Text("時間（分）")
                        TextField("", text: $duration)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("消費カロリー")
                        TextField("", text: $caloriesBurned)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("日付", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                // タイマー（オプション）
                Section(header: Text("タイマー")) {
                    HStack {
                        Text(formatTime(timerSeconds))
                            .font(.system(size: 40, weight: .medium, design: .monospaced))
                            .frame(maxWidth: .infinity)
                    }
                    
                    HStack {
                        Button(action: {
                            if timerActive {
                                timerActive = false
                            } else {
                                if timerSeconds == 0 {
                                    // タイマーをリセット
                                    timerSeconds = 0
                                }
                                timerActive = true
                                // タイマーを開始
                                startTimer()
                            }
                        }) {
                            Text(timerActive ? "一時停止" : "開始")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            timerSeconds = 0
                            timerActive = false
                        }) {
                            Text("リセット")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            // 時間を記録
                            let minutes = timerSeconds / 60
                            duration = "\(minutes)"
                            timerActive = false
                        }) {
                            Text("記録")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(timerSeconds == 0)
                    }
                }
                
                // メモ
                Section(header: Text("メモ")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("アクティビティを記録")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    cancelActivity()
                },
                trailing: Button("保存") {
                    saveActivity()
                }
                .disabled(activityName.isEmpty || count.isEmpty)
            )
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
    
    private func applyTemplate(_ template: (String, Activity.ActivityType, Int)) {
        activityName = template.0
        selectedType = template.1
        count = "\(template.2)"
        
        // デフォルト値を設定
        switch template.1 {
        case .walking, .running:
            // 歩数から消費カロリーを推定
            let estimatedCalories = Int(Double(template.2) * 0.04)
            caloriesBurned = "\(estimatedCalories)"
            
        case .squats, .pushups, .situps:
            // 回数から消費カロリーを推定
            let estimatedCalories = Int(Double(template.2) * 0.3)
            caloriesBurned = "\(estimatedCalories)"
            
        default:
            break
        }
    }
    
    private func saveActivity() {
        guard let countInt = Int(count) else { return }
        
        var distanceDouble: Double? = nil
            if !distance.isEmpty, let distVal = Double(distance) {
                distanceDouble = distVal
        }
        
        var durationInt: Int? = nil
        if !duration.isEmpty, let durInt = Int(duration) {
            durationInt = durInt
        }
        
        var caloriesInt: Int? = nil
        if !caloriesBurned.isEmpty, let calInt = Int(caloriesBurned) {
            caloriesInt = calInt
        }
        
        let activity = Activity(
            name: activityName,
            type: selectedType,
            count: countInt,
            distance: distanceDouble,
            duration: durationInt,
            caloriesBurned: caloriesInt,
            date: date,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataStore.addActivity(activity)
        // タブから開いた場合はタブを切り替える
        if isTabActive {
            isTabActive = false  // タブを非アクティブにする
        } else {
            presentationMode.wrappedValue.dismiss()  // モーダルを閉じる
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    // キャンセルボタンアクション - 修正
        private func cancelActivity() {
            if isTabActive {
                isTabActive = false  // タブを非アクティブにする
            } else {
                presentationMode.wrappedValue.dismiss()  // モーダルを閉じる
            }
        }
    // ナビゲーションバーの設定
        var navigationBarItems: some View {
            Group {
                Button("キャンセル") {
                    cancelActivity()
                }
            }
        }
    
    private func startTimer() {
        // バックグラウンドスレッドでタイマーを動かす
        DispatchQueue.global(qos: .background).async {
            while timerActive {
                DispatchQueue.main.async {
                    timerSeconds += 1
                }
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
