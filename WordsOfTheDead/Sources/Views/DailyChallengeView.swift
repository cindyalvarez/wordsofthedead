import SwiftUI

/// Displays the 3 daily rotating challenges with completion status.
struct DailyChallengeView: View {
    let challenges: [DailyChallenge]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Challenges")
                    .font(.headline)
                
                Spacer()
                
                Text("\(challenges.filter { $0.isCompleted }.count)/\(challenges.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 10) {
                ForEach(challenges) { challenge in
                    ChallengeRowView(challenge: challenge)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

/// Individual challenge row with completion checkbox.
private struct ChallengeRowView: View {
    let challenge: DailyChallenge
    
    var icon: String {
        challenge.isCompleted ? "checkmark.circle.fill" : "circle"
    }
    
    var iconColor: Color {
        challenge.isCompleted ? .green : .gray.opacity(0.5)
    }
    
    var textColor: Color {
        challenge.isCompleted ? .secondary : .primary
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(textColor)
                
                Text(challenge.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if challenge.isCompleted {
                Text("✓")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(challenge.isCompleted ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

#Preview {
    let challenges = [
        DailyChallenge(
            id: "learn-3-words",
            title: "Learn 3 Words",
            description: "Master 3 new words in a session",
            reward: "+2 XP"
        ),
        DailyChallenge(
            id: "high-accuracy",
            title: "High Accuracy",
            description: "Maintain 85%+ accuracy",
            reward: "+3 XP"
        ),
        DailyChallenge(
            id: "extend-streak",
            title: "Extend Streak",
            description: "Complete a study session",
            reward: "+5 XP"
        )
    ]
    
    DailyChallengeView(challenges: challenges)
        .padding()
}
