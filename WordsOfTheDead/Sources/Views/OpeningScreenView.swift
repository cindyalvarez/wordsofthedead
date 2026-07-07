import SwiftUI

/// Main opening screen showing streak, daily progress, and today's challenges.
struct OpeningScreenView: View {
    @ObservedObject var gameEngine: GameEngine
    @State private var showPlayMenu = false
    @State private var showNotificationSettings = false
    
    let completedToday: Int
    let dailyGoal: Int
    let dailyGoalDeadline: Date
    
    var timeRemainingUntilDeadline: TimeInterval {
        max(0, dailyGoalDeadline.timeIntervalSinceNow)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with player name and settings
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !gameEngine.players.isEmpty {
                            Text(gameEngine.players[0].name)
                                .font(.title2.bold())
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showNotificationSettings = true }) {
                        Image(systemName: "gear")
                            .font(.headline)
                            .foregroundStyle(.gray)
                    }
                    .sheet(isPresented: $showNotificationSettings) {
                        NotificationSettingsView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Streak Card
                StreakCardView(metrics: gameEngine.metrics, showMessage: true)
                    .padding(.horizontal, 20)
                
                // Daily Progress
                DailyProgressView(
                    completed: completedToday,
                    goal: dailyGoal,
                    timeRemaining: timeRemainingUntilDeadline
                )
                .padding(.horizontal, 20)
                
                // Today's Challenges
                DailyChallengeView(challenges: gameEngine.dailyChallenges)
                    .padding(.horizontal, 20)
                
                // Last Session Stats (if available)
                if let lastSession = gameEngine.lastSessionStats {
                    LastSessionView(stats: lastSession)
                        .padding(.horizontal, 20)
                }
                
                // Share Progress
                ShareProgressView(
                    levelsPlayed: gameEngine.levelsPlayedTotal,
                    wordsMasteredToday: gameEngine.wordsMasteredToday,
                    totalWordsMastered: gameEngine.totalWordsMastered,
                    playerName: gameEngine.currentPlayerName
                )
                .padding(.horizontal, 20)
                
                // Play Button
                Button(action: { showPlayMenu = true }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Playing")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                Spacer(minLength: 20)
            }
            .padding(.bottom, 20)
        }
        .background(Color(white: 0.98))
        .sheet(isPresented: $showPlayMenu) {
            GameView(engine: gameEngine)
        }
    }
}

/// Displays stats from the previous game session.
private struct LastSessionView: View {
    let stats: SessionStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Session")
                .font(.headline)
            
            HStack(spacing: 20) {
                StatItem(
                    label: "Zombies",
                    value: String(stats.wordsLearned),
                    icon: "figure.walk",
                    color: .green
                )
                
                StatItem(
                    label: "Accuracy",
                    value: String(format: "%.0f%%", stats.accuracy * 100),
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatItem(
                    label: "Words",
                    value: String(stats.wordsLearned),
                    icon: "book.fill",
                    color: .blue
                )
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

/// Single stat item component.
private struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let gameEngine = GameEngine()
    
    OpeningScreenView(
        gameEngine: gameEngine,
        completedToday: 12,
        dailyGoal: 20,
        dailyGoalDeadline: Date().addingTimeInterval(3600)
    )
}
