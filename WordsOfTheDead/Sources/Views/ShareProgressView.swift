import SwiftUI

/// A view for sharing the player's progress via email.
/// Displays stats (levels played, words mastered today, total mastered) and
/// allows the user to enter an email address to share with.
struct ShareProgressView: View {
    @State private var showShareSheet = false
    @State private var emailAddress = "cindy.alvarez@gmail.com"
    @State private var editingEmail = false
    
    let levelsPlayed: Int
    let wordsMasteredToday: Int
    let totalWordsMastered: Int
    let playerName: String
    
    var shareMessage: String {
        """
        I'm playing Words of the Dead and making great progress! 🧟‍♂️

        Today's Stats:
        • Levels played: \(levelsPlayed)
        • Words mastered today: \(wordsMasteredToday)
        • Total words mastered: \(totalWordsMastered)

        Join me and learn words while fighting zombies!
        """
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Share Progress")
                .font(.headline)
            
            // Stats Display
            VStack(alignment: .leading, spacing: 10) {
                StatRow(
                    label: "Levels Played",
                    value: String(levelsPlayed),
                    icon: "arrow.up",
                    color: .blue
                )
                
                StatRow(
                    label: "Words Mastered Today",
                    value: String(wordsMasteredToday),
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatRow(
                    label: "Total Words Mastered",
                    value: String(totalWordsMastered),
                    icon: "book.fill",
                    color: .green
                )
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Share Section
            if editingEmail {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send to:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Email address", text: $emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    
                    HStack(spacing: 8) {
                        Button(action: { editingEmail = false }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .foregroundStyle(.primary)
                                .cornerRadius(6)
                        }
                        
                        Button(action: shareProgress) {
                            Text("Send")
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            } else {
                Button(action: { editingEmail = true }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Share Progress")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func shareProgress() {
        // Log the share action (could be expanded to send email, post to service, etc.)
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        FileUtilities.log(
            "Progress shared to \(emailAddress): \(levelsPlayed) levels, \(wordsMasteredToday) today, \(totalWordsMastered) total at \(timestamp)",
            category: "share"
        )
        
        // Reset the form
        editingEmail = false
        emailAddress = "cindy.alvarez@gmail.com"
        
        // Show brief confirmation (could use a Toast or Alert here)
    }
}

/// Single stat row component for the share progress card.
private struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.title3.bold())
            }
            
            Spacer()
        }
    }
}

#Preview {
    ShareProgressView(
        levelsPlayed: 15,
        wordsMasteredToday: 5,
        totalWordsMastered: 87,
        playerName: "Test Player"
    )
    .padding()
}
