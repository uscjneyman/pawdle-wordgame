import Foundation
import AVFoundation
import AudioToolbox

/// Centralized audio helper for background music and lightweight game SFX.
final class SoundManager {
    static let shared = SoundManager()

    private let backgroundTrackName = "01. Opening Theme"

    private var backgroundPlayer: AVAudioPlayer?

    private init() {
        configureAudioSession()
    }

    func startBackgroundMusic() {
        // Avoid creating duplicate players if the track is already running.
        guard backgroundPlayer?.isPlaying != true else { return }
        backgroundPlayer = makePlayer(
            resource: backgroundTrackName,
            loops: -1,
            volume: 0.25
        )
        backgroundPlayer?.prepareToPlay()
        backgroundPlayer?.play()
    }

    func stopBackgroundMusic() {
        backgroundPlayer?.stop()
    }

    func resumeBackgroundMusic() {
        // Recreate the player if it was released, otherwise continue playback.
        guard let backgroundPlayer else {
            startBackgroundMusic()
            return
        }
        if !backgroundPlayer.isPlaying {
            backgroundPlayer.play()
        }
    }

    func playVictory() {
        // Always use a built-in tone so no extra SFX files are required.
        AudioServicesPlaySystemSound(1025)
    }

    func playSadTrombone() {
        // Always use a built-in tone so no extra SFX files are required.
        AudioServicesPlaySystemSound(1053)
    }

    private func makePlayer(resource: String, loops: Int, volume: Float) -> AVAudioPlayer? {
        // Return nil if the file cannot be resolved so callers can fail gracefully.
        guard let url = resourceURL(for: resource) else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            player.volume = volume
            return player
        } catch {
            return nil
        }
    }

    private func resourceURL(for resource: String) -> URL? {
        // First handle names that may already include an extension, e.g. "track.mp3".
        let ns = resource as NSString
        let extInName = ns.pathExtension
        if !extInName.isEmpty {
            let base = ns.deletingPathExtension
            if let url = Bundle.main.url(forResource: base, withExtension: extInName) {
                return url
            }
        }

        // Then try exact resource name as-is.
        if let url = Bundle.main.url(forResource: resource, withExtension: nil) {
            return url
        }

        // Finally try common audio extensions.
        let exts = ["mp3", "m4a", "wav", "aac"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: resource, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private func configureAudioSession() {
        do {
            // .ambient allows music to coexist with other audio apps.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal: app can continue without custom audio session behavior.
        }
    }
}