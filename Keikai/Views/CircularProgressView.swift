import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let title: String
    let subtitle: String
    var color: Color = .blue
    @State private var animationProgress: Double = 0
    
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(color)
            
            // 進捗を示す円弧
            Circle()
                .trim(from: 0.0, to: animationProgress)
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.easeInOut(duration: 1.0), value: animationProgress)
            
            // 中央のテキスト
            VStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                
                Text(title)
                    .font(.headline)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animationProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            // アニメーションをリセットして再開
            animationProgress = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animationProgress = newValue
            }
        }
    }
}
