import SwiftUI

struct BadgesView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingUnlockedOnly = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // バッジの切り替えトグル
                Toggle("獲得したバッジのみ表示", isOn: $showingUnlockedOnly)
                    .padding(.horizontal)
                
                // バッジサマリー
                HStack(spacing: 20) {
                    BadgeSummaryCard(
                        title: "獲得済み",
                        count: earnedBadgesCount(),
                        icon: "checkmark.seal.fill",
                        color: .green
                    )
                    
                    BadgeSummaryCard(
                        title: "未獲得",
                        count: totalBadgesCount() - earnedBadgesCount(),
                        icon: "lock.fill",
                        color: .gray
                    )
                    
                    BadgeSummaryCard(
                        title: "達成率",
                        count: Int(Double(earnedBadgesCount()) / Double(totalBadgesCount()) * 100),
                        icon: "percent",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // バッジリスト
                VStack(alignment: .leading, spacing: 10) {
                    Text("バッジコレクション")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredBadges()) { badge in
                            BadgeCard(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // チャレンジセクション
                VStack(alignment: .leading, spacing: 10) {
                    Text("今週のチャレンジ")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    WeeklyChallenge()
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                // ヒント
                VStack(alignment: .leading, spacing: 10) {
                    Text("バッジの獲得方法")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text("運動を記録し、目標を達成することで様々なバッジを獲得できます。コンスタントな活動を続けて、より多くのバッジを集めましょう。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("実績とバッジ")
    }
    
    private func earnedBadgesCount() -> Int {
        return dataStore.userProfile.badges.filter { $0.isAchieved }.count
    }
    
    private func totalBadgesCount() -> Int {
        return dataStore.userProfile.badges.count
    }
    
    private func filteredBadges() -> [Badge] {
        if showingUnlockedOnly {
            return dataStore.userProfile.badges.filter { $0.isAchieved }
        } else {
            return dataStore.userProfile.badges
        }
    }
}

struct BadgeSummaryCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badge.isAchieved ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(badge.isAchieved ? .blue : .gray)
                
                if !badge.isAchieved {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .background(Circle().fill(Color.white).frame(width: 24, height: 24))
                        .offset(x: 30, y: 30)
                }
            }
            
            Text(badge.name)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(badge.isAchieved ? .primary : .secondary)
            
            Text(badge.description)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if badge.isAchieved, let achievedDate = badge.achievedDate {
                Text(formattedDate(achievedDate))
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "獲得日: \(formatter.string(from: date))"
    }
}

struct WeeklyChallenge: View {
    @EnvironmentObject var dataStore: DataStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("連続7日間のアクティビティ")
                    .font(.headline)
                
                Spacer()
                
                Text("3/7")
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            
            ProgressView(value: 3, total: 7)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.orange)
            
            Text("7日間連続でアクティビティを記録して特別なバッジを獲得しましょう！")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
