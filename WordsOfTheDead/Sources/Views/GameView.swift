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
            case .cutscene:
                CutsceneView(engine: engine)
            case .start:
                StartView(engine: engine)
            case .levelIntro:
                LevelIntroView(level: engine.level,
                               isBoss: engine.isBossLevel,
                               instruction: engine.levelInstruction,
                               bombEarned: engine.bombEarnedThisLevel)
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
    var bombEarned: Bool = false

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

            if bombEarned {
                VStack(spacing: 6) {
                    Text("💣 ZOMBIE BOMB EARNED!")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Click the 💣 in the HUD to blast all zombies off the screen — one time only!")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.black.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.orange.opacity(0.65), lineWidth: 1.5)
                )
                .shadow(color: .orange.opacity(0.3), radius: 12)
                .padding(.top, 8)
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
                                Text("Best: Level \(player.bestLevel)")
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

    @State private var appeared = false
    @State private var pulseGlow = false
    @State private var zombieOffset: CGFloat = 0
    @State private var showContent = false
    @State private var newName: String = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            // Vignette/fog treatment inspired by game-over.
            RadialGradient(colors: [.clear, Color.black.opacity(0.68)],
                           center: .center, startRadius: 100, endRadius: 540)
                .ignoresSafeArea()

            zombieParade
                .opacity(appeared ? 0.28 : 0)

            VStack(spacing: 0) {
                Spacer().frame(height: 30)

                // Dramatic title treatment.
                VStack(spacing: 6) {
                    Text("WORDS OF THE DEAD")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.green, Color(red: 0.18, green: 0.66, blue: 0.24)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .shadow(color: .green.opacity(pulseGlow ? 0.78 : 0.30), radius: pulseGlow ? 24 : 10)
                        .multilineTextAlignment(.center)
                    Text("SURVIVE THE VOCABULARY ONSLAUGHT")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.58))
                }
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)

                Spacer().frame(height: 18)

                if engine.currentPlayer == nil {
                    // No player yet — show an inline name-entry form.
                    nameEntryBlock
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 16)
                } else {
                    // Returning player — show identity bar, stats, streak, and start button.

                    // Player identity bar.
                    if !engine.currentPlayerName.isEmpty {
                        playerBar
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 12)
                    }

                    Spacer().frame(height: 16)

                    // Stats overview — personal bests + mastery.
                    statsStrip
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 12)

                    Spacer().frame(height: 16)

                    // Daily streak.
                    DailyStreakView(engine: engine)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 12)

                    Spacer().frame(height: 20)

                    // Action buttons.
                    if engine.hasContent {
                        buttonsBlock
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 16)
                    } else {
                        Text("⚠️ Vocabulary data could not be loaded.")
                            .foregroundStyle(.red)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulseGlow = true }
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { zombieOffset = 1 }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                showContent = true
                if engine.currentPlayer == nil { nameFieldFocused = true }
            }
        }
    }

    // MARK: - Sub-views

    /// Shown when no player has been created yet. Styled to sit comfortably over the
    /// animated start-screen background.
    private var nameEntryBlock: some View {
        VStack(spacing: 16) {
            Text("Welcome! What's your name?")
                .font(.title2.bold())
                .foregroundStyle(.white.opacity(0.9))

            TextField("Enter your name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .frame(width: 320)
                .focused($nameFieldFocused)
                .onSubmit(createPlayer)

            Button(action: createPlayer) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                    Text("Begin")
                }
                .font(.title2.bold())
                .frame(width: 240)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.48))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
    }

    private func createPlayer() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        engine.createPlayer(named: name)
    }

    private var playerBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .foregroundStyle(.green.opacity(0.7))
            Text(engine.currentPlayerName)
                .font(.headline.bold())
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Button(action: { engine.switchPlayer() }) {
                Text("Switch")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            .controlSize(.small)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.06)))
        .padding(.horizontal, 30)
    }

    private var statsStrip: some View {
        let player = engine.currentPlayer!
        return HStack(spacing: 0) {
            miniStat(value: "\(player.bestLevel)", label: "Best Level", color: .green)
            miniDivider
            miniStat(value: "\(engine.totalWordsMastered)", label: "Mastered", color: .yellow)
            miniDivider
            miniStat(value: "\(engine.totalWords)", label: "Total Words", color: .white.opacity(0.6))
        }
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.3)))
        .padding(.horizontal, 30)
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    private var miniDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.1))
            .frame(width: 1, height: 30)
    }

    private var buttonsBlock: some View {
        VStack(spacing: 14) {
            Button(action: { engine.startGame() }) {
                HStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                    Text("Start Game")
                }
                .font(.title2.bold())
                .frame(width: 240)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Button(action: { engine.startGame(testMode: true) }) {
                HStack(spacing: 8) {
                    Image(systemName: "flask")
                    Text("Test Mode")
                }
                .font(.title3.bold())
                .frame(width: 240)
                .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.orange)

            Text("Test Mode advances to the next level after just 1 word.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.45))

            Text("Press P to pause the game at any time.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.38))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 30)
    }

    /// A row of shambling zombie silhouettes that drift slowly across the screen.
    private var zombieParade: some View {
        GeometryReader { geo in
            let count = 6
            let spacing = geo.size.width / CGFloat(count)
            let totalTravel = geo.size.width + spacing
            ForEach(0..<count, id: \.self) { i in
                let kind = ZombieKind.allCases[i % ZombieKind.allCases.count]
                let baseX = CGFloat(i) * spacing
                let x = ((baseX + zombieOffset * totalTravel)
                    .truncatingRemainder(dividingBy: totalTravel)) - spacing * 0.5
                let y = geo.size.height * (0.56 + 0.07 * sin(Double(i) * 1.4))
                ZombieFigure(kind: kind, wrong: false)
                    .frame(width: 56, height: 84)
                    .rotationEffect(.degrees(Double(i % 2 == 0 ? 4 : -4)))
                    .position(x: x, y: y)
            }
        }
    }
}

/// Daily goal + consecutive-day streak with a small 7-day activity calendar.
private struct DailyStreakView: View {
    @ObservedObject var engine: GameEngine
    @State private var flameWiggle = false

    private var showDayStreak: Bool { engine.dayStreak >= 2 }
    private var goalMet: Bool { engine.todayCount >= engine.dailyGoal }
    private var progress: Double {
        guard engine.dailyGoal > 0 else { return 0 }
        return min(1.0, Double(engine.todayCount) / Double(engine.dailyGoal))
    }

    var body: some View {
        VStack(spacing: 12) {
            // Streak headline.
            HStack(spacing: 6) {
                Text(showDayStreak ? "🔥" : "🎯")
                    .font(.title2)
                    .rotationEffect(.degrees(flameWiggle ? 6 : -6))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            flameWiggle = true
                        }
                    }
                Text(showDayStreak ? "\(engine.dayStreak) day streak" : "Daily goal")
                    .font(.headline.bold())
                    .foregroundStyle(showDayStreak ? .orange : .white.opacity(0.9))

                Spacer()

                Text("\(engine.todayCount)/\(engine.dailyGoal)")
                    .font(.headline.bold().monospacedDigit())
                    .foregroundStyle(goalMet ? .green : .white.opacity(0.85))
                Text("today")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Progress bar.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                    Capsule()
                        .fill(goalMet
                              ? LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                              : LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)

            // 7-day calendar dots.
            HStack(spacing: 10) {
                ForEach(engine.recentDays(7)) { day in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(day.met ? Color.green : Color.white.opacity(0.12))
                                .frame(width: 18, height: 18)
                            if day.met {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundStyle(.black.opacity(0.6))
                            }
                        }
                        .overlay(
                            Circle().stroke(day.isToday ? Color.yellow : Color.clear, lineWidth: 2)
                                .frame(width: 22, height: 22)
                        )
                        Text(day.label)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 22)
        .background(RoundedRectangle(cornerRadius: 12).fill(.black.opacity(0.3)))
        .padding(.horizontal, 30)
    }
}

private struct GameOverView: View {
    @ObservedObject var engine: GameEngine

    @State private var appeared = false
    @State private var statsRevealed = false
    @State private var zombieOffset: CGFloat = 0
    @State private var pulseGlow = false
    @State private var showPlayAgain = false

    /// A flavour headline that reacts to how the player did.
    private var headline: String {
        if engine.zombiesKilled == 0 { return "DEVOURED INSTANTLY" }
        if engine.level >= 10 { return "LEGENDARY FALL" }
        if engine.zombiesKilled >= 20 { return "HEROIC LAST STAND" }
        if engine.runAccuracy >= 0.9 { return "SO CLOSE…" }
        return "DEVOURED"
    }

    private var subtitleLines: [String] {
        var lines: [String] = []
        if engine.runNewlyMastered > 0 {
            lines.append("You permanently learned \(engine.runNewlyMastered) word\(engine.runNewlyMastered == 1 ? "" : "s") — the undead can never take that from you.")
        }
        if engine.runMissed > 0 {
            lines.append("\(engine.runMissed) word\(engine.runMissed == 1 ? "" : "s") to review — they'll come back to haunt you.")
        }
        return lines
    }

    var body: some View {
        ZStack {
            // Fog / vignette overlay.
            RadialGradient(colors: [.clear, Color.black.opacity(0.7)],
                           center: .center, startRadius: 100, endRadius: 500)
                .ignoresSafeArea()

            // Shambling zombie silhouettes behind the stats.
            zombieParade
                .opacity(appeared ? 0.35 : 0)

            VStack(spacing: 0) {
                Spacer().frame(height: 30)

                // Dramatic headline.
                Text(headline)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.red, Color(red: 0.6, green: 0.0, blue: 0.0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .red.opacity(pulseGlow ? 0.8 : 0.3), radius: pulseGlow ? 24 : 10)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)

                // Subtitle / flavour text.
                VStack(spacing: 6) {
                    ForEach(Array(subtitleLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.callout.bold())
                            .foregroundStyle(line.hasPrefix("🏆") ? .yellow : .white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 8)
                .opacity(statsRevealed ? 1 : 0)

                Spacer().frame(height: 24)

                // Stats — tombstone-styled card.
                statsCard
                    .opacity(statsRevealed ? 1 : 0)
                    .offset(y: statsRevealed ? 0 : 30)

                Spacer().frame(height: 18)

                DailyStreakView(engine: engine)
                    .opacity(statsRevealed ? 1 : 0)

                Spacer().frame(height: 22)

                if showPlayAgain {
                    Button(action: { engine.startGame() }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Rise Again")
                        }
                        .font(.title2.bold())
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulseGlow = true }
            withAnimation(.easeOut(duration: 0.7).delay(0.5)) { statsRevealed = true }
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) { showPlayAgain = true }
            // Slow shamble drift.
            withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                zombieOffset = 1
            }
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 0) {
            // "R.I.P." header strip.
            Text("R.I.P.")
                .font(.system(size: 14, weight: .heavy, design: .serif))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))

            VStack(spacing: 14) {
                // Hero stat — zombies killed.
                VStack(spacing: 2) {
                    Text("\(engine.zombiesKilled)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(.green)
                    Text("ZOMBIES KILLED")
                        .font(.caption.bold())
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.top, 10)

                // Secondary stats in a 2-column grid.
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCell("Reached Level", "\(engine.level)", .white)
                    statCell("Accuracy", String(format: "%.0f%%", engine.runAccuracy * 100), .cyan)
                    statCell("Best Streak", "\(engine.runBestStreak)", .orange)
                    statCell("Newly Mastered", "\(engine.runNewlyMastered)", .yellow)
                    statCell("Words to Review", "\(engine.runMissed)", .red)
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 22)
        }
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Zombie Parade

    /// A row of shambling zombie silhouettes that drift slowly across the screen.
    private var zombieParade: some View {
        GeometryReader { geo in
            let count = 6
            let spacing = geo.size.width / CGFloat(count)
            let totalTravel = geo.size.width + spacing
            ForEach(0..<count, id: \.self) { i in
                let kind = ZombieKind.allCases[i % ZombieKind.allCases.count]
                let baseX = CGFloat(i) * spacing
                // Each zombie starts at a staggered horizontal position and drifts rightward.
                let x = ((baseX + zombieOffset * totalTravel)
                    .truncatingRemainder(dividingBy: totalTravel)) - spacing * 0.5
                let y = geo.size.height * (0.55 + 0.08 * sin(Double(i) * 1.3))
                ZombieFigure(kind: kind, wrong: false)
                    .frame(width: 60, height: 90)
                    .rotationEffect(.degrees(Double(i % 2 == 0 ? 4 : -4)))
                    .position(x: x, y: y)
            }
        }
    }
}
