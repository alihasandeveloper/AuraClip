//
//  MenuBarController.swift
//  ClipboardManager
//

import AppKit
import SwiftUI

public final class MenuBarController: NSObject {
    public static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var settingsWindowController: NSWindowController?

    private override init() {
        super.init()
    }

    public func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "AuraClip")?.withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "📋"
        }
        button.toolTip = "AuraClip (⌘⇧V)"

        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let currentEvent = NSApp.currentEvent else {
            HistoryPopupPanel.shared.togglePanel()
            return
        }

        // Check if right-click or Control-click
        if currentEvent.type == .rightMouseUp || (currentEvent.modifierFlags.contains(.control)) {
            showContextMenu()
        } else {
            // Left click: Toggle popup under status item
            if let window = sender.window {
                let buttonFrame = sender.bounds
                let screenRect = window.convertToScreen(buttonFrame)
                let point = NSPoint(x: screenRect.midX, y: screenRect.minY)
                HistoryPopupPanel.shared.togglePanel(near: point)
            } else {
                HistoryPopupPanel.shared.togglePanel()
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Open AuraClip", action: #selector(openHistoryPopup), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let isPaused = ClipboardStore.shared.isPaused
        let pauseItem = NSMenuItem(
            title: isPaused ? "Resume Clipboard Monitoring" : "Pause Clipboard Monitoring",
            action: #selector(togglePauseMonitoring),
            keyEquivalent: ""
        )
        pauseItem.target = self
        menu.addItem(pauseItem)

        let clearItem = NSMenuItem(title: "Clear Unpinned History", action: #selector(clearHistoryAction), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Preferences...", action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let accessItem = NSMenuItem(title: "Accessibility Status...", action: #selector(checkAccessibilityAction), keyEquivalent: "")
        accessItem.target = self
        menu.addItem(accessItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit AuraClip", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Clear menu so left click continues to trigger target/action
    }

    @objc private func openHistoryPopup() {
        HistoryPopupPanel.shared.openPanel()
    }

    @objc private func togglePauseMonitoring() {
        ClipboardStore.shared.isPaused.toggle()
    }

    @objc private func clearHistoryAction() {
        ClipboardStore.shared.clearHistory()
    }

    @objc private func openSettingsAction() {
        openSettingsWindow()
    }

    @objc private func checkAccessibilityAction() {
        if !PasteSimulator.isAccessibilityGranted {
            PasteSimulator.requestAccessibilityPermission()
            PasteSimulator.openAccessibilitySettings()
        } else {
            openSettingsWindow()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    public func openSettingsWindow() {
        if let controller = settingsWindowController, let window = controller.window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "AuraClip Preferences"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false

        let controller = NSWindowController(window: window)
        self.settingsWindowController = controller
        controller.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
