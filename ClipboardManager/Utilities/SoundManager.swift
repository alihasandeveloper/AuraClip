//
//  SoundManager.swift
//  ClipboardManager
//

import Foundation
import AppKit
import Combine

public final class SoundManager: ObservableObject {
    public static let shared = SoundManager()

    public static let soundEnabledKey = "ClipboardManager.SoundEnabled"

    @Published public var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: SoundManager.soundEnabledKey)
        }
    }

    private init() {
        if UserDefaults.standard.object(forKey: SoundManager.soundEnabledKey) == nil {
            self.isSoundEnabled = true
        } else {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: SoundManager.soundEnabledKey)
        }
    }

    public func playCopySound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Tink")?.play()
    }

    public func playPasteSound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Pop")?.play()
    }

    public func playPinSound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Ping")?.play()
    }

    public func playDeleteSound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Basso")?.play()
    }
}
