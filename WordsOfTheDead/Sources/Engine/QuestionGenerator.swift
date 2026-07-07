import Foundation

/// A fully-built round of play: the question, which gameplay style it uses, and the
/// text to display on the zombie.
struct Round {
    let question: Question
    let kind: RoundKind
    let prompt: String
}

/// Builds rounds for all four gameplay styles:
///
/// - Definition rounds: one correct definition, two plausible distractors (same part of
///   speech), and one obviously-wrong distractor (different part of speech).
/// - Synonym rounds: four correct synonyms and three related-but-wrong words.
/// - Reverse-definition rounds: the definition is shown, and the player chooses the word.
/// - Fill-in-the-blank rounds: the word's fun definition with the word blanked out, plus
///   two candidate words (the correct one and a plausible distractor).
struct QuestionGenerator {
    let store: VocabularyStore

    // MARK: - Definition rounds (Type 1)

    func makeDefinitionRound(for word: VocabWord) -> Round {
        let question = makeQuestion(for: word)
        return Round(question: question, kind: .definition, prompt: question.word.word)
    }

    // MARK: - Synonym rounds

    /// The zombie displays a vocabulary word; the player must click all four true synonyms
    /// from a seven-choice grid (four synonyms, three related distractors).
    func makeSynonymRound(for word: VocabWord) -> Round {
        guard let entry = store.synonymEntry(for: word),
              entry.synonyms.count >= 4,
              entry.related.count >= 3
        else {
            return makeDefinitionRound(for: word)
        }

        var choices = Array(entry.synonyms.prefix(4)) + Array(entry.related.prefix(3))
        choices.shuffle()

        let correctIndices = Set(choices.enumerated().compactMap { idx, choice in
            entry.synonyms.contains(choice) ? idx : nil
        })
        guard correctIndices.count == 4 else {
            return makeDefinitionRound(for: word)
        }

        let question = Question(
            word: word,
            choices: choices,
            correctIndex: correctIndices.sorted().first ?? 0,
            correctIndices: correctIndices
        )
        return Round(question: question, kind: .synonym, prompt: word.word)
    }

    // MARK: - Reverse-definition rounds (Type 3)

    /// The zombie displays the short definition; the bottom ticker cycles four candidate
    /// WORDS (the correct one plus three distractors, preferring the same part of speech).
    func makeReverseDefinitionRound(for word: VocabWord) -> Round {
        let correct = word.word
        var options: [String] = [correct]

        let samePos = store.allWords
            .filter { $0.pos == word.pos && $0.word.lowercased() != correct.lowercased() }
            .map { $0.word }
        for w in samePos.shuffled() where options.count < 3 {
            if !options.contains(w) { options.append(w) }
        }

        let otherPos = store.allWords
            .filter { $0.pos != word.pos }
            .map { $0.word }
        for w in otherPos.shuffled() where options.count < 4 {
            if !options.contains(w) { options.append(w) }
        }

        if options.count < 4 {
            for w in store.allWords.map({ $0.word }).shuffled() where options.count < 4 {
                if !options.contains(w) { options.append(w) }
            }
        }

        options.shuffle()
        let correctIndex = options.firstIndex(of: correct) ?? 0
        let question = Question(word: word, choices: options, correctIndex: correctIndex, correctIndices: [correctIndex])
        return Round(question: question, kind: .reverseDefinition, prompt: word.shortDefinition)
    }

    func makeQuestion(for word: VocabWord) -> Question {
        let correct = word.shortDefinition
        var options: [String] = [correct]

        // Two plausible distractors share the part of speech.
        let plausiblePool = store.allWords
            .filter { $0.pos == word.pos && $0.shortDefinition != correct }
            .map { $0.shortDefinition }
        for def in plausiblePool.shuffled() where options.count < 3 {
            if !options.contains(def) { options.append(def) }
        }

        // One obvious distractor comes from a different part of speech.
        let obviousPool = store.allWords
            .filter { $0.pos != word.pos }
            .map { $0.shortDefinition }
        for def in obviousPool.shuffled() where options.count < 4 {
            if !options.contains(def) { options.append(def) }
        }

        // Fallback: top up from the entire pool if anything is still short.
        if options.count < 4 {
            for def in store.allWords.map({ $0.shortDefinition }).shuffled() where options.count < 4 {
                if !options.contains(def) { options.append(def) }
            }
        }

        options.shuffle()
        let correctIndex = options.firstIndex(of: correct) ?? 0
        return Question(word: word, choices: options, correctIndex: correctIndex, correctIndices: [correctIndex])
    }

    // MARK: - Fill-in-the-blank rounds (Type 4)

    func makeFillBlankRound(for word: VocabWord) -> Round {
        // Blank the word out of its fun definition; fall back to a definition round if
        // (rarely) the word cannot be located in its sentence.
        guard let fun = word.funDefinition,
              let blanked = Self.blankOut(word.word, in: fun),
              let distractor = distractorWord(for: word, excluding: blanked.surface)
        else {
            return makeDefinitionRound(for: word)
        }

        // The correct choice must match the exact form used in the sentence (e.g. the
        // sentence may say "abetted" even though the listed word is "abet").
        let correct = blanked.surface
        var options = [correct, distractor]
        options.shuffle()
        let correctIndex = options.firstIndex(of: correct) ?? 0
        let question = Question(word: word, choices: options, correctIndex: correctIndex, correctIndices: [correctIndex])
        return Round(question: question, kind: .fillBlank, prompt: blanked.sentence)
    }

    /// Picks a plausible but incorrect word, preferring the same part of speech. Kept as a
    /// real dictionary word (not an invented inflection) so it never looks broken.
    private func distractorWord(for word: VocabWord, excluding correctSurface: String) -> String? {
        let target = word.word.lowercased()
        let correct = correctSurface.lowercased()
        let samePos = store.allWords.filter {
            $0.pos == word.pos && $0.word.lowercased() != target && $0.word.lowercased() != correct
        }
        if let pick = samePos.randomElement() { return pick.word }
        return store.allWords
            .filter { $0.word.lowercased() != target && $0.word.lowercased() != correct }
            .randomElement()?.word
    }

    /// Replaces the first occurrence of `word` (allowing common inflected forms) in
    /// `text` with a blank. Returns the blanked sentence together with the exact surface
    /// form that was removed (e.g. "abetted"), or nil if the word cannot be found.
    static func blankOut(_ word: String, in text: String) -> (sentence: String, surface: String)? {
        let blank = "_____"
        let escaped = NSRegularExpression.escapedPattern(for: word)

        // Try the exact word with optional trailing letters (plurals, -ed, -ing, -ly...).
        if let result = replaceFirst("\\b\(escaped)[a-zA-Z]*\\b", in: text, with: blank) {
            return result
        }

        // Fall back to a stem match for forms with altered endings (e.g. "ostensible"
        // appearing as "ostensibly").
        let lower = word.lowercased()
        for trim in [2, 3] where lower.count - trim >= 4 {
            let stem = String(lower.dropLast(trim))
            let stemEscaped = NSRegularExpression.escapedPattern(for: stem)
            if let result = replaceFirst("\\b\(stemEscaped)[a-zA-Z]*\\b", in: text, with: blank) {
                return result
            }
        }
        return nil
    }

    private static func replaceFirst(_ pattern: String, in text: String, with replacement: String) -> (sentence: String, surface: String)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let matchRange = Range(match.range, in: text)
        else { return nil }
        // Preserve the form as written, but normalize a sentence-initial capital so the
        // choice button doesn't reveal the answer's position.
        let surface = decapitalizeIfSentenceInitial(String(text[matchRange]))
        let sentence = text.replacingCharacters(in: matchRange, with: replacement)
        return (sentence, surface)
    }

    /// Lowercases the first letter unless the word looks like a proper noun (more than one
    /// capital letter), so "Abetted" at the start of a sentence becomes "abetted".
    private static func decapitalizeIfSentenceInitial(_ word: String) -> String {
        let capitals = word.filter { $0.isUppercase }.count
        guard capitals == 1, let first = word.first, first.isUppercase else { return word }
        return first.lowercased() + word.dropFirst()
    }
}
