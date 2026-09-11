//
//  AppExclusionList.swift
//  ClipboardManager
//

import Foundation
import AppKit

public final class AppExclusionList {
    public static let shared = AppExclusionList()

    private let userDefaultsKey = "ClipboardManager.ExcludedBundleIDs"

    // Default list of password managers and sensitive apps
    private let defaultExclusions: Set<String> = [
        "com.agilebits.onepassword7",
        "com.1password.1password",
        "com.1password.onepassword",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
        "com.apple.keychainaccess",
        "org.keepassxc.keepassxc",
        "com.dashlane.dashlane",
        "com.enpass.enpass-mac",
        "com.nordpass.macos",
        "com.roboform.mac",
        "org.whispersystems.signal",
        "com.apple.Pass-Viewer"
    ]

    private init() {
        if UserDefaults.standard.object(forKey: userDefaultsKey) == nil {
            UserDefaults.standard.set(Array(defaultExclusions), forKey: userDefaultsKey)
        }
    }

    public var excludedBundleIDs: [String] {
        get {
            let list = UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? Array(defaultExclusions)
            return list.sorted()
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }

    public func isExcluded(bundleIdentifier: String?) -> Bool {
        guard let bundleID = bundleIdentifier?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
              !bundleID.isEmpty else {
            return false
        }
        
        let exclusions = Set(excludedBundleIDs.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
        return exclusions.contains(bundleID)
    }

    public func add(bundleIdentifier: String) {
        var current = Set(excludedBundleIDs)
        current.insert(bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines))
        excludedBundleIDs = Array(current).sorted()
    }

    public func remove(bundleIdentifier: String) {
        var current = Set(excludedBundleIDs)
        current.remove(bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines))
        excludedBundleIDs = Array(current).sorted()
    }

    public func resetToDefaults() {
        excludedBundleIDs = Array(defaultExclusions).sorted()
    }
}
