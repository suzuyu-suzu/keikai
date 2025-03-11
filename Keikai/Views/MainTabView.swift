import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house.fill")
                    }
                    .tag(0)
                
                StatisticsView()
                    .tabItem {
                        Label("統計", systemImage: "chart.bar.fill")
                    }
                    .tag(1)
                
                ActivityHistoryView()  // 新しいビュー - 記録履歴表示用
                    .tabItem {
                        Label("記録", systemImage: "list.bullet")  // アイコン変更
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Label("設定", systemImage: "person.fill")
                    }
                    .tag(3)
            }
            
            // 右下に配置する大きな記録ボタン
            NewRecordButton()
                .padding(.trailing, 20)
                .padding(.bottom, 80)  // タブの上に配置
        }
    }
}

// 大きな記録ボタン
struct NewRecordButton: View {
    @State private var showingAddActivity = false
    
    var body: some View {
        Button(action: {
            showingAddActivity = true
        }) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 65, height: 65)
                    .shadow(radius: 3)
                
                Image(systemName: "plus")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
        }
        .sheet(isPresented: $showingAddActivity) {
            ActivityInputView()
        }
    }
}
