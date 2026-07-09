import AVFoundation

/// Manages sound effects for gameplay events.
@MainActor
final class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var soundEffectsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: "sound_effects_enabled") }
    }
    
    private var audioPlayers: [AVAudioPlayer] = []
    
    private init() {
        self.soundEffectsEnabled = UserDefaults.standard.object(forKey: "sound_effects_enabled") == nil
            ? true // Default to enabled
            : UserDefaults.standard.bool(forKey: "sound_effects_enabled")
    }
    
    /// Play explosion sound effect when a zombie is defeated.
    func playExplosion() {
        playSound(named: "explosion")
    }

    /// Play the exaggerated KABOOM when a zombie bomb detonates.
    func playKaboom() {
        playSound(named: "kaboom", volume: 1.0)
    }
    
    /// Play a named sound effect from the app bundle.
    private func playSound(named soundName: String, volume: Float = 0.7) {
        guard soundEffectsEnabled else { return }
        
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav", subdirectory: "Sounds") else {
            print("[SoundManager] Could not find sound file: \(soundName).wav")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = volume
            player.play()
            
            // Keep player in array to prevent deallocation while playing
            audioPlayers.append(player)
            
            // Remove from array after playback completes
            let duration = player.duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                self.audioPlayers.removeAll { $0 === player }
            }
        } catch {
            print("[SoundManager] Error playing sound \(soundName): \(error)")
        }
    }
}
