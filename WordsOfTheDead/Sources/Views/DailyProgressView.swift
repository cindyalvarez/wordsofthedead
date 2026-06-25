import SwiftUI

/// Shows daily goal progress with visual bar and time remaining until deadline.
struct DailyProgressView: View {
    let completed: Int
    let goal: Int
    let timeRemaining: TimeInterval
    
    var progress: Double {
        min(Double(completed) / Double(goal), 1.0)
    }
    
    var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .green
        case 0.5..<0.75:
            return .yellow
        case 0.75..<0.9:
            return .orange
        default:
            return .green  // Goal met
        }
    }
    
    var timeString: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Progress")
                        .font(.headline)
                    Text("\(completed)/\(goal) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeString)
                        .font(.caption.bold())
                    
                    if completed >= goal {
                        Text("Goal Met! ✅")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            // Progress bar with gradient
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                
                // Filled portion with gradient
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [progressColor, progressColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(progress) * 100, alignment: .leading)
            }
            .frame(height: 24)
            
            // Percentage
            HStack {
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.caption.bold())
                    .foregroundStyle(progressColor)
                
                Spacer()
                
                if progress < 1.0 {
                    Text("\(goal - completed) more needed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    VStack(spacing: 16) {
        DailyProgressView(completed: 8, goal: 20, timeRemaining: 3600)
        DailyProgressView(completed: 20, goal: 20, timeRemaining: 1800)
        DailyProgressView(completed: 5, goal: 20, timeRemaining: 7200)
    }
    .padding()
}
