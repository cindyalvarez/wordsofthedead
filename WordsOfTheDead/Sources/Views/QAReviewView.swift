import SwiftUI

/// QA review mode (launched with `--qa`): shows every fun sentence 20 at a time with a
/// checkbox to flag flaws, then offers suggested corrections that feed back into gameplay.
struct QAReviewView: View {
    @StateObject private var store = FunSentenceStore()
    @State private var page = 0
    @State private var reviewing = false
    @State private var savedCount: Int? = nil

    private let perPage = 10

    private var pageCount: Int {
        max(1, Int(ceil(Double(store.items.count) / Double(perPage))))
    }

    private var pageRange: Range<Int> {
        let start = page * perPage
        let end = min(start + perPage, store.items.count)
        return start..<max(start, end)
    }

    private var flaggedCount: Int { store.items.filter { $0.flagged }.count }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if reviewing {
                CorrectionView(store: store,
                               onBack: { reviewing = false },
                               onSaved: { count in
                                   savedCount = count
                                   reviewing = false
                               })
            } else {
                reviewList
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .preferredColorScheme(.light)
    }

    private var reviewList: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(pageRange, id: \.self) { idx in
                        SentenceRow(item: $store.items[idx])
                        Divider().background(.black.opacity(0.12))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 8)
            }

            footer
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("🧟 Fun Sentence QA Review")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.5, blue: 0.15))
            Text("Check the box next to any sentence that is incorrect, doesn't make sense, or is incomplete.")
                .font(.headline)
                .foregroundStyle(.black.opacity(0.7))
            if let savedCount {
                Text("✅ Saved \(savedCount) correction\(savedCount == 1 ? "" : "s") — they will appear in gameplay.")
                    .font(.callout.bold())
                    .foregroundStyle(Color(red: 0.12, green: 0.5, blue: 0.15))
            }
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.93))
    }

    private var footer: some View {
        HStack(spacing: 20) {
            Button(action: { if page > 0 { page -= 1 } }) {
                Label("Previous", systemImage: "arrow.left")
            }
            .disabled(page == 0)

            Text("Page \(page + 1) of \(pageCount)")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(minWidth: 140)

            Button(action: { if page < pageCount - 1 { page += 1 } }) {
                Label("Next", systemImage: "arrow.right")
            }
            .disabled(page >= pageCount - 1)

            Spacer()

            Text("\(flaggedCount) flagged")
                .foregroundStyle(.orange)

            Button(action: { startReview() }) {
                Text("Review flagged & correct")
                    .bold()
                    .padding(.horizontal, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(flaggedCount == 0)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Color(white: 0.93))
    }

    private func startReview() {
        // Seed each flagged item's editable suggestion with a best-guess correction.
        for i in store.items.indices where store.items[i].flagged {
            if store.items[i].suggestion.isEmpty {
                store.items[i].suggestion = FunSentenceStore.suggestCorrection(
                    for: store.items[i].current, word: store.items[i].word)
            }
        }
        savedCount = nil
        reviewing = true
    }
}

private struct SentenceRow: View {
    @Binding var item: FunSentenceItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Toggle("", isOn: $item.flagged)
                .toggleStyle(.checkbox)
                .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                Text(item.word)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.5, blue: 0.15))
                Text(item.current)
                    .font(.system(size: 22))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }
}

/// Correction step: lists each flagged sentence with an editable suggested correction.
private struct CorrectionView: View {
    @ObservedObject var store: FunSentenceStore
    let onBack: () -> Void
    let onSaved: (Int) -> Void

    private var flaggedIndices: [Int] {
        store.items.indices.filter { store.items[$0].flagged }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Suggested Corrections")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.orange)
                Text("Accept the suggested fix or edit it yourself, then save. Saved sentences are used in gameplay.")
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.93))

            ScrollView {
                VStack(spacing: 18) {
                    ForEach(flaggedIndices, id: \.self) { idx in
                        CorrectionRow(item: $store.items[idx])
                    }
                }
                .padding(28)
            }

            HStack(spacing: 20) {
                Button(action: onBack) {
                    Label("Back to list", systemImage: "arrow.left")
                }
                Spacer()
                Button(action: { onSaved(store.saveCorrections()) }) {
                    Text("Save corrections")
                        .bold()
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Color(white: 0.93))
        }
    }
}

private struct CorrectionRow: View {
    @Binding var item: FunSentenceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.word)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.5, blue: 0.15))

            Text("Original:")
                .font(.caption.bold())
                .foregroundStyle(.black.opacity(0.5))
            Text(item.current)
                .font(.system(size: 18))
                .foregroundStyle(.black.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            Text("Correction:")
                .font(.caption.bold())
                .foregroundStyle(.black.opacity(0.5))
            TextEditor(text: $item.suggestion)
                .font(.system(size: 18))
                .foregroundStyle(.black)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 76)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.97)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.orange.opacity(0.6), lineWidth: 1))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.95)))
    }
}
