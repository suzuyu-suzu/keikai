import SwiftUI

struct GoalSettingView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.presentationMode) var presentationMode
    @State private var goals: [GoalState] = []
    
    struct GoalState: Identifiable {
        var id: UUID
        var activityType: Activity.ActivityType
        var weeklyTarget: String
        var unit: String
        var isNew: Bool
    }
    
    var body: some View {
        Form {
            Section(header: Text("週間目標の設定")) {
                List {
                    ForEach(goals) { goalState in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goalState.activityType.rawValue)
                                    .font(.headline)
                                
                                if goalState.isNew {
                                    Text("新規目標")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            Spacer()
                            
                            HStack {
                                TextField("目標値", text: Binding(
                                    get: { goalState.weeklyTarget },
                                    set: { newValue in
                                        if let index = goals.firstIndex(where: { $0.id == goalState.id }) {
                                            goals[index].weeklyTarget = newValue
                                        }
                                    }
                                ))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                
                                Text(goalState.unit)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteGoal)
                }
            }
            
            Section {
                Button(action: {
                    addNewGoal()
                }) {
                    Label("新しい目標を追加", systemImage: "plus")
                }
            }
            
            Section {
                Button(action: {
                    saveGoals()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("保存")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("目標設定")
        .onAppear {
            loadGoals()
        }
    }
    
    private func loadGoals() {
        // 既存の目標をロード
        goals = dataStore.userProfile.goals.map { goal in
            GoalState(
                id: goal.id,
                activityType: goal.activityType,
                weeklyTarget: "\(goal.weeklyTarget)",
                unit: goal.unit,
                isNew: false
            )
        }
        
        // 目標がない場合はデフォルト目標を設定
        if goals.isEmpty {
            addDefaultGoals()
        }
    }
    
    private func addDefaultGoals() {
        let defaultGoals: [(Activity.ActivityType, Int, String)] = [
            (.walking, 70000, "歩"),
            (.squats, 100, "回")
        ]
        
        for defaultGoal in defaultGoals {
            goals.append(
                GoalState(
                    id: UUID(),
                    activityType: defaultGoal.0,
                    weeklyTarget: "\(defaultGoal.1)",
                    unit: defaultGoal.2,
                    isNew: true
                )
            )
        }
    }
    
    private func addNewGoal() {
        // 既存の目標には含まれていないアクティビティタイプを取得
        let existingTypes = Set(goals.map { $0.activityType })
        let availableTypes = Activity.ActivityType.allCases.filter { !existingTypes.contains($0) }
        
        if let firstAvailable = availableTypes.first {
            let newGoal = GoalState(
                id: UUID(),
                activityType: firstAvailable,
                weeklyTarget: "100",
                unit: unitFor(firstAvailable),
                isNew: true
            )
            
            goals.append(newGoal)
        }
    }
    
    private func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
    
    private func saveGoals() {
        // 全ての既存目標をクリアして新しい目標で置き換え
        dataStore.userProfile.goals.removeAll()
        
        for goalState in goals {
            guard let target = Int(goalState.weeklyTarget) else { continue }
            
            let goal = Goal(
                id: goalState.id,
                activityType: goalState.activityType,
                weeklyTarget: target,
                unit: goalState.unit,
                startDate: Date()
            )
            
            dataStore.updateGoal(goal)
        }
    }
    
    private func unitFor(_ type: Activity.ActivityType) -> String {
        switch type {
        case .walking, .running: return "歩"
        case .cycling, .swimming: return "m"
        case .squats, .pushups, .situps: return "回"
        case .weightTraining, .yoga: return "分"
        case .other: return "回"
        }
    }
}
