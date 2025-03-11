import SwiftUI

struct CustomizeView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var preferredActivityTypes: [Activity.ActivityType] = []
    @State private var isEditingActivityOrder = false
    @State private var homeCircleTypes: [UserProfile.CircleType] = []
    @State private var isEditingCircleOrder = false
    @State private var weekStartsOnMonday = true
    
    var body: some View {
        Form {
            Section(header: Text("表示するアクティビティ")) {
                ForEach(Activity.ActivityType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: activityIcon(for: type))
                            .foregroundColor(.blue)
                        
                        Text(type.rawValue)
                        
                        Spacer()
                        
                        Button(action: {
                            toggleActivityType(type)
                        }) {
                            Image(systemName: isPreferred(type) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isPreferred(type) ? .blue : .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            if !preferredActivityTypes.isEmpty {
                Section(header: Text("お気に入りの順序")) {
                    Button(action: {
                        isEditingActivityOrder.toggle()
                    }) {
                        Label(isEditingActivityOrder ? "完了" : "順序を変更", systemImage: isEditingActivityOrder ? "checkmark" : "arrow.up.arrow.down")
                    }
                    
                    if isEditingActivityOrder {
                        List {
                            ForEach(preferredActivityTypes, id: \.self) { type in
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundColor(.gray)
                                    
                                    Image(systemName: activityIcon(for: type))
                                        .foregroundColor(.blue)
                                    
                                    Text(type.rawValue)
                                }
                            }
                            .onMove(perform: moveActivityType)
                        }
                    } else {
                        ForEach(preferredActivityTypes, id: \.self) { type in
                            HStack {
                                Image(systemName: activityIcon(for: type))
                                    .foregroundColor(.blue)
                                
                                Text(type.rawValue)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("ホーム画面の設定")) {
                Toggle("週間進捗を表示", isOn: .constant(true))
                
                Toggle("最近の記録を表示", isOn: .constant(true))
                
                Picker("表示期間のデフォルト", selection: .constant(0)) {
                    Text("週間").tag(0)
                    Text("月間").tag(1)
                    Text("年間").tag(2)
                }
            }
            
            Section(header: Text("外観設定")) {
                Picker("カラーテーマ", selection: .constant(0)) {
                    Text("ブルー").tag(0)
                    Text("グリーン").tag(1)
                    Text("パープル").tag(2)
                    Text("レッド").tag(3)
                }
                
                Toggle("ダークモード", isOn: .constant(false))
                
                Picker("グラフスタイル", selection: .constant(0)) {
                    Text("バー").tag(0)
                    Text("ライン").tag(1)
                    Text("円").tag(2)
                }
            }
            
            Section(header: Text("ホーム画面の円グラフ設定")) {
                            Button(action: {
                                isEditingCircleOrder.toggle()
                            }) {
                                Label(isEditingCircleOrder ? "完了" : "表示順序を変更", systemImage: isEditingCircleOrder ? "checkmark" : "arrow.up.arrow.down")
                            }
                            
                            if isEditingCircleOrder {
                                List {
                                    ForEach(homeCircleTypes, id: \.self) { type in
                                        HStack {
                                            Image(systemName: "line.3.horizontal")
                                                .foregroundColor(.gray)
                                            
                                            Text(type.rawValue)
                                        }
                                    }
                                    .onMove(perform: moveCircleType)
                                }
                            } else {
                                ForEach(UserProfile.CircleType.allCases, id: \.self) { type in
                                    HStack {
                                        Text(type.rawValue)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            toggleCircleType(type)
                            }) {
                                Image(systemName: isCircleTypeEnabled(type) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isCircleTypeEnabled(type) ? .blue : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            Section(header: Text("週の設定")) {
                Toggle("週の開始日を月曜日にする", isOn: $weekStartsOnMonday)
                    .onChange(of: weekStartsOnMonday) { newValue in
                        dataStore.userProfile.weekStartsOnMonday = newValue
                        saveSettings()
                    }
            }
        }
        .navigationTitle("カスタマイズ")
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettings()
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
    
    private func loadPreferredActivityTypes() {
        preferredActivityTypes = dataStore.userProfile.preferredActivityTypes
    }
    
    private func savePreferredActivityTypes() {
        dataStore.userProfile.preferredActivityTypes = preferredActivityTypes
        
        // UserDefaultsに保存
        if let encoded = try? JSONEncoder().encode(dataStore.userProfile) {
            UserDefaults.standard.set(encoded, forKey: "UserProfile")
        }
    }
    
    private func isPreferred(_ type: Activity.ActivityType) -> Bool {
        return preferredActivityTypes.contains(type)
    }
    
    private func toggleActivityType(_ type: Activity.ActivityType) {
        if isPreferred(type) {
            preferredActivityTypes.removeAll { $0 == type }
        } else {
            preferredActivityTypes.append(type)
        }
    }
    
    private func moveActivityType(from source: IndexSet, to destination: Int) {
        preferredActivityTypes.move(fromOffsets: source, toOffset: destination)
    }
    
    private func loadSettings() {
            homeCircleTypes = dataStore.userProfile.homeCircleTypes
            weekStartsOnMonday = dataStore.userProfile.weekStartsOnMonday
        }
        
        // 設定の保存
        private func saveSettings() {
            dataStore.userProfile.homeCircleTypes = homeCircleTypes
            dataStore.userProfile.weekStartsOnMonday = weekStartsOnMonday
            
            // UserDefaultsに保存
            if let encoded = try? JSONEncoder().encode(dataStore.userProfile) {
                UserDefaults.standard.set(encoded, forKey: "UserProfile")
            }
        }
        
        // 円タイプが有効かどうか
        private func isCircleTypeEnabled(_ type: UserProfile.CircleType) -> Bool {
            return homeCircleTypes.contains(type)
        }
        
        // 円タイプの切り替え
        private func toggleCircleType(_ type: UserProfile.CircleType) {
            if isCircleTypeEnabled(type) {
                homeCircleTypes.removeAll { $0 == type }
            } else {
                homeCircleTypes.append(type)
            }
        }
        
        // 円タイプの順序変更
        private func moveCircleType(from source: IndexSet, to destination: Int) {
            homeCircleTypes.move(fromOffsets: source, toOffset: destination)
        }
}
