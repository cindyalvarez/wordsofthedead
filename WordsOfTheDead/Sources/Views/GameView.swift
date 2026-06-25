import SwiftUI

/// Root view: routes between the start screen, active game, and game-over screen.
struct GameView: View {
    @ObservedObject var engine: GameEngine
    @State private var showDiagnosticsExport = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.10),
                         Color(red: 0.10, green: 0.13, blue: 0.11)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            switch engine.phase {
            case .playerSelect:
                PlayerSelectView(engine: engine)
            case .start:
                StartView(engine: engine)
            case .levelIntro:
                LevelIntroView(level: engine.level,
                               isBoss: engine.isBossLevel,
                               instruction: engine.levelInstruction)
            case .playing, .revealing:
                PlayfieldView(engine: engine)
            case .gameOver:
                GameOverView(engine: engine)
            }
        }
        .sheet(isPresented: $showDiagnosticsExport) {
            DiagnosticsExportView()
        }
    }
}

private struct LevelIntroView: View {
    let level: Int
    var isBoss: Bool = false
    var instruction: String = ""

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            if isBoss {
                Text("☠️ BOSS REVIEW")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.red)
                Text("Only the words you've struggled with — and they're faster!")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            } else {
                Text("Level")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text("\(level)")
                .font(.system(size: 120, weight: .heavy, design: .rounded))
                .foregroundStyle(isBoss ? .red : .green)
                .shadow(color: (isBoss ? Color.red : Color.green).opacity(0.7), radius: 18)

            if !instruction.isEmpty {
                Text(instruction)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 4)
                Text("A wrong guess speeds the zombie up.  Press P to pause.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
        }
    }
}

private struct PlayerSelectView: View {
    @ObservedObject var engine: GameEngine

    @State private var newName: String = ""
    @State private var addingNew: Bool = false
    @FocusState private var nameFieldFocused: Bool

    private var showEntry: Bool { !engine.hasSavedPlayers || addingNew }

    var body: some View {
        VStack(spacing: 26) {
            Text("🧟 Words of the Dead")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(.green)

            if showEntry {
                nameEntry
            } else {
                returningPlayers
            }
        }
        .frame(maxWidth: 520)
        .onAppear { nameFieldFocused = showEntry }
    }

    private var nameEntry: some View {
        VStack(spacing: 16) {
            Text(engine.hasSavedPlayers ? "New player" : "Welcome! What's your name?")
                .font(.title2.bold())
                .foregroundStyle(.white.opacity(0.9))

            TextField("Enter your name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .frame(width: 320)
                .focused($nameFieldFocused)
                .onSubmit(create)

            Button(action: create) {
                Text("Start")
                    .font(.title2.bold())
                    .frame(width: 220)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)

            if engine.hasSavedPlayers {
                Button("Back") { addingNew = false; nameFieldFocused = false }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var returningPlayers: some View {
        VStack(spacing: 18) {
            Text("Who's playing?")
                .font(.title2.bold())
                .foregroundStyle(.white.opacity(0.9))

            VStack(spacing: 12) {
                ForEach(engine.savedPlayers) { player in
                    Button(action: { engine.continueAs(player) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.title3.bold())
                                Text("Best: Level \(player.bestLevel) · \(player.bestScore) pts")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .frame(width: 360)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green.opacity(0.85))
                }
            }

            Button(action: { newName = ""; addingNew = true; nameFieldFocused = true }) {
                Text("➕ New Player")
                    .font(.title3.bold())
                    .frame(width: 220)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
        }
    }

    private func create() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        engine.createPlayer(named: name)
        newName = ""
        addingNew = false
    }
}

private struct StartView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 24) {
            Text("🧟 Words of the Dead")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .foregroundStyle(.green)

            if !engine.currentPlayerName.isEmpty {
                HStack(spacing: 12) {
                    Text("Player: \(engine.currentPlayerName)")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                    Button("Switch") { engine.switchPlayer() }
                        .buttonStyle(.bordered)
                        .tint(.gray)
                        .controlSize(.small)
                }
            }

            DailyStreakView(engine: engine)

            if engine.hasContent {
                VStack(spacing: 14) {
                    Button(action: { engine.startGame() }) {
                        Text("Start Game")
                            .font(.title2.bold())
                            .frame(width: 220)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: { engine.startGame(testMode: true) }) {
                        Text("Test Mode")
                            .font(.title3.bold())
                            .frame(width: 220)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    Text("Test Mode advances to the next level after just 1 word.")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.55))
                }
            } else {
                Text("⚠️ Vocabulary data could not be loaded.")
                    .foregroundStyle(.red)
            }
        }
    }
}

/// Daily goal + consecutive-day streak with a small 7-day activity calendar (suggestion #7).
private struct DailyStreakView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 18) {
                Text("🔥 Day streak: \(engine.dayStreak)")
                    .foregroundStyle(.orange)
                Text("Today: \(engine.todayCount) / \(engine.dailyGoal) words")
                    .foregroundStyle(engine.todayCount >= engine.dailyGoal ? .green : .white.opacity(0.8))
            }
            .font(.headline.bold())

            HStack(spacing: 10) {
                ForEach(engine.recentDays(7)) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(day.met ? Color.green : Color.white.opacity(0.15))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle().stroke(day.isToday ? Color.yellow : Color.clear, lineWidth: 2)
                            )
                        Text(day.label)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 22)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.25)))
    }
}

private struct GameOverView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 20) {
            Text("☠️ You Were Overrun")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundStyle(.red)

            VStack(spacing: 12) {
                summaryRow("Final Score", "\(engine.score)", .white)
                summaryRow("Zombies Killed", "\(engine.zombiesKilled)", .green)
                summaryRow("Accuracy", String(format: "%.0f%%", engine.runAccuracy * 100), .cyan)
                summaryRow("Best Streak", "\(engine.runBestStreak)", .orange)
                summaryRow("Newly Mastered", "\(engine.runNewlyMastered)", .yellow)
                summaryRow("Words to Review", "\(engine.runMissed)", .red)
            }
            .font(.title3.bold())
            .padding(.vertical, 18)
            .padding(.horizontal, 34)
            .background(RoundedRectangle(cornerRadius: 14).fill(.black.opacity(0.3)))

            DailyStreakView(engine: engine)

            Button(action: { engine.startGame() }) {
                Text("Play Again")
                    .font(.title2.bold())
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    private func summaryRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.white.opacity(0.75))
            Spacer(minLength: 40)
            Text(value)
                .foregroundStyle(color)
        }
        .frame(width: 320)
    }
}
