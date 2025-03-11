import SwiftUI

struct ActivityHistoryRow: View {
    let activity: Activity
    
    var body: some View {
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
                Text("\(activity.count) \(unitForType(activity.type))")
                    .font(.headline)
                
                if let distance = activity.distance {
                    Text(String(format: "%.2f km", distance))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let calories = activity.caloriesBurned {
                    Text("\(calories) kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func unitForType(_ type: Activity.ActivityType) -> String {
        switch type {
        case .walking, .running: return "歩"
        case .cycling, .swimming: return "m"
        case .squats, .pushups, .situps: return "回"
        case .weightTraining, .yoga: return "分"
        case .other: return ""
        }
    }
}
