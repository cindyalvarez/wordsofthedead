import SwiftUI
import AppKit

/// The active playfield: HUD at the top; the full remaining height is the attack zone
/// where zombies fall with their answer choices embedded around them.
struct PlayfieldView: View {
    @ObservedObject var engine: GameEngine
    @State private var keyMonitor: Any?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HUDView(lives: engine.lives,
                        zombiesKilled: engine.zombiesKilled,
                        level: engine.level,
                        mastered: engine.masteredCount,
                        totalWords: engine.totalWords,
                        isBoss: engine.isBossLevel)

                // Full remaining height: zombies fall with choices embedded around them.
                // The reveal card slides up from the bottom after a correct kill.
                ZStack(alignment: .bottom) {
                    AttackZoneView(engine: engine)

                    if engine.phase == .revealing, let word = engine.revealWord {
                        RevealView(word: word, stage: engine.revealStage)
                            .padding(14)
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.80))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: engine.phase == .revealing)
            }

            if engine.isPaused {
                PauseOverlayView()
            }

            if engine.showStreakBanner {
                CenterStreakBannerView()
                    .transition(.scale.combined(with: .opacity))
            }

        }
        .onAppear(perform: installPauseKeyMonitor)
        .onDisappear(perform: removePauseKeyMonitor)
        .animation(.spring(response: 0.3), value: engine.showStreakBanner)
    }

    private func installPauseKeyMonitor() {
        removePauseKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let key = event.charactersIgnoringModifiers?.lowercased() else {
                return event
            }
            switch key {
            case "p":
                engine.togglePause()
                return nil
            case "j":
                if engine.phase == .playing, let lead = engine.leadZombie {
                    if lead.kind == .fillBlank {
                        engine.answerFillBlank(left: false)
                    } else if lead.kind == .definition || lead.kind == .reverseDefinition {
                        engine.advanceCurrentChoice()
                    }
                    return nil
                }
                return event
            case "f":
                if engine.phase == .playing, let lead = engine.leadZombie, lead.kind == .fillBlank {
                    engine.answerFillBlank(left: true)
                    return nil
                }
                return event
            case " ":
                if engine.phase == .playing {
                    engine.guessCurrent()
                    return nil
                }
                return event
            default:
                return event
            }
        }
    }

    private func removePauseKeyMonitor() {
        guard let keyMonitor else { return }
        NSEvent.removeMonitor(keyMonitor)
        self.keyMonitor = nil
    }
}

private struct CenterStreakBannerView: View {
    var body: some View {
        Text("🔥 STREAK — you got a new life!")
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(.yellow)
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.black.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.yellow.opacity(0.7), lineWidth: 2)
            )
            .shadow(color: .yellow.opacity(0.35), radius: 18)
    }
}

private struct PauseOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("⏸ Paused")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.green)
                Text("Press  P  to resume")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

private struct AttackZoneView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                LevelBackgroundView(level: engine.level)

                // Player danger line at the bottom of the zone.
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(.red.opacity(0.55))
                        .frame(height: 4)
                }

                let leadID = engine.leadZombie?.id
                ForEach(engine.zombies) { zombie in
                    let isLead = zombie.id == leadID
                    // Only show choices on the lead zombie during active play.
                    let showChoices = isLead && engine.phase == .playing
                    ZombieView(
                        prompt: zombie.prompt,
                        kind: ZombieKind.allCases[zombie.variant % ZombieKind.allCases.count],
                        roundKind: zombie.kind,
                        wrong: zombie.wrong,
                        isLead: isLead,
                        isExploding: zombie.isExploding,
                        choices: showChoices ? zombie.question.choices : [],
                        currentChoiceIndex: zombie.currentChoiceIndex,
                        correctIndices: zombie.question.correctIndices,
                        selectedChoiceIndices: zombie.selectedChoiceIndices,
                        wrongChoiceIndices: zombie.wrongChoiceIndices,
                        onGuessChoice: showChoices ? { i in engine.guessChoice(at: i) } : nil,
                        onSelectSynonym: showChoices ? { i in engine.answerSynonymChoice(at: i) } : nil,
                        onFillBlank: showChoices ? { isLeft in engine.answerFillBlank(left: isLeft) } : nil
                    )
                    .position(
                        x: zombieX(zombie.lane, in: geo.size.width),
                        y: zombieY(zombie.progress, in: geo.size.height, roundKind: zombie.kind)
                    )
                    .animation(.linear(duration: 0.05), value: zombie.progress)
                }
            }
        }
    }

    private func zombieX(_ lane: Int, in width: CGFloat) -> CGFloat {
        // Keep zombies clear of the window edges in each lane.
        let margin = min(width * 0.22, 200)
        switch lane {
        case 0: return margin
        case 2: return width - margin
        default: return width / 2
        }
    }

    private func zombieY(_ progress: Double, in height: CGFloat, roundKind: RoundKind) -> CGFloat {
        // Fill-in-the-blank zombies use taller sentence cards, so give them a little more
        // vertical runway to reduce overlap when multiple are on screen.
        let top: CGFloat = roundKind == .fillBlank ? 60 : 95
        let bottom = height - (roundKind == .fillBlank ? 40 : 70)
        return top + (bottom - top) * CGFloat(progress)
    }
}

/// Per-level background for the attack zone. Each level always maps to the same image
/// (see `BackgroundCatalog`). The chosen image is scaled to fill the zone, with a dark
/// gradient on top so falling zombies and their word/sentence text stay legible.
private struct LevelBackgroundView: View {
    let level: Int

    var body: some View {
        ZStack {
            if let image = BackgroundCatalog.image(for: level) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                LinearGradient(
                    colors: [Color.black.opacity(0.30), Color.black.opacity(0.62)],
                    startPoint: .top, endPoint: .bottom
                )
            } else {
                // No image assigned to this level yet → plain black background.
                Color.black
            }
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

/// Assigns each level a persistent background image bundled under `Resources/backgrounds`.
///
/// - Levels that are a multiple of 5 (5, 10, 15, ...) draw from the "sf-" images; these are
///   reserved exclusively for multiple-of-5 levels. All other levels draw from the remaining
///   (non-"sf-") images.
/// - Within each pool, levels are filled in order with images not yet used by that pool. Once
///   a pool's images are exhausted, further levels of that kind get no image (plain black).
/// - Assignments are persisted (see `BackgroundAssignmentStore`), so a given level always keeps
///   the same background. Adding more images later simply assigns them to the next, currently
///   black, higher levels without disturbing any existing assignment.
enum BackgroundCatalog {
    /// All bundled background file names (without extension), sorted for stable ordering.
    private static let allNames: [String] = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "backgrounds") ?? []
        return urls.map { $0.deletingPathExtension().lastPathComponent }.sorted()
    }()

    /// "sf-" images, reserved for multiple-of-5 levels.
    private static let sfNames: [String] = allNames.filter { $0.hasPrefix("sf-") }

    /// All other images, used for non-multiple-of-5 levels.
    private static let regularNames: [String] = allNames.filter { !$0.hasPrefix("sf-") }

    private static var assignments: [Int: String] = BackgroundAssignmentStore.load()
    private static var imageCache: [String: NSImage] = [:]

    /// The image name for a level, or nil if no image is assigned (→ plain black background).
    static func name(for level: Int) -> String? {
        let pool = (level % 5 == 0) ? sfNames : regularNames
        guard !pool.isEmpty else { return nil }

        // Keep an existing assignment if its image is still available.
        if let locked = assignments[level], pool.contains(locked) {
            return locked
        }

        // Otherwise take the first image in this pool not yet used by a same-kind level.
        let isMultipleOfFive = (level % 5 == 0)
        let used = Set(assignments.filter { ($0.key % 5 == 0) == isMultipleOfFive }.values)
        guard let chosen = pool.first(where: { !used.contains($0) }) else {
            return nil   // Pool exhausted → black until more images are added.
        }
        assignments[level] = chosen
        BackgroundAssignmentStore.save(assignments)
        return chosen
    }

    static func image(for level: Int) -> NSImage? {
        guard let name = name(for: level) else { return nil }
        if let cached = imageCache[name] { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: "backgrounds"),
              let image = NSImage(contentsOf: url) else { return nil }
        imageCache[name] = image
        return image
    }
}

/// The visual flavor of a zombie: a distinct silhouette, aura color, eye color, and
/// a shaded skin/cloth palette so each one is drawn as a small painterly figure.
enum ZombieKind: CaseIterable {
    case classic, ghoul, reaper

    var auraColor: Color {
        switch self {
        case .classic: return Color(red: 0.40, green: 0.80, blue: 0.20)
        case .ghoul:   return Color(red: 0.62, green: 0.30, blue: 0.85)
        case .reaper:  return Color(red: 0.20, green: 0.80, blue: 0.80)
        }
    }

    var eyeColor: Color {
        switch self {
        case .classic: return .red
        case .ghoul:   return .yellow
        case .reaper:  return .orange
        }
    }

    /// Lit (top) and shadowed (bottom) skin/bone tones, kept desaturated and moody to
    /// match the painterly graveyard background.
    var skin: (lit: Color, dark: Color) {
        switch self {
        case .classic: return (Color(red: 0.55, green: 0.61, blue: 0.47),
                               Color(red: 0.27, green: 0.34, blue: 0.24))
        case .ghoul:   return (Color(red: 0.64, green: 0.59, blue: 0.69),
                               Color(red: 0.33, green: 0.29, blue: 0.41))
        case .reaper:  return (Color(red: 0.82, green: 0.81, blue: 0.74),
                               Color(red: 0.43, green: 0.43, blue: 0.40))
        }
    }

    /// Lit (top) and shadowed (bottom) clothing/robe tones.
    var cloth: (lit: Color, dark: Color) {
        switch self {
        case .classic: return (Color(red: 0.20, green: 0.24, blue: 0.24),
                               Color(red: 0.08, green: 0.10, blue: 0.10))
        case .ghoul:   return (Color(red: 0.22, green: 0.17, blue: 0.29),
                               Color(red: 0.09, green: 0.07, blue: 0.13))
        case .reaper:  return (Color(red: 0.14, green: 0.14, blue: 0.17),
                               Color(red: 0.04, green: 0.04, blue: 0.06))
        }
    }

    /// True for the cloaked reaper, which is drawn with a hood + skull instead of a
    /// bare-headed shambler silhouette.
    var isHooded: Bool { self == .reaper }
}

private struct ZombieView: View {
    let prompt: String
    let kind: ZombieKind
    var roundKind: RoundKind = .definition
    let wrong: Bool
    var isLead: Bool = true
    let isExploding: Bool

    // Choice data — only populated for the lead zombie during active play.
    var choices: [String] = []
    var currentChoiceIndex: Int = 0
    var correctIndices: Set<Int> = []
    var selectedChoiceIndices: Set<Int> = []
    var wrongChoiceIndices: Set<Int> = []
    var onGuessChoice: ((Int) -> Void)? = nil
    var onSelectSynonym: ((Int) -> Void)? = nil
    var onFillBlank: ((Bool) -> Void)? = nil

    @State private var sway = false
    @State private var lurch = false

    // Art is scaled to 75% of the original size.
    private let scale: CGFloat = 0.75
    private var auraSize: CGFloat { 150 * scale }
    private var figureW: CGFloat { 120 * scale }
    private var figureH: CGFloat { 150 * scale }

    private var showChoices: Bool { isLead && !choices.isEmpty && !isExploding }

    var body: some View {
        Group {
            if showChoices {
                switch roundKind {
                case .definition, .reverseDefinition:
                    // 2 choice columns flanking the zombie.
                    HStack(alignment: .center, spacing: 12) {
                        choiceColumn(indices: [0, 1], width: 172)
                        coreView
                        choiceColumn(indices: [2, 3], width: 172)
                    }
                case .synonym:
                    // 3 choice columns on each side.
                    HStack(alignment: .center, spacing: 12) {
                        synonymColumn(indices: [0, 1, 2], width: 152)
                        coreView
                        synonymColumn(indices: [3, 4, 5], width: 152)
                    }
                case .fillBlank:
                    // Zombie above, two word-choice buttons directly below.
                    VStack(spacing: 10) {
                        coreView
                        fillBlankButtons
                    }
                }
            } else {
                coreView
            }
        }
        .onAppear {
            if !isExploding {
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { sway = true }
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { lurch = true }
            }
        }
        .animation(.easeOut(duration: 0.5), value: isExploding)
        .opacity(isLead ? 1.0 : 0.8)
    }

    // MARK: - Core zombie (figure + prompt label)

    private var coreView: some View {
        VStack(spacing: 6) {
            zombieArtStack
            promptLabel
        }
    }

    private var zombieArtStack: some View {
        ZStack {
            // Explosion burst.
            if isExploding {
                Circle()
                    .fill(RadialGradient(
                        colors: [.yellow.opacity(0.8), .orange.opacity(0.4), .clear],
                        center: .center, startRadius: 4, endRadius: 100 * scale
                    ))
                    .frame(width: auraSize * 1.5, height: auraSize * 1.5)
                    .scaleEffect(1.8)
            }
            // Sickly aura pulsing behind the zombie.
            Circle()
                .fill(RadialGradient(
                    colors: [kind.auraColor.opacity(0.40), .clear],
                    center: .center, startRadius: 4, endRadius: 70 * scale
                ))
                .frame(width: auraSize, height: auraSize)
                .scaleEffect(lurch ? 1.08 : 0.92)
                .blur(radius: 6)

            ZombieFigure(kind: kind, wrong: wrong)
                .frame(width: figureW, height: figureH)
                .shadow(color: kind.auraColor.opacity(0.7), radius: 10)
                .shadow(color: .red.opacity(wrong ? 0.9 : 0.0), radius: wrong ? 18 : 0)
                .rotationEffect(.degrees(sway ? 4 : -4), anchor: .bottom)
                .offset(y: lurch ? -3 : 3)
                .scaleEffect(isExploding ? 0.1 : 1.0)
                .opacity(isExploding ? 0.0 : 1.0)
        }
        .frame(height: auraSize)
    }

    private var promptLabel: some View {
        Group {
            if roundKind == .definition || roundKind == .synonym {
                Text(prompt)
                    .font(.system(size: 28, weight: .heavy, design: .serif))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.08, green: 0.10, blue: 0.08).opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(wrong ? Color.red : kind.auraColor, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
            } else {
                // Fill-in-the-blank sentence or short definition — smaller, wrapped.
                Text(prompt)
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.08, green: 0.10, blue: 0.08).opacity(0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(wrong ? Color.red : kind.auraColor, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
            }
        }
    }

    // MARK: - Definition / reverse-definition choice columns

    private func choiceColumn(indices: [Int], width: CGFloat) -> some View {
        VStack(spacing: 8) {
            ForEach(indices, id: \.self) { i in
                definitionChoiceButton(text: choices[safe: i] ?? "", index: i)
                    .frame(height: 72)
            }
        }
        .frame(width: width)
    }

    private func definitionChoiceButton(text: String, index: Int) -> some View {
        let isSelected = (index == currentChoiceIndex)
        let isWrong = (wrong && isSelected)
        let border: Color = isWrong ? .red.opacity(0.85) : isSelected ? kind.auraColor : .white.opacity(0.20)
        let bg: Color    = isWrong ? .red.opacity(0.12) : isSelected ? kind.auraColor.opacity(0.18) : .white.opacity(0.07)
        return Button { onGuessChoice?(index) } label: {
            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(bg))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }

    // MARK: - Synonym choice columns

    private func synonymColumn(indices: [Int], width: CGFloat) -> some View {
        VStack(spacing: 8) {
            ForEach(indices, id: \.self) { i in
                synonymChoiceButton(text: choices[safe: i] ?? "", index: i)
                    .frame(height: 60)
            }
        }
        .frame(width: width)
    }

    private func synonymChoiceButton(text: String, index: Int) -> some View {
        let isSelected = selectedChoiceIndices.contains(index)
        let isWrong    = wrongChoiceIndices.contains(index)
        let bg: Color     = isSelected ? .green.opacity(0.24) : isWrong ? .red.opacity(0.18) : .white.opacity(0.07)
        let border: Color = isWrong ? .red.opacity(0.85) : isSelected ? .green.opacity(0.85) : .white.opacity(0.20)
        return Button { onSelectSynonym?(index) } label: {
            Text(text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(bg))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(border, lineWidth: isSelected ? 2 : 1))
                .shadow(color: isSelected ? .green.opacity(0.45) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.12), value: isSelected)
    }

    // MARK: - Fill-in-the-blank buttons

    private var fillBlankButtons: some View {
        HStack(spacing: 20) {
            fillWordButton(key: "F", word: choices[safe: 0] ?? "", isLeft: true)
            fillWordButton(key: "J", word: choices[safe: 1] ?? "", isLeft: false)
        }
    }

    private func fillWordButton(key: String, word: String, isLeft: Bool) -> some View {
        Button { onFillBlank?(isLeft) } label: {
            VStack(spacing: 8) {
                Text(key)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(.green))
                Text(word)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.08)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(wrong ? Color.red.opacity(0.8) : Color.green.opacity(0.5), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A small painterly zombie/ghoul/reaper drawn with Canvas: shaded skin and clothing
/// gradients, tattered robe, reaching arms, a sunken face and glowing eyes — tuned to
/// the muted, illustrated look of the graveyard background rather than a flat emoji.
struct ZombieFigure: View {
    let kind: ZombieKind
    let wrong: Bool

    var body: some View {
        Canvas { ctx, size in
            ZombieFigure.draw(into: &ctx, size: size, kind: kind)
        }
        .drawingGroup()
    }

    static func draw(into ctx: inout GraphicsContext, size: CGSize, kind: ZombieKind) {
        let w = size.width, h = size.height
        let cx = w / 2
        let skin = kind.skin
        let cloth = kind.cloth

        // Vertical lit→shadow gradient between two points.
        func vGrad(_ lit: Color, _ dark: Color, top: CGFloat, bottom: CGFloat) -> GraphicsContext.Shading {
            .linearGradient(Gradient(colors: [lit, dark]),
                            startPoint: CGPoint(x: cx, y: top),
                            endPoint: CGPoint(x: cx, y: bottom))
        }

        // Head / body geometry.
        let headTop = 0.07 * h
        let headH = 0.27 * h
        let headW = 0.225 * h
        let headCY = headTop + headH / 2
        let headBottom = headTop + headH
        let shoulderY = headBottom + 0.045 * h
        let shoulderHalf = 0.20 * h
        let hemY = 0.82 * h

        // Soft ground shadow.
        ctx.fill(Path(ellipseIn: CGRect(x: cx - 0.26 * h, y: 0.95 * h, width: 0.52 * h, height: 0.07 * h)),
                 with: .color(.black.opacity(0.35)))

        // Legs (staggered for a shambling stance).
        func limb(_ a: CGPoint, _ b: CGPoint, width: CGFloat, lit: Color, dark: Color) {
            var p = Path()
            p.move(to: a)
            p.addLine(to: b)
            ctx.stroke(p, with: .linearGradient(Gradient(colors: [lit, dark]),
                                                startPoint: a, endPoint: b),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
        limb(CGPoint(x: cx - 0.07 * h, y: hemY - 0.02 * h), CGPoint(x: cx - 0.085 * h, y: 0.97 * h),
             width: 0.11 * h, lit: cloth.lit, dark: cloth.dark)
        limb(CGPoint(x: cx + 0.07 * h, y: hemY - 0.02 * h), CGPoint(x: cx + 0.075 * h, y: 0.995 * h),
             width: 0.11 * h, lit: cloth.lit, dark: cloth.dark)

        if kind.isHooded {
            // Reaper: a wide cloak that drapes from the hood to the ground.
            var cloak = Path()
            cloak.move(to: CGPoint(x: cx - 0.10 * h, y: headCY))
            cloak.addQuadCurve(to: CGPoint(x: cx - 0.30 * h, y: 0.99 * h),
                               control: CGPoint(x: cx - 0.34 * h, y: 0.6 * h))
            // Tattered hem.
            var x = cx - 0.30 * h
            var up = true
            while x < cx + 0.30 * h {
                x += 0.075 * h
                cloak.addLine(to: CGPoint(x: min(x, cx + 0.30 * h), y: up ? 0.95 * h : 0.99 * h))
                up.toggle()
            }
            cloak.addQuadCurve(to: CGPoint(x: cx + 0.10 * h, y: headCY),
                               control: CGPoint(x: cx + 0.34 * h, y: 0.6 * h))
            cloak.closeSubpath()
            ctx.fill(cloak, with: vGrad(cloth.lit, cloth.dark, top: headCY, bottom: h))
        } else {
            // Torso with a ragged hem.
            var torso = Path()
            torso.move(to: CGPoint(x: cx - shoulderHalf, y: shoulderY))
            torso.addLine(to: CGPoint(x: cx - 0.17 * h, y: hemY))
            var x = cx - 0.17 * h
            var up = true
            while x < cx + 0.17 * h {
                x += 0.057 * h
                torso.addLine(to: CGPoint(x: min(x, cx + 0.17 * h), y: up ? hemY - 0.03 * h : hemY))
                up.toggle()
            }
            torso.addLine(to: CGPoint(x: cx + shoulderHalf, y: shoulderY))
            torso.addQuadCurve(to: CGPoint(x: cx - shoulderHalf, y: shoulderY),
                               control: CGPoint(x: cx, y: shoulderY - 0.05 * h))
            torso.closeSubpath()
            ctx.fill(torso, with: vGrad(cloth.lit, cloth.dark, top: shoulderY, bottom: hemY))
        }

        // Reaching arms (bare skin forearms + a torn sleeve at the shoulder).
        func arm(shoulder: CGPoint, elbow: CGPoint, hand: CGPoint) {
            limb(shoulder, elbow, width: 0.10 * h, lit: skin.lit, dark: skin.dark)
            limb(elbow, hand, width: 0.085 * h, lit: skin.lit, dark: skin.dark)
            // Sleeve over the upper arm.
            limb(shoulder, CGPoint(x: (shoulder.x + elbow.x) / 2, y: (shoulder.y + elbow.y) / 2),
                 width: 0.12 * h, lit: cloth.lit, dark: cloth.dark)
            // Hand + three claw fingers.
            ctx.fill(Path(ellipseIn: CGRect(x: hand.x - 0.05 * h, y: hand.y - 0.05 * h,
                                            width: 0.10 * h, height: 0.10 * h)),
                     with: .color(skin.dark))
            for dx in [-0.03, 0.0, 0.03] as [CGFloat] {
                var claw = Path()
                claw.move(to: CGPoint(x: hand.x + dx * h, y: hand.y + 0.02 * h))
                claw.addLine(to: CGPoint(x: hand.x + dx * h, y: hand.y + 0.08 * h))
                ctx.stroke(claw, with: .color(skin.dark),
                           style: StrokeStyle(lineWidth: 0.02 * h, lineCap: .round))
            }
        }
        arm(shoulder: CGPoint(x: cx - shoulderHalf, y: shoulderY + 0.01 * h),
            elbow: CGPoint(x: cx - shoulderHalf - 0.01 * h, y: 0.50 * h),
            hand: CGPoint(x: cx - 0.12 * h, y: 0.65 * h))
        arm(shoulder: CGPoint(x: cx + shoulderHalf, y: shoulderY + 0.01 * h),
            elbow: CGPoint(x: cx + shoulderHalf + 0.01 * h, y: 0.48 * h),
            hand: CGPoint(x: cx + 0.10 * h, y: 0.63 * h))

        // Neck.
        ctx.fill(Path(CGRect(x: cx - 0.05 * h, y: headBottom - 0.02 * h, width: 0.10 * h, height: 0.08 * h)),
                 with: .color(skin.dark))

        if kind.isHooded {
            // Hood framing the skull.
            var hood = Path()
            hood.addEllipse(in: CGRect(x: cx - headW * 0.95, y: headTop - 0.03 * h,
                                       width: headW * 1.9, height: headH * 1.25))
            ctx.fill(hood, with: vGrad(cloth.lit, cloth.dark, top: headTop, bottom: headBottom))
        }

        // Head / skull.
        let headRect = CGRect(x: cx - headW / 2, y: headTop, width: headW, height: headH)
        ctx.fill(Path(ellipseIn: headRect),
                 with: .radialGradient(Gradient(colors: [skin.lit, skin.dark]),
                                       center: CGPoint(x: cx - headW * 0.12, y: headTop + headH * 0.32),
                                       startRadius: 1, endRadius: headH * 0.7))

        // Sunken brow shadow.
        ctx.fill(Path(ellipseIn: CGRect(x: cx - headW * 0.42, y: headTop + headH * 0.30,
                                        width: headW * 0.84, height: headH * 0.30)),
                 with: .color(skin.dark.opacity(0.6)))

        // Eyes: dark sockets with a glowing pupil.
        let eyeY = headTop + headH * 0.45
        let eyeDX = headW * 0.23
        let socketR = headW * 0.17
        let glow = kind.eyeColor
        for sx in [cx - eyeDX, cx + eyeDX] {
            ctx.fill(Path(ellipseIn: CGRect(x: sx - socketR, y: eyeY - socketR,
                                            width: socketR * 2, height: socketR * 2)),
                     with: .color(.black.opacity(0.85)))
            ctx.drawLayer { layer in
                layer.addFilter(.blur(radius: socketR * 0.6))
                layer.fill(Path(ellipseIn: CGRect(x: sx - socketR * 0.6, y: eyeY - socketR * 0.6,
                                                  width: socketR * 1.2, height: socketR * 1.2)),
                           with: .color(glow))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: sx - socketR * 0.32, y: eyeY - socketR * 0.32,
                                            width: socketR * 0.64, height: socketR * 0.64)),
                     with: .color(.white.opacity(0.9)))
        }

        // Nose hollow.
        ctx.fill(Path(ellipseIn: CGRect(x: cx - headW * 0.06, y: headTop + headH * 0.55,
                                        width: headW * 0.12, height: headH * 0.12)),
                 with: .color(skin.dark.opacity(0.8)))

        // Mouth: a dark gash with crude teeth.
        let mouthY = headTop + headH * 0.78
        let mouthW = headW * 0.5
        ctx.fill(Path(CGRect(x: cx - mouthW / 2, y: mouthY, width: mouthW, height: headH * 0.10)),
                 with: .color(.black.opacity(0.8)))
        var tx = cx - mouthW / 2
        while tx < cx + mouthW / 2 {
            ctx.fill(Path(CGRect(x: tx, y: mouthY, width: mouthW * 0.10, height: headH * 0.05)),
                     with: .color(skin.lit.opacity(0.85)))
            tx += mouthW * 0.18
        }

        // Hair: stringy strands for the ghoul, sparse tufts for the classic shambler.
        if !kind.isHooded {
            let strands = (kind == .ghoul) ? 9 : 5
            let len: CGFloat = (kind == .ghoul) ? 0.18 * h : 0.05 * h
            for i in 0..<strands {
                let t = CGFloat(i) / CGFloat(strands - 1)
                let sx = cx - headW * 0.5 + t * headW
                var hair = Path()
                hair.move(to: CGPoint(x: sx, y: headTop + 0.01 * h))
                hair.addQuadCurve(to: CGPoint(x: sx + (t - 0.5) * 0.06 * h, y: headTop - 0.02 * h + len),
                                  control: CGPoint(x: sx + (t - 0.5) * 0.12 * h, y: headTop))
                ctx.stroke(hair, with: .color(cloth.dark.opacity(0.95)),
                           style: StrokeStyle(lineWidth: 0.015 * h, lineCap: .round))
            }
        }
    }
}
