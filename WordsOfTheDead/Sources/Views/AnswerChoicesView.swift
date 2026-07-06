import SwiftUI

/// Top status bar (upper-left): remaining lives and zombies killed, plus a transient
/// streak banner when the player earns a bonus life.
struct HUDView: View {
    let lives: Int
    let zombiesKilled: Int
    let level: Int
    let mastered: Int
    let totalWords: Int
    let showStreak: Bool
    let score: Int
    let comboMultiplier: Double
    let isBoss: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Zombies Killed: \(zombiesKilled)")
                    .foregroundStyle(.green)
                HStack(spacing: 10) {
                    Text("Level: \(level)")
                        .foregroundStyle(.cyan)
                    if isBoss {
                        Text("☠️ BOSS")
                            .font(.headline.bold())
                            .foregroundStyle(.red)
                    }
                }
            }

            if showStreak {
                Text("🔥 STREAK – you got a new life!")
                    .font(.title3.bold())
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.black.opacity(0.5)))
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("Score: \(score)")
                    .foregroundStyle(.white)
                if comboMultiplier > 1.0 {
                    Text(String(format: "Combo ×%.2f", comboMultiplier))
                        .font(.headline.bold())
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Lives: \(lives)")
                    .foregroundStyle(.red)
                Text("Mastered: \(mastered) / \(totalWords)")
                    .foregroundStyle(.yellow)
            }
        }
        .font(.title3.bold())
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.black.opacity(0.3))
        .animation(.spring(response: 0.3), value: showStreak)
    }
}

/// Shown in the bottom area for the duration of the reveal after a correct answer.
struct CorrectBannerView: View {
    var body: some View {
        Text("CORRECT")
            .font(.system(size: 48, weight: .heavy, design: .rounded))
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.green.opacity(0.10))
            )
    }
}

/// Shows a single definition at a time. The player presses SPACE to answer while the
/// correct one is on screen, or J to manually cycle through the other options.
struct DefinitionTickerView: View {
    let text: String
    var prompt: String = "Press  SPACE  to answer or  J  to cycle"
    let wrong: Bool
    let onGuess: () -> Void
    let onCycle: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(text)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(wrong ? Color.red.opacity(0.8) : Color.green.opacity(0.5),
                                lineWidth: 2)
                )
                .id(text)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: text)

            HStack(spacing: 16) {
                Button(action: onCycle) {
                    Text("J: Next")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                       .padding(.vertical, 10)
                        .background(Capsule().fill(.orange))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("j", modifiers: [])
                
                Button(action: onGuess) {
                    Text("SPACE: Answer")
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.green))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.space, modifiers: [])
            }
        }
    }
}

/// Shown in the bottom area on even levels: two candidate words, chosen with the F key
/// (left word) or the J key (right word).
struct FillBlankChoicesView: View {
    let leftWord: String
    let rightWord: String
    let wrong: Bool
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("Complete the sentence — press  F  or  J")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 28) {
                choiceButton(key: "F", word: leftWord, isLeft: true)
                choiceButton(key: "J", word: rightWord, isLeft: false)
            }
        }
    }

    private func choiceButton(key: String, word: String, isLeft: Bool) -> some View {
        Button(action: { onAnswer(isLeft) }) {
            VStack(spacing: 10) {
                Text(key)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.green))
                Text(word)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(wrong ? Color.red.opacity(0.8) : Color.green.opacity(0.5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character(key.lowercased())), modifiers: [])
    }
}

/// Shown in the top zone for 3 seconds after a correct answer: the word, its part of
/// speech, and the hand-authored "fun" definition (falling back to the short definition).
/// The vocabulary word within the fun definition is rendered bold and yellow.
struct RevealView: View {
    let word: VocabWord
    var stage: MasteryStage? = nil

    var body: some View {
        VStack(spacing: 22) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(word.word)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                Text("(\(word.displayPos))")
                    .font(.title.italic())
                    .foregroundStyle(.white.opacity(0.7))
                if let stage {
                    Text(stage.label)
                        .font(.headline.bold())
                        .foregroundStyle(stageColor(stage))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(stageColor(stage).opacity(0.18)))
                        .overlay(Capsule().stroke(stageColor(stage).opacity(0.6), lineWidth: 1))
                }
            }

            // Fun definition: left-justified, wrapped to a comfortable ~50-75 char reading
            // width. The fixed-width block is centered, giving equal left/right margins.
            // The vocabulary word itself is highlighted bold + yellow.
            Text(highlightedDefinition)
                .font(.system(size: 23))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
                .frame(maxWidth: 660, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.black.opacity(0.35))
        )
    }

    private func stageColor(_ stage: MasteryStage) -> Color {
        switch stage {
        case .new: return .cyan
        case .learning: return .orange
        case .known: return .green
        }
    }

    /// Builds the fun definition with the vocabulary word (and common inflections)
    /// styled bold + yellow. For 8th-grade (tier-0) words, uses only the short definition.
    private var highlightedDefinition: AttributedString {
        let text = (word.tier == 0 ? nil : word.funDefinition) ?? word.shortDefinition
        var attributed = AttributedString(text)

        for range in matchRanges(of: word.word, in: text) {
            if let lo = AttributedString.Index(range.lowerBound, within: attributed),
               let hi = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[lo..<hi].foregroundColor = .yellow
                attributed[lo..<hi].font = .system(size: 23, weight: .bold)
            }
        }
        return attributed
    }

    private func matchRanges(of word: String, in text: String) -> [Range<String.Index>] {
        let escaped = NSRegularExpression.escapedPattern(for: word)
        var patterns = ["\\b\(escaped)[a-zA-Z]*\\b"]
        let lower = word.lowercased()
        for trim in [2, 3] where lower.count - trim >= 4 {
            let stem = NSRegularExpression.escapedPattern(for: String(lower.dropLast(trim)))
            patterns.append("\\b\(stem)[a-zA-Z]*\\b")
        }

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
            let matches = regex.matches(in: text, options: [], range: nsRange)
            if !matches.isEmpty {
                return matches.compactMap { Range($0.range, in: text) }
            }
        }
        return []
    }
}
