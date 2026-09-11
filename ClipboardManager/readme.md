# AuraClip — Modern macOS Clipboard Manager
> **AuraClip: The All-in-One, Ethereal Frosted Glass Clipboard for macOS**

## Overview

macOS's built-in clipboard only holds one item at a time. This app should sit in the menu bar, silently track everything copied to the clipboard, and let the user recall any previous item via a global keyboard shortcut.

## Core Features

1. **Clipboard History Tracking**
   - Continuously monitor the system clipboard (`NSPasteboard`) for changes.
   - Detect new copy events and store each new item (do not store duplicates of the immediately preceding item).
   - Support these content types: plain text, rich text (RTF), images, and file references (file paths copied from Finder).

2. **Global Hotkey**
   - Register a global keyboard shortcut (default: `Cmd+Shift+V`) that opens the clipboard history popup from anywhere in macOS, regardless of which app is focused.
   - Shortcut should be user-configurable in Settings.

3. **History Popup UI**
   - A small, borderless popup window (or menu-bar dropdown) showing a scrollable list of recent clipboard items, most recent first.
   - Each item shows a short preview (truncated text, thumbnail for images, filename for files) and a relative timestamp ("2m ago").
   - Keyboard navigation: arrow keys to move selection, `Enter` to paste, `Esc` to dismiss.
   - Fuzzy search/filter box at the top to search through history by typing.
   - Clicking or pressing Enter on an item should:
     a. Set that item back onto the system pasteboard.
     b. Simulate `Cmd+V` in the previously active application (so the paste happens immediately, like Windows' behavior).

4. **Persistence**
   - Store clipboard history locally (SQLite or Core Data) so history survives app restarts.
   - Configurable history limit (default: 200 items) with automatic pruning of oldest entries.
   - Option to pin/favorite specific items so they're never auto-pruned.

5. **Menu Bar Presence**
   - Lives in the macOS menu bar (status bar) with a simple icon.
   - Left-click opens the history popup; right-click (or a menu item) opens Settings/Preferences.
   - Option to launch at login.

6. **Settings / Preferences Window**
   - Configure global hotkey.
   - Configure max history size.
   - Toggle which content types to track (text/images/files).
   - Clear all history button.
   - Exclude specific apps from being tracked (e.g., don't record copies from a password manager).
   - Launch-at-login toggle.

7. **Privacy / Security**
   - Do NOT track clipboard content when the source app is a known password manager (e.g., 1Password, Bitwarden) — check against an exclusion list.
   - All data stored locally; no network calls, no analytics, no external storage.

## Technical Requirements

- **Language/Framework:** Swift + AppKit (native macOS app). SwiftUI can be used for Settings and popup UI where convenient, but core pasteboard/hotkey logic should use AppKit/Carbon APIs since global hotkeys and pasteboard monitoring need low-level access.
- **Minimum macOS version:** macOS 12 (Monterey) or later.
- **Key APIs:**
  - `NSPasteboard` — reading/writing clipboard content. Poll `NSPasteboard.general.changeCount` on a timer (~0.5s interval) since macOS has no native clipboard-change notification.
  - `NSEvent.addGlobalMonitorForEvents` or a lightweight library (e.g., `HotKey` via Swift Package Manager) — for registering the global keyboard shortcut.
  - `CGEvent` — to simulate the `Cmd+V` keystroke after selecting a history item.
  - `SQLite` (via `SQLite.swift` or raw `Core Data`) — for persistent storage.
  - **Accessibility permissions** are required to simulate keystrokes (`CGEvent.post`) and to detect the frontmost app before paste-back. Prompt the user to grant Accessibility access in System Settings on first launch.

## Suggested Project Structure

```
ClipboardManager/
├── ClipboardManagerApp.swift        # App entry point, menu bar setup
├── Core/
│   ├── ClipboardMonitor.swift       # Polls NSPasteboard, detects changes
│   ├── ClipboardItem.swift          # Model for a clipboard entry
│   ├── ClipboardStore.swift         # SQLite/CoreData persistence layer
│   └── HotkeyManager.swift          # Global shortcut registration
├── UI/
│   ├── HistoryPopupView.swift       # Main popup list UI (SwiftUI)
│   ├── HistoryItemRow.swift         # Single row in the list
│   ├── SettingsView.swift           # Preferences window
│   └── MenuBarController.swift      # Status bar icon + menu
├── Utilities/
│   ├── PasteSimulator.swift         # Simulates Cmd+V via CGEvent
│   └── AppExclusionList.swift       # Password manager exclusion logic
└── Resources/
    └── Assets.xcassets              # Menu bar icons
```

## Development Steps (suggested order)

1. Scaffold a basic macOS menu bar app (no dock icon, `LSUIElement = true` in Info.plist).
2. Implement `ClipboardMonitor` with polling + `ClipboardItem` model.
3. Wire up local persistence (start simple with an in-memory array, then add SQLite/Core Data).
4. Build the history popup UI with a static list first, then connect it to live data.
5. Add global hotkey to toggle the popup.
6. Implement paste-back: set pasteboard + simulate `Cmd+V`.
7. Add Settings window (hotkey config, history limit, exclusions).
8. Add launch-at-login support (`SMAppService` on macOS 13+, or `ServiceManagement` framework for older versions).
9. Polish: icons, keyboard navigation in the popup, search/filter.
10. Test Accessibility permission flow and password-manager exclusion behavior.

## Distribution Notes

- For direct distribution (outside the Mac App Store), the app needs to be code-signed and notarized by Apple, otherwise Gatekeeper will block it on other machines.
- If targeting the Mac App Store, note that sandboxing restrictions may complicate global hotkey registration and `CGEvent` posting — review App Sandbox entitlements carefully before choosing that distribution path.

## Reference Apps (for behavior inspiration, not code copying)

- Maccy (open source, Swift — good reference for architecture)
- CopyClip
- Paste
- Alfred's clipboard history feature