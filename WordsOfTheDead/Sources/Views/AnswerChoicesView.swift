import SwiftUI

/// Top status bar (upper-left): remaining lives, zombies killed, and progress stats.
struct HUDView: View {
    let lives: Int
    let zombiesKilled: Int
    let level: Int
    let mastered: Int
    let totalWords: Int
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

/// Shows all answer choices simultaneously as a 2-column clickable grid.
/// Players can click any choice directly, or use J to cycle the highlight
/// and SPACE to confirm the highlighted choice.
struct DefinitionTickerView: View {
    let choices: [String]
    let selectedIndex: Int
    var prompt: String = "Click to answer  •  J to cycle  •  Space to confirm"
    let wrong: Bool
    let onGuessChoice: (Int) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 8) {
            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(choices.enumerated()), id: \.offset) { i, choice in
                    choiceCell(text: choice, index: i)
                }
            }
        }
    }

    private func choiceCell(text: String, index: Int) -> some View {
        let isSelected = index == selectedIndex
        let borderColor: Color = (wrong && isSelected) ? Color.red.opacity(0.85)
                               : isSelected            ? Color.green.opacity(0.75)
                               :                         Color.white.opacity(0.18)
        let bgColor: Color = isSelected ? Color.green.opacity(0.18) : Color.white.opacity(0.06)
        return Button(action: { onGuessChoice(index) }) {
            Text(text)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(bgColor))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

/// Shown in the bottom area for synonym levels: six choices, three of which are correct.
/// Correct picks stay highlighted; wrong picks are flagged red and speed the zombie up.
struct SynonymChoicesView: View {
    let choices: [String]
    let correctIndices: Set<Int>
    let selectedIndices: Set<Int>
    let wrongIndices: Set<Int>
    let onSelect: (Int) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10),
                           GridItem(.flexible(), spacing: 10)]

    var body: some View {
        VStack(spacing: 10) {
            Text("Click all the synonyms")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.75))

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    choiceButton(text: choice, index: index)
                }
            }
        }
    }

    private func choiceButton(text: String, index: Int) -> some View {
        let isSelected = selectedIndices.contains(index)
        let isWrong = wrongIndices.contains(index)
        let isCorrect = correctIndices.contains(index)
        let bgColor: Color = isSelected && isCorrect ? .green.opacity(0.24)
            : isWrong ? .red.opacity(0.18)
            : .white.opacity(0.06)
        let borderColor: Color = isWrong ? .red.opacity(0.85)
            : isSelected ? .green.opacity(0.85)
            : .white.opacity(0.18)

        return Button(action: { onSelect(index) }) {
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 58)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(bgColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: isSelected && isCorrect ? .green.opacity(0.45) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }
}

/// Shown in the bottom area on Type 4 levels: two candidate words, chosen with the F key
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
    }
}

/// Shown in the top zone for 3 seconds after a correct answer: the word, its part of
/// speech, and the hand-authored "fun" definition (falling back to the short definition).
/// The vocabulary word within the fun definition is rendered bold and yellow.
struct RevealView: View {
    let word: VocabWord
    var stage: MasteryStage? = nil

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(word.word)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                Text("(\(word.displayPos))")
                    .font(.title3.italic())
                    .foregroundStyle(.white.opacity(0.7))
                if let stage {
                    Text(stage.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(stageColor(stage))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(stageColor(stage).opacity(0.18)))
                        .overlay(Capsule().stroke(stageColor(stage).opacity(0.6), lineWidth: 1))
                }
            }

            Text(highlightedDefinition)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.82))
                .shadow(color: .green.opacity(0.25), radius: 18, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.green.opacity(0.35), lineWidth: 1)
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
