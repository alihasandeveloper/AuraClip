# AuraClip — Modern macOS Clipboard Manager
> **The All-in-One, Ethereal Frosted Glass Clipboard for macOS**

AuraClip is a native macOS menu bar clipboard manager crafted with Swift, SwiftUI, and AppKit. It features a futuristic Apple frosted glass interface, real-time background monitoring, keyboard-first navigation, and zero storage bloat.

---

## ✨ Key Features

- 🧊 **Apple Frosted Glass UI**: Native backdrop blur, borderless floating window, squircle thumbnails, and luminous gradients.
- ⚡ **Full Keyboard Navigation**:
  - `↑` / `↓` : Select & scroll clipboard items.
  - `Tab` / `⇧Tab` : Cycle category tabs.
  - `←` / `→` : Switch category tabs with visual auto-centering.
  - `↵ (Return)` : Paste selected item instantly into active application.
  - `⌘1` – `⌘9` : Direct instant paste by index.
  - `⌘P` : Pin / unpin selected item.
  - `Esc` : Dismiss popup.
- 📋 **Multi-Format Support**: Plain Text, Rich Text (RTF/HTML), Images (PNG/TIFF with SHA-256 deduplication), Files (Finder URLs), Links, and Hex Colors.
- 🔍 **Fuzzy & Tab Search**: Search through content, source apps, or filter tabs by name (`image`, `file`, `code`, `link`, `pinned`).
- ⚙️ **Customizable Shortcuts**: Interactive shortcut recorder in Preferences (default: `⌘⇧V`).
- 🎵 **Sound Effects**: Audio feedback for Copy (`Tink`), Paste (`Pop`), Pin (`Ping`), Delete (`Basso`).
- 🔒 **100% Local & Privacy-First**: Zero tracking, zero telemetry, auto-suppression of password managers (`1Password`, `Bitwarden`, `Keychain`).
- 🚀 **Launch at Login**: Seamless integration via modern `SMAppService`.

---

## 🛠️ Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14+ / Swift 5.7+
- Accessibility Permission (for simulating `Cmd+V` paste)

---

## 💿 Installation

1. Download **`AuraClip.dmg`** from the [Latest Release](https://github.com/alihasandeveloper/AuraClip/releases).
2. Double-click the DMG and drag **AuraClip** into your **Applications** folder.
3. If macOS shows a security prompt (*"AuraClip can't be opened"* or *"damaged"* due to Gatekeeper quarantine on internet downloads), simply run this one command in Terminal:
   ```bash
   xattr -cr /Applications/AuraClip.app
   ```
   *(Or Right-click `AuraClip.app` in Applications ➔ Click **Open** ➔ **Open Anyway**)*.

---

## 🚀 Building & Running from Source

1. Clone the repository:
   ```bash
   git clone git@github.com:alihasandeveloper/AuraClip.git
   cd AuraClip
   ```
2. Open in Xcode:
   ```bash
   open ClipboardManager.xcodeproj
   ```
3. Build and Run (`⌘R`).

---

## 📄 License

MIT License. Designed and developed with ❤️ for macOS.

