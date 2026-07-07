import SwiftUI

/// Prominent streak display card with flame, number, and milestone progress.
struct StreakCardView: View {
    let metrics: StreakMetrics
    let showMessage: Bool
    let onReplay: (() -> Void)? = nil
    
    private var showDayStreak: Bool { metrics.currentStreak >= 2 }
    
    var body: some View {
        VStack(spacing: 16) {
            // Flame + Streak Number
            VStack(spacing: 8) {
                if showDayStreak {
                    Text(metrics.streakEmoji)
                        .font(.system(size: 64))
                        .scaleEffect(metrics.isBroken ? 0.8 : 1.0)
                        .opacity(metrics.isBroken ? 0.6 : 1.0)
                    
                    Text("\(metrics.currentStreak)")
                        .font(.system(size: 72, weight: .heavy, design: .rounded))
                        .foregroundStyle(streakColor)
                    
                    Text("DAY STREAK")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                } else {
                    Text("🎯")
                        .font(.system(size: 58))
                    Text("Build your streak")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
            }
            
            // Motivational Message
            if showMessage {
                Text(metrics.streakMessage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(messageBgColor)
                    .cornerRadius(8)
            }
            
            // Milestone Progress
            if !metrics.isBroken {
                VStack(spacing: 8) {
                    HStack {
                        Text("Next: \(metrics.milestoneBadge ?? "Milestone")")
                            .font(.caption.bold())
                        Spacer()
                        Text("\(metrics.daysUntilMilestone) away")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: Double(metrics.nextMilestone - metrics.daysUntilMilestone), total: Double(metrics.nextMilestone))
                        .tint(streakColor)
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Streak at Risk Warning
            if metrics.streakAtRisk && !metrics.isBroken {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Streak at Risk!")
                            .font(.caption.bold())
                        Text("\(metrics.todayGoal - metrics.todayProgress) more words before midnight")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Break-in Counter (after streak lost)
            if metrics.isRebuildingAfterBreak {
                VStack(spacing: 8) {
                    HStack {
                        Text("🤝 Rebuild Streak")
                            .font(.caption.bold())
                        Spacer()
                        Text("Was \(metrics.longestStreak) days")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: Double(metrics.breakInStreak), total: Double(metrics.longestStreak))
                        .tint(.green)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Daily Progress (if visible in context)
            if !metrics.goalMetToday && !metrics.isBroken {
                HStack(spacing: 12) {
                    ProgressView(value: Double(metrics.todayProgress), total: Double(metrics.todayGoal))
                        .tint(.cyan)
                    Text("\(metrics.todayProgress)/\(metrics.todayGoal)")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                }
                .padding(8)
                .background(Color.cyan.opacity(0.05))
                .cornerRadius(6)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(borderColor, lineWidth: 2)
        )
    }
    
    private var streakColor: Color {
        switch metrics.currentStreak {
        case 0:
            return .gray
        case 1..<7:
            return .green
        case 7..<14:
            return .blue
        case 14..<30:
            return .orange
        case 30..<60:
            return Color(red: 1, green: 0.5, blue: 0)  // Gold
        default:
            return Color(red: 1, green: 0.84, blue: 0)  // Deep gold
        }
    }
    
    private var backgroundColor: Color {
        if metrics.isBroken {
            return Color.gray.opacity(0.1)
        }
        switch metrics.currentStreak {
        case 0:
            return Color.gray.opacity(0.05)
        case 1..<7:
            return Color.green.opacity(0.05)
        case 7..<14:
            return Color.blue.opacity(0.05)
        case 14..<30:
            return Color.orange.opacity(0.05)
        default:
            return Color.yellow.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if metrics.isBroken {
            return .gray.opacity(0.3)
        }
        return streakColor.opacity(0.3)
    }
    
    private var messageBgColor: Color {
        if metrics.isBroken {
            return Color.gray.opacity(0.3)
        }
        switch metrics.currentStreak {
        case 1..<7:
            return Color.green.opacity(0.3)
        case 7..<14:
            return Color.blue.opacity(0.3)
        case 14..<30:
            return Color.orange.opacity(0.3)
        default:
            return Color.yellow.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakCardView(
            metrics: StreakMetrics(
                currentStreak: 28,
                longestStreak: 28,
                breakInStreak: 0,
                daysUntilMilestone: 2,
                nextMilestone: 30,
                streakAtRisk: false,
                timeUntilDeadline: 3600,
                todayProgress: 15,
                todayGoal: 20
            ),
            showMessage: true
        )
        
        StreakCardView(
            metrics: StreakMetrics(
                currentStreak: 0,
                longestStreak: 28,
                breakInStreak: 2,
                daysUntilMilestone: 7,
                nextMilestone: 7,
                streakAtRisk: false,
                timeUntilDeadline: 3600,
                todayProgress: 3,
                todayGoal: 20
            ),
            showMessage: true
        )
    }
    .padding()
}
