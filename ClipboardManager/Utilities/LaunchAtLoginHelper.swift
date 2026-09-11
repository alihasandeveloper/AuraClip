//
//  LaunchAtLoginHelper.swift
//  ClipboardManager
//

import Foundation
import ServiceManagement
import Combine

public final class LaunchAtLoginHelper: ObservableObject {
    public static let shared = LaunchAtLoginHelper()

    @Published public var isEnabled: Bool = false

    private init() {
        refreshState()
    }

    public func refreshState() {
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: "ClipboardManager.LaunchAtLogin")
        }
    }

    public func setEnabled(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                isEnabled = (SMAppService.mainApp.status == .enabled)
            } catch {
                NSLog("[ClipboardManager] LaunchAtLogin error: \(error.localizedDescription)")
                isEnabled = (SMAppService.mainApp.status == .enabled)
            }
        } else {
            UserDefaults.standard.set(enable, forKey: "ClipboardManager.LaunchAtLogin")
            isEnabled = enable
        }
    }
}
