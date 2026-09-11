//
//  PasteSimulator.swift
//  ClipboardManager
//

import Foundation
import AppKit
import Carbon

public final class PasteSimulator {
    public static let shared = PasteSimulator()

    public static let autoPasteEnabledKey = "ClipboardManager.AutoPasteEnabled"

    public var isAutoPasteEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: PasteSimulator.autoPasteEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: PasteSimulator.autoPasteEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PasteSimulator.autoPasteEnabledKey)
        }
    }

    private init() {}

    public static var isAccessibilityGranted: Bool {
        return AXIsProcessTrusted()
    }

    public static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Paste the item to the previous active application
    public func paste(item: ClipboardItem, targetApp: NSRunningApplication?) {
        // 1. Write item content back to the general pasteboard
        ClipboardMonitor.shared.writeItemToPasteboard(item)
        SoundManager.shared.playPasteSound()

        guard isAutoPasteEnabled else { return }

        // 2. If target app is available, activate it and simulate Cmd+V
        if let app = targetApp, !app.isTerminated {
            app.activate(options: [.activateIgnoringOtherApps])

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.simulateCommandV()
            }
        } else {
            // Fallback: try activating previous frontmost app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.simulateCommandV()
            }
        }
    }

    /// Synthesizes Command+V keystroke using CGEvent
    public func simulateCommandV() {
        guard PasteSimulator.isAccessibilityGranted else {
            NSLog("[ClipboardManager] Accessibility permissions not granted for simulated paste.")
            return
        }

        let keyCode: CGKeyCode = 0x09 // Virtual key code for 'V'

        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = []

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
