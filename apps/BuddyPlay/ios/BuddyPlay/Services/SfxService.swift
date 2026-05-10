import Foundation
import AVFoundation

/// Tiny SFX helper. Plays `move.aiff`, `capture.aiff`, etc. from the bundle.
/// Falls back to `AudioServicesPlaySystemSound` so we never need to ship
/// audio assets in v1.
final class SfxService {

    static let shared = SfxService()
    private init() {}

    func playMove() {
        if enabled { AudioServicesPlaySystemSound(1104) } // tock
    }
    func playCapture() {
        if enabled { AudioServicesPlaySystemSound(1306) } // beep
    }
    func playWin() {
        if enabled { AudioServicesPlaySystemSound(1025) } // glass
    }

    var enabled: Bool = true
}
