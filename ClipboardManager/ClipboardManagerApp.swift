//
//  ClipboardManagerApp.swift
//  ClipboardManager
//

import SwiftUI
import AppKit

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use Settings scene for native macOS Preferences shortcut (Cmd+,)
        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (no dock icon, lives in menu bar)
        NSApplication.shared.setActivationPolicy(.accessory)

        // Setup Menu Bar icon & context menu
        MenuBarController.shared.setupMenuBar()

        // Start clipboard change monitoring
        ClipboardMonitor.shared.startMonitoring()

        // Bind global hotkey action (Cmd+Shift+V)
        HotkeyManager.shared.onHotkeyPressed = {
            HistoryPopupPanel.shared.togglePanel()
        }

        // Prompt accessibility permissions if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !PasteSimulator.isAccessibilityGranted {
                PasteSimulator.requestAccessibilityPermission()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ClipboardMonitor.shared.stopMonitoring()
    }
}
