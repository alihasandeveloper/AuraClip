//
//  HistoryPopupPanel.swift
//  ClipboardManager
//

import AppKit
import SwiftUI

public final class HistoryPopupPanel: NSPanel {
    public static let shared = HistoryPopupPanel()

    public private(set) var previousFrontmostApp: NSRunningApplication?
    private var localKeyMonitor: Any?

    public override var canBecomeKey: Bool {
        return true
    }

    public override var canBecomeMain: Bool {
        return true
    }

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 540),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isMovableByWindowBackground = true
        self.isFloatingPanel = true
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupContentView()
    }

    private func setupContentView() {
        let rootView = HistoryPopupView(
            onPasteItem: { [weak self] item in
                self?.pasteAndClose(item: item)
            },
            onOpenSettings: { [weak self] in
                self?.closePanel()
                MenuBarController.shared.openSettingsWindow()
            },
            onClose: { [weak self] in
                self?.closePanel()
            }
        )

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.cornerRadius = 16
        hostingView.layer?.masksToBounds = true
        self.contentView = hostingView
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = true
        self.invalidateShadow()
    }

    public func togglePanel(near mouseLocation: NSPoint? = nil) {
        if isVisible {
            closePanel()
        } else {
            openPanel(near: mouseLocation)
        }
    }

    public func openPanel(near mouseLocation: NSPoint? = nil) {
        // Record frontmost app before we show the popup
        let frontApp = NSWorkspace.shared.frontmostApplication
        if frontApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousFrontmostApp = frontApp
        }

        ClipboardStore.shared.selectedIndex = 0
        ClipboardStore.shared.searchQuery = ""

        positionWindow(near: mouseLocation)
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        startLocalKeyMonitoring()
    }

    public func closePanel() {
        stopLocalKeyMonitoring()
        self.orderOut(nil)
    }

    private func positionWindow(near mouseLocation: NSPoint?) {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        let panelSize = self.frame.size

        if let loc = mouseLocation {
            var originX = loc.x - (panelSize.width / 2)
            var originY = loc.y - panelSize.height - 8

            // Keep within screen bounds
            originX = max(screenRect.minX + 10, min(originX, screenRect.maxX - panelSize.width - 10))
            originY = max(screenRect.minY + 10, min(originY, screenRect.maxY - panelSize.height - 10))

            self.setFrameOrigin(NSPoint(x: originX, y: originY))
        } else {
            // Position near menu bar or center top of screen
            let originX = screenRect.midX - (panelSize.width / 2)
            let originY = screenRect.maxY - panelSize.height - 40
            self.setFrameOrigin(NSPoint(x: originX, y: originY))
        }
    }

    private func pasteAndClose(item: ClipboardItem) {
        let target = self.previousFrontmostApp
        closePanel()
        PasteSimulator.shared.paste(item: item, targetApp: target)
    }

    // MARK: - Key Event Handling

    private func startLocalKeyMonitoring() {
        stopLocalKeyMonitoring()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.handleKeyDown(event: event) {
                return nil
            }
            return event
        }
    }

    private func stopLocalKeyMonitoring() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    private func handleKeyDown(event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Esc key closes popup
        if event.keyCode == 53 {
            closePanel()
            return true
        }

        // Cmd + , -> Open preferences
        if flags.contains(.command) && event.charactersIgnoringModifiers == "," {
            closePanel()
            MenuBarController.shared.openSettingsWindow()
            return true
        }

        // Cmd + Q -> Quit
        if flags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApplication.shared.terminate(nil)
            return true
        }

        // Option + Cmd + Delete -> Clear
        if flags.contains(.command) && flags.contains(.option) && event.keyCode == 51 {
            ClipboardStore.shared.clearHistory()
            return true
        }

        // Cmd + 1..9 quick paste
        if flags.contains(.command) {
            if let chars = event.charactersIgnoringModifiers, let num = Int(chars), num >= 1, num <= 9 {
                let items = ClipboardStore.shared.filteredItems
                let targetIndex = num - 1
                if targetIndex < items.count {
                    pasteAndClose(item: items[targetIndex])
                    return true
                }
            }
            // Cmd + P toggle pin
            if event.charactersIgnoringModifiers?.lowercased() == "p" {
                let items = ClipboardStore.shared.filteredItems
                let sel = ClipboardStore.shared.selectedIndex
                if sel < items.count {
                    ClipboardStore.shared.togglePin(id: items[sel].id)
                    return true
                }
            }
        }

        // Tab key (keyCode 48) - Switch tabs
        if event.keyCode == 48 {
            if flags.contains(.shift) {
                ClipboardStore.shared.previousTab()
            } else {
                ClipboardStore.shared.nextTab()
            }
            return true
        }

        // Left Arrow (keyCode 123) - Switch tab left
        if event.keyCode == 123 {
            ClipboardStore.shared.previousTab()
            return true
        }

        // Right Arrow (keyCode 124) - Switch tab right
        if event.keyCode == 124 {
            ClipboardStore.shared.nextTab()
            return true
        }

        // Down Arrow (keyCode 125) - Navigate items down
        if event.keyCode == 125 {
            ClipboardStore.shared.selectNextItem()
            return true
        }

        // Up Arrow (keyCode 126) - Navigate items up
        if event.keyCode == 126 {
            ClipboardStore.shared.selectPreviousItem()
            return true
        }

        // Enter / Return (keyCode 36) - Paste selected item
        if event.keyCode == 36 {
            let items = ClipboardStore.shared.filteredItems
            let sel = ClipboardStore.shared.selectedIndex
            if !items.isEmpty && sel >= 0 && sel < items.count {
                pasteAndClose(item: items[sel])
                return true
            }
        }

        // Allow all text typing to pass through to Search TextField!
        return false
    }

    public override func resignKey() {
        super.resignKey()
        closePanel()
    }
}
