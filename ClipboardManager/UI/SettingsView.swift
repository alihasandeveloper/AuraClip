//
//  SettingsView.swift
//  ClipboardManager
//

import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var store = ClipboardStore.shared
    @ObservedObject var launchHelper = LaunchAtLoginHelper.shared
    @ObservedObject var hotkeyManager = HotkeyManager.shared

    @State private var soundEnabled: Bool = SoundManager.shared.isSoundEnabled
    @State private var autoPasteEnabled: Bool = PasteSimulator.shared.isAutoPasteEnabled
    @State private var excludedApps: [String] = AppExclusionList.shared.excludedBundleIDs
    @State private var newBundleID: String = ""
    @State private var selectedTab: SettingsTab = .general
    @State private var isAccessibilityTrusted: Bool = PasteSimulator.isAccessibilityGranted
    @State private var showClearAllAlert: Bool = false

    enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case shortcuts = "Shortcuts"
        case contentTypes = "Content Types"
        case exclusions = "Exclusions"
        case permissions = "Permissions"
        case about = "About"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .shortcuts: return "command"
            case .contentTypes: return "square.stack.3d.up"
            case .exclusions: return "hand.raised"
            case .permissions: return "lock.shield"
            case .about: return "info.circle"
            }
        }
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            shortcutsTab
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
                .tag(SettingsTab.shortcuts)

            contentTypesTab
                .tabItem {
                    Label("Content Types", systemImage: "square.stack.3d.up")
                }
                .tag(SettingsTab.contentTypes)

            exclusionsTab
                .tabItem {
                    Label("Exclusions", systemImage: "hand.raised")
                }
                .tag(SettingsTab.exclusions)

            permissionsTab
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
                .tag(SettingsTab.permissions)

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 520, height: 420)
        .padding(16)
        .onAppear {
            refreshStates()
        }
    }

    private func refreshStates() {
        soundEnabled = SoundManager.shared.isSoundEnabled
        autoPasteEnabled = PasteSimulator.shared.isAutoPasteEnabled
        excludedApps = AppExclusionList.shared.excludedBundleIDs
        isAccessibilityTrusted = PasteSimulator.isAccessibilityGranted
        launchHelper.refreshState()
    }

    @ObservedObject var soundManager = SoundManager.shared

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section(header: Text("Startup & Integration").font(.headline)) {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchHelper.isEnabled },
                    set: { launchHelper.setEnabled($0) }
                ))

                Toggle("Automatically paste selected item (Cmd+V simulation)", isOn: $autoPasteEnabled)
                    .onChange(of: autoPasteEnabled) { newValue in
                        PasteSimulator.shared.isAutoPasteEnabled = newValue
                    }
            }

            Section(header: Text("Sound Effects & Audio Feedback").font(.headline)) {
                Toggle("Enable Sound Effects (Copy, Paste, Pin, Delete)", isOn: $soundManager.isSoundEnabled)

                if soundManager.isSoundEnabled {
                    HStack(spacing: 8) {
                        Text("Test sound:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Copy 🎵") {
                            SoundManager.shared.playCopySound()
                        }
                        .controlSize(.small)

                        Button("Paste 🎵") {
                            SoundManager.shared.playPasteSound()
                        }
                        .controlSize(.small)

                        Button("Pin 🎵") {
                            SoundManager.shared.playPinSound()
                        }
                        .controlSize(.small)

                        Button("Delete 🎵") {
                            SoundManager.shared.playDeleteSound()
                        }
                        .controlSize(.small)
                    }
                    .padding(.top, 2)
                }
            }

            Section(header: Text("History Storage").font(.headline)) {
                Picker("Maximum History Items:", selection: $store.maxHistoryItems) {
                    Text("50 items").tag(50)
                    Text("100 items").tag(100)
                    Text("200 items (Default)").tag(200)
                    Text("500 items").tag(500)
                    Text("1,000 items").tag(1000)
                    Text("Unlimited").tag(0)
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Current items: \(store.items.count) (\(store.items.filter { $0.isPinned }.count) pinned)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear Unpinned History") {
                        store.clearHistory()
                    }

                    Button("Clear All...") {
                        showClearAllAlert = true
                    }
                    .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
        }
        .padding(10)
        .alert(isPresented: $showClearAllAlert) {
            Alert(
                title: Text("Clear entire history?"),
                message: Text("This will permanently remove all clipboard items including pinned ones."),
                primaryButton: .destructive(Text("Clear All")) {
                    store.clearAllIncludingPinned()
                },
                secondaryButton: .cancel()
            )
        }
    }

    @State private var isRecordingShortcut: Bool = false
    @State private var localKeyMonitor: Any? = nil

    // MARK: - Shortcuts Tab

    private var shortcutsTab: some View {
        Form {
            Section(header: Text("Global Activation Shortcut").font(.headline)) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Current Shortcut:")
                            .font(.system(size: 13, weight: .medium))
                        Text("Opens clipboard history from anywhere in macOS.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Interactive Shortcut Recorder Button
                    Button(action: {
                        toggleRecordingShortcut()
                    }) {
                        HStack(spacing: 6) {
                            if isRecordingShortcut {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                Text("Type shortcut keys...")
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "keyboard")
                                    .font(.system(size: 12))
                                Text(hotkeyManager.shortcutDisplay)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isRecordingShortcut ? Color.red.opacity(0.12) : Color.primary.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isRecordingShortcut ? Color.red : Color.primary.opacity(0.15), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help(isRecordingShortcut ? "Press any key combination now" : "Click to record a new custom global shortcut")
                }

                if isRecordingShortcut {
                    Text("💡 Press your desired key combination (e.g. ⌘⇧V, ⌥Space, ⌃⌥V). Press Esc to cancel.")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.vertical, 2)
                }

                Divider()
                    .padding(.vertical, 4)

                Text("Or choose a popular preset:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button("⌘ ⇧ V (Default)") {
                        hotkeyManager.updateHotkey(keyCode: UInt32(0x09), carbonModifiers: UInt32(0x0100 | 0x0200))
                    }
                    Button("⌥ Space") {
                        hotkeyManager.updateHotkey(keyCode: UInt32(0x31), carbonModifiers: UInt32(0x0800))
                    }
                    Button("⌃ ⌥ V") {
                        hotkeyManager.updateHotkey(keyCode: UInt32(0x09), carbonModifiers: UInt32(0x1000 | 0x0800))
                    }
                    Button("⌘ ⌥ V") {
                        hotkeyManager.updateHotkey(keyCode: UInt32(0x09), carbonModifiers: UInt32(0x0100 | 0x0800))
                    }
                }
            }

            Section(header: Text("Popup Keyboard Navigation").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    shortcutRow(keys: "↑ / ↓", desc: "Select previous / next item")
                    shortcutRow(keys: "Tab / ⇧Tab", desc: "Switch category tab next / previous")
                    shortcutRow(keys: "← / →", desc: "Switch category tab left / right")
                    shortcutRow(keys: "↵ (Return)", desc: "Paste selected item into previous app")
                    shortcutRow(keys: "⌘1 ... ⌘9", desc: "Instantly quick paste item by index")
                    shortcutRow(keys: "⌘P", desc: "Pin / unpin selected item")
                    shortcutRow(keys: "Esc", desc: "Dismiss popup")
                }
            }
        }
        .padding(10)
        .onDisappear {
            stopRecordingShortcut()
        }
    }

    private func toggleRecordingShortcut() {
        if isRecordingShortcut {
            stopRecordingShortcut()
        } else {
            startRecordingShortcut()
        }
    }

    private func startRecordingShortcut() {
        isRecordingShortcut = true
        stopRecordingShortcutMonitor()

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Esc cancels recording
            if event.keyCode == 53 {
                self.stopRecordingShortcut()
                return nil
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            var carbonMods: UInt32 = 0
            if flags.contains(.command) { carbonMods |= UInt32(0x0100) } // cmdKey
            if flags.contains(.shift) { carbonMods |= UInt32(0x0200) }   // shiftKey
            if flags.contains(.option) { carbonMods |= UInt32(0x0800) }  // optionKey
            if flags.contains(.control) { carbonMods |= UInt32(0x1000) } // controlKey

            // If no modifiers, allow function keys or space
            let keyCode = UInt32(event.keyCode)
            HotkeyManager.shared.updateHotkey(keyCode: keyCode, carbonModifiers: carbonMods)

            self.stopRecordingShortcut()
            return nil
        }
    }

    private func stopRecordingShortcut() {
        isRecordingShortcut = false
        stopRecordingShortcutMonitor()
    }

    private func stopRecordingShortcutMonitor() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
    }

    private func shortcutRow(keys: String, desc: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .frame(width: 90, alignment: .leading)

            Text(desc)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Content Types Tab

    private var contentTypesTab: some View {
        Form {
            Section(header: Text("Tracked Clipboard Content Types").font(.headline)) {
                Toggle(isOn: $store.trackText) {
                    Label("Plain Text & Code Snippets", systemImage: "doc.text")
                }
                Toggle(isOn: $store.trackRichText) {
                    Label("Rich Text (RTF & HTML formatting)", systemImage: "text.alignleft")
                }
                Toggle(isOn: $store.trackImages) {
                    Label("Images & Screenshots (PNG, TIFF, JPEG)", systemImage: "photo")
                }
                Toggle(isOn: $store.trackFiles) {
                    Label("Files & Folders copied from Finder", systemImage: "folder")
                }
            }
        }
        .padding(10)
    }

    // MARK: - Exclusions Tab

    private var exclusionsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Excluded Applications")
                .font(.headline)
            Text("Clipboard content copied from these apps will be ignored to protect sensitive data.")
                .font(.caption)
                .foregroundColor(.secondary)

            List {
                ForEach(excludedApps, id: \.self) { bundleID in
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.orange)
                        Text(bundleID)
                            .font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Button(action: {
                            AppExclusionList.shared.remove(bundleIdentifier: bundleID)
                            excludedApps = AppExclusionList.shared.excludedBundleIDs
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 160)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                TextField("Add bundle ID (e.g. com.example.app)", text: $newBundleID)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    guard !newBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    AppExclusionList.shared.add(bundleIdentifier: newBundleID)
                    excludedApps = AppExclusionList.shared.excludedBundleIDs
                    newBundleID = ""
                }
                .disabled(newBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Reset Defaults") {
                    AppExclusionList.shared.resetToDefaults()
                    excludedApps = AppExclusionList.shared.excludedBundleIDs
                }
            }
        }
        .padding(10)
    }

    // MARK: - Permissions Tab

    private var permissionsTab: some View {
        VStack(spacing: 16) {
            Image(systemName: isAccessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(isAccessibilityTrusted ? .green : .orange)

            Text(isAccessibilityTrusted ? "Accessibility Permission Granted" : "Accessibility Permission Required")
                .font(.headline)

            Text(isAccessibilityTrusted
                 ? "Clipboard Manager has full permission to simulate Cmd+V paste and focus previous applications."
                 : "macOS requires Accessibility permissions to allow Clipboard Manager to detect the active app and paste items automatically via simulated keystrokes.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button("Refresh Status") {
                    isAccessibilityTrusted = PasteSimulator.isAccessibilityGranted
                }

                if !isAccessibilityTrusted {
                    Button("Grant Accessibility Access") {
                        PasteSimulator.requestAccessibilityPermission()
                        PasteSimulator.openAccessibilitySettings()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)

            VStack(spacing: 4) {
                Text("AuraClip")
                    .font(.title2.bold())
                Text("Version 1.0 • The Modern Aura Clipboard for Mac")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundColor(.green)
                    Text("100% Private & Local: All history is stored securely on your Mac.")
                        .font(.caption)
                }
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("Zero cloud tracking, no analytics, no external servers.")
                        .font(.caption)
                }
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.blue)
                    Text("Automatic exclusion of password managers & concealed data.")
                        .font(.caption)
                }
            }
            .padding(12)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
    }
}
