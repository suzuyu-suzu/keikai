import SwiftUI


struct ActivityHistoryView: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("今週のアクティビティ")) {
                    if thisWeekActivities().isEmpty {
                        Text("記録がありません")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(thisWeekActivities().sorted(by: { $0.date > $1.date })) { activity in
                            ActivityHistoryRow(activity: activity)
                        }
                        .onDelete(perform: deleteActivity)
                    }
                }
                
                Section(header: Text("先週のアクティビティ")) {
                    if lastWeekActivities().isEmpty {
                        Text("記録がありません")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 10)
                    } else {
                        ForEach(lastWeekActivities().sorted(by: { $0.date > $1.date })) { activity in
                            ActivityHistoryRow(activity: activity)
                        }
                        .onDelete(perform: deleteActivity)
                    }
                }
            }
            .navigationTitle("記録履歴")
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func thisWeekActivities() -> [Activity] {
        let weekStart = dataStore.getWeekStart()
            let weekEnd = dataStore.getWeekEnd()
            
            return dataStore.activities.filter { $0.date >= weekStart && $0.date <= weekEnd }
        
    }
    
    private func lastWeekActivities() -> [Activity] {
        let calendar = Calendar.current
        let thisWeekStart = dataStore.getWeekStart()
        let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
        let lastWeekEnd = dataStore.getWeekEnd(for: lastWeekStart)
        
        return dataStore.activities.filter { $0.date >= lastWeekStart && $0.date <= lastWeekEnd }
    }
    
    private func deleteActivity(at offsets: IndexSet) {
        let activitiesToDelete = thisWeekActivities().sorted(by: { $0.date > $1.date })
        
        for index in offsets {
            if index < activitiesToDelete.count {
                let activityToDelete = activitiesToDelete[index]
                dataStore.activities.removeAll { $0.id == activityToDelete.id }
            }
        }
        
        // 保存
        if let encoded = try? JSONEncoder().encode(dataStore.activities) {
            UserDefaults.standard.set(encoded, forKey: "SavedActivities")
        }
    }
}


