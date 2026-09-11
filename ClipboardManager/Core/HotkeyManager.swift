//
//  HotkeyManager.swift
//  ClipboardManager
//

import Foundation
import AppKit
import Carbon
import Combine

private func hotKeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )

    if status == noErr && hotKeyID.signature == 0x434C4950 /* 'CLIP' */ {
        DispatchQueue.main.async {
            HotkeyManager.shared.onHotkeyPressed?()
        }
        return noErr
    }
    return OSStatus(eventNotHandledErr)
}

public final class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()

    public static let hotkeyKeyCodeKey = "ClipboardManager.HotkeyKeyCode"
    public static let hotkeyModifiersKey = "ClipboardManager.HotkeyModifiers"

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    @Published public var shortcutDisplay: String = "⌘ ⇧ V"

    public var onHotkeyPressed: (() -> Void)?

    private init() {
        setupEventHandler()
        loadAndRegister()
    }

    private func setupEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    public func loadAndRegister() {
        let keyCode = UserDefaults.standard.object(forKey: HotkeyManager.hotkeyKeyCodeKey) != nil
            ? UInt32(UserDefaults.standard.integer(forKey: HotkeyManager.hotkeyKeyCodeKey))
            : UInt32(kVK_ANSI_V)

        let modifiers = UserDefaults.standard.object(forKey: HotkeyManager.hotkeyModifiersKey) != nil
            ? UInt32(UserDefaults.standard.integer(forKey: HotkeyManager.hotkeyModifiersKey))
            : UInt32(cmdKey | shiftKey)

        registerHotKey(keyCode: keyCode, carbonModifiers: modifiers)
        updateShortcutDisplay(keyCode: keyCode, carbonModifiers: modifiers)
    }

    public func updateHotkey(keyCode: UInt32, carbonModifiers: UInt32) {
        UserDefaults.standard.set(Int(keyCode), forKey: HotkeyManager.hotkeyKeyCodeKey)
        UserDefaults.standard.set(Int(carbonModifiers), forKey: HotkeyManager.hotkeyModifiersKey)

        registerHotKey(keyCode: keyCode, carbonModifiers: carbonModifiers)
        updateShortcutDisplay(keyCode: keyCode, carbonModifiers: carbonModifiers)
    }

    private func registerHotKey(keyCode: UInt32, carbonModifiers: UInt32) {
        if let existing = hotKeyRef {
            UnregisterEventHotKey(existing)
            hotKeyRef = nil
        }

        let hotKeyID = EventHotKeyID(signature: 0x434C4950 /* 'CLIP' */, id: 1)
        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            NSLog("[ClipboardManager] Failed to register global hotkey. Status: \(status)")
        }
    }

    private func updateShortcutDisplay(keyCode: UInt32, carbonModifiers: UInt32) {
        var symbols: [String] = []
        if (carbonModifiers & UInt32(controlKey)) != 0 { symbols.append("⌃") }
        if (carbonModifiers & UInt32(optionKey)) != 0 { symbols.append("⌥") }
        if (carbonModifiers & UInt32(shiftKey)) != 0 { symbols.append("⇧") }
        if (carbonModifiers & UInt32(cmdKey)) != 0 { symbols.append("⌘") }

        let keyName = keyCodeToString(keyCode: keyCode)
        symbols.append(keyName)
        self.shortcutDisplay = symbols.joined(separator: " ")
    }

    private func keyCodeToString(keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        default: return "Key(\(keyCode))"
        }
    }

    deinit {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
}
