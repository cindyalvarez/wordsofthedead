import SwiftUI
import AVFoundation

/// The opening cutscene that plays when a player first creates their character.
struct CutsceneView: View {
    @ObservedObject var engine: GameEngine
    @State private var currentScene: CutsceneScene = .scene1
    @State private var sceneOpacity: Double = 1.0
    @State private var displayedTexts: [String] = []
    @State private var delayedTexts: [String] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showContinueButton: Bool = false
    
    enum CutsceneScene: Equatable {
        case scene1
        case scene2
        case scene3
        case scene4
        case scene5
    }
    
    let scenes: [CutsceneScene: CutsceneData] = [
        .scene1: CutsceneData(
            background: .black,
            backgroundImage: nil,
            texts: [],
           duration: 3.0
        ),
        .scene2: CutsceneData(
            background: .black,
            backgroundImage: "accomplished",
            texts: [
                "After years of study and training, you're up for a job with Aegis Monster Containment Solutions.",
                "",
                "The job comes with competitive salary, full health coverage, and unlimited access to company-branded crossbows."
            ],
            initialTextSize: 24,
            delayedTexts: [
                "Unfortunately, you're competing against dozens of other applicants."
            ],
            delayedTextSize: 36,
            duration: 3.0,
            delayBeforePunchline: 2.5
        ),
        .scene3: CutsceneData(
            background: .black,
            backgroundImage: "zombies-escape",
            texts: [
                "Instead of a traditional job interview, you're all given a challenge."
            ],
            initialTextSize: 36,
            delayedTexts: [
                "Three days ago, an intern dropped a classified containment capsule into the library archives.",
                "",
                "Hundreds of experimental zombies escaped and ate the books instead.",
                "",
                "Now these book-fed undead roam the library, challenging anyone to tests of vocabulary and linguistic mastery."
            ],
            delayedTextSize: 24,
            duration: 3.0,
            delayBeforePunchline: 2.5
        ),
        .scene4: CutsceneData(
            background: .black,
            backgroundImage: nil,
            texts: [
                "Zombie: Use \"perspicacious\" in a sentence. Get it right - zombie go boom. Get it wrong -- well..."
            ],
            initialTextSize: 36,
            delayedTexts: [
                "The applicant with the highest zombie count earns the position. Second place gets--",
                "",
                "Just kidding - there IS no second place."
            ],
            delayedTextSize: 24,
            duration: 3.0,
            delayBeforePunchline: 2.5
        ),
        .scene5: CutsceneData(
            background: .black,
            backgroundImage: nil,
            texts: [],  // Scene 5 is special - just the title
            duration: 3.0
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            if let backgroundImage = scenes[currentScene]?.backgroundImage {
                ZStack {
                    if let path = Bundle.main.path(forResource: backgroundImage, ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Fallback to black if image not found
                        Color.black
                    }
                }
                .ignoresSafeArea()
            } else {
                (scenes[currentScene]?.background ?? .black)
                    .ignoresSafeArea()
            }
            
            // Vignette overlay for readability
            RadialGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.4)]),
                center: .center,
                startRadius: 300,
                endRadius: 900
            )
            .ignoresSafeArea()
            
            // Scene-specific content
            if currentScene == .scene5 {
                // Scene 5: Large glowing green title
                VStack {
                    Spacer()
                    Text("🧟")
                        .font(.system(size: 120))
                        .padding(.bottom, 20)
                    
                    Text("WORDS OF THE DEAD")
                        .font(.system(size: 72, weight: .bold, design: .default))
                        .foregroundStyle(Color.green)
                        .shadow(color: Color.green.opacity(0.8), radius: 20)
                        .tracking(2)
                    
                    Spacer()
                    
                    Text("Tap to begin...")
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, 40)
                }
            } else {
                // Scenes 1-4: Left-aligned text
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(getSceneText().indices, id: \.self) { index in
                            Text(getSceneText()[index])
                                .font(.system(size: scenes[currentScene]?.initialTextSize ?? 24, weight: .medium, design: .default))
                                .foregroundStyle(.white)
                                .lineSpacing(6)
                                .multilineTextAlignment(.leading)
                        }
                        
                        // Delayed text (punchline)
                        if !delayedTexts.isEmpty {
                            Spacer()
                                .frame(height: 18)
                            ForEach(delayedTexts.indices, id: \.self) { index in
                                Text(delayedTexts[index])
                                    .font(.system(size: scenes[currentScene]?.delayedTextSize ?? 24, weight: .medium, design: .default))
                                    .foregroundStyle(.white)
                                    .lineSpacing(6)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    .frame(maxWidth: 800, alignment: .leading)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    
                    // Continue button (scenes 2-4 only, shown after text appears)
                    if currentScene != .scene5 && currentScene != .scene1 && showContinueButton {
                        Button(action: {
                            print("DEBUG: Continue button tapped")
                            advanceScene()
                        }) {
                            Text("Continue")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            // Fade effect
            Color.black.opacity(1.0 - sceneOpacity)
                .ignoresSafeArea()
        }
        .onTapGesture {
            if currentScene == .scene5 {
                engine.markCutsceneWatched()
            }
        }
        .onAppear {
            print("DEBUG: CutsceneView.onAppear, currentScene=\(currentScene), showContinueButton=\(showContinueButton)")
            playCorpJingle()
            // Scene 1 auto-advances; scenes 2-4 show button after delays
            if currentScene == .scene1 {
                scheduleAutoAdvanceScene1()
            } else {
                scheduleDelayedTextAndButton()
            }
        }
    }
    
    private func getSceneText() -> [String] {
        return scenes[currentScene]?.texts ?? []
    }
    
    private func scheduleNextScene() {
        // For scenes 2-4, show delayed text and button after delays
        let delayBeforePunchline = scenes[currentScene]?.delayBeforePunchline ?? 0
        
        if delayBeforePunchline > 0 && !(scenes[currentScene]?.delayedTexts.isEmpty ?? true) {
            // Show delayed text after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforePunchline) {
                self.delayedTexts = self.scenes[self.currentScene]?.delayedTexts ?? []
            }
            // Show button after delayed text appears
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforePunchline + 0.5) {
                if self.currentScene != .scene1 && self.currentScene != .scene5 {
                    self.showContinueButton = true
                }
            }
        } else if self.currentScene != .scene1 && self.currentScene != .scene5 {
            // No delayed text but not scene 1/5 - show button immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showContinueButton = true
            }
        }
    }
    
    private func scheduleAutoAdvanceScene1() {
        // Scene 1 auto-advances after its duration
        let duration = scenes[currentScene]?.duration ?? 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.advanceScene()
        }
    }
    
    private func scheduleDelayedTextAndButton() {
        // For scenes 2-4: show delayed text after delay, then show Continue button
        let targetScene = currentScene
        let sceneData = scenes[targetScene]
        let delayBeforePunchline = sceneData?.delayBeforePunchline ?? 0
        
        print("DEBUG scheduleDelayedTextAndButton:")
        print("  - targetScene: \(targetScene)")
        print("  - delayBeforePunchline: \(delayBeforePunchline)")
        print("  - has delayedTexts: \(!(sceneData?.delayedTexts.isEmpty ?? true))")
        
        if delayBeforePunchline > 0 && !(sceneData?.delayedTexts.isEmpty ?? true) {
            print("  - BRANCH 1: Has delay and delayed texts")
            // Show delayed text after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBeforePunchline) {
                print("DEBUG: Executing delayed text at \(Date())")
                self.delayedTexts = sceneData?.delayedTexts ?? []
                // Show Continue button after delayed text appears (with a delay)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("DEBUG: Setting showContinueButton=true at \(Date())")
                    self.showContinueButton = true
                }
            }
        } else {
            print("  - BRANCH 2: No delayed text")
            // No delayed text - show button immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("DEBUG: Setting showContinueButton=true (immediate) at \(Date())")
                self.showContinueButton = true
            }
        }
    }
    
    private func advanceScene() {
        let nextScene: CutsceneScene?
        
        switch currentScene {
        case .scene1: nextScene = .scene2
        case .scene2: nextScene = .scene3
        case .scene3: nextScene = .scene4
        case .scene4: nextScene = .scene5
        case .scene5: nextScene = nil
        }
        
        if let nextScene = nextScene {
            currentScene = nextScene
            delayedTexts = []  // Reset delayed texts for new scene
            showContinueButton = false
            sceneOpacity = 1.0
            
            // Schedule appropriate action for the new scene
            // Use DispatchQueue to ensure scheduling happens after view re-renders
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if nextScene == .scene1 {
                    self.scheduleAutoAdvanceScene1()
                } else {
                    self.scheduleDelayedTextAndButton()
                }
            }
        } else {
            // Scene 5 ended, mark watched
            engine.markCutsceneWatched()
        }
    }
    
    private func playCorpJingle() {
        let synthesizer = AudioSynthesizer()
        if let data = synthesizer.generateJingle() {
            do {
                audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
                audioPlayer?.volume = 0.3
                audioPlayer?.play()
            } catch {
                print("Failed to play jingle: \(error)")
            }
        }
    }
}

struct CutsceneData {
    let background: Color
    let backgroundImage: String?
    let texts: [String]
    let initialTextSize: Double
    let delayedTexts: [String]
    let delayedTextSize: Double
    let duration: Double
    let delayBeforePunchline: Double
    
    init(background: Color, backgroundImage: String? = nil, texts: [String], initialTextSize: Double = 24, delayedTexts: [String] = [], delayedTextSize: Double = 24, duration: Double, delayBeforePunchline: Double = 0) {
        self.background = background
        self.backgroundImage = backgroundImage
        self.texts = texts
        self.initialTextSize = initialTextSize
        self.delayedTexts = delayedTexts
        self.delayedTextSize = delayedTextSize
        self.duration = duration
        self.delayBeforePunchline = delayBeforePunchline
    }
}

// Audio synthesis for the corporate jingle
class AudioSynthesizer {
    func generateJingle() -> Data? {
        let sampleRate: Double = 44100
        let duration: Double = 2.0
        let totalSamples = Int(sampleRate * duration)
        
        var samples: [Int16] = []
        
        // Generate a simple cheerful 3-note jingle: C-E-G (major chord)
        let notes = [262, 330, 392] // C, E, G frequencies
        let noteLength = totalSamples / 3
        
        for note in notes {
            for i in 0..<noteLength {
                let time = Double(i) / sampleRate
                let sine = sin(2.0 * .pi * Double(note) * time)
                
                // Add envelope (fade in/out)
                let envelope: Double
                if i < noteLength / 10 {
                    envelope = Double(i) / Double(noteLength / 10) // Fade in
                } else if i > noteLength * 9 / 10 {
                    envelope = Double(noteLength - i) / Double(noteLength / 10) // Fade out
                } else {
                    envelope = 1.0
                }
                
                let sample = Int16(sine * 20000 * envelope)
                samples.append(sample)
            }
        }
        
        // Convert to WAV data
        return waveData(from: samples, sampleRate: Int(sampleRate))
    }
    
    private func waveData(from samples: [Int16], sampleRate: Int) -> Data? {
        var wav = Data()
        
        // WAV header
        let chunkSize = 36 + samples.count * 2
        let subchunk2Size = samples.count * 2
        
        wav.append(contentsOf: "RIFF".utf8)
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(chunkSize).littleEndian) { Data($0) })
        wav.append(contentsOf: "WAVE".utf8)
        
        // fmt subchunk
        wav.append(contentsOf: "fmt ".utf8)
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // subchunk1 size
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // audio format (PCM)
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Data($0) }) // channels
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Data($0) }) // sample rate
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { Data($0) }) // byte rate
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Data($0) }) // block align
        wav.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Data($0) }) // bits per sample
        
        // data subchunk
        wav.append(contentsOf: "data".utf8)
        wav.append(contentsOf: withUnsafeBytes(of: UInt32(subchunk2Size).littleEndian) { Data($0) })
        
        // Add sample data
        for sample in samples {
            wav.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }
        
        return wav
    }
}

#Preview {
    let gameEngine = GameEngine()
    CutsceneView(engine: gameEngine)
}
