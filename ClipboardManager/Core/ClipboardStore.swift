//
//  ClipboardStore.swift
//  ClipboardManager
//

import Foundation
import AppKit
import SwiftUI
import Combine
import CryptoKit

public final class ClipboardStore: ObservableObject {
    public static let shared = ClipboardStore()

    private let maxHistoryKey = "ClipboardManager.MaxHistoryItems"
    private let trackTextKey = "ClipboardManager.TrackText"
    private let trackRichTextKey = "ClipboardManager.TrackRichText"
    private let trackImagesKey = "ClipboardManager.TrackImages"
    private let trackFilesKey = "ClipboardManager.TrackFiles"

    @Published public var items: [ClipboardItem] = []
    @Published public var searchQuery: String = "" {
        didSet { selectedIndex = 0 }
    }
    @Published public var selectedTypeFilter: ClipboardContentType? = nil {
        didSet { selectedIndex = 0 }
    }
    @Published public var showOnlyPinned: Bool = false {
        didSet { selectedIndex = 0 }
    }
    @Published public var isPaused: Bool = false
    @Published public var selectedIndex: Int = 0

    // MARK: - Selection Navigation Helpers

    public func selectNextItem() {
        let count = filteredItems.count
        if count > 0 {
            selectedIndex = min(selectedIndex + 1, count - 1)
        }
    }

    public func selectPreviousItem() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }

    public var selectedItem: ClipboardItem? {
        let items = filteredItems
        guard selectedIndex >= 0 && selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    // MARK: - Tab Index Helpers

    public var currentTabIndex: Int {
        if showOnlyPinned {
            return 1
        }
        if let type = selectedTypeFilter, let idx = ClipboardContentType.allCases.firstIndex(of: type) {
            return 2 + idx
        }
        return 0 // All
    }

    public var currentTabId: String {
        if showOnlyPinned {
            return "tab_pinned"
        }
        if let type = selectedTypeFilter {
            return "tab_\(type.rawValue)"
        }
        return "tab_all"
    }

    public func setTabIndex(_ index: Int) {
        let totalTabs = 2 + ClipboardContentType.allCases.count
        let safeIndex = (index % totalTabs + totalTabs) % totalTabs

        selectedIndex = 0
        if safeIndex == 0 {
            selectedTypeFilter = nil
            showOnlyPinned = false
        } else if safeIndex == 1 {
            selectedTypeFilter = nil
            showOnlyPinned = true
        } else {
            let typeIndex = safeIndex - 2
            if typeIndex < ClipboardContentType.allCases.count {
                showOnlyPinned = false
                selectedTypeFilter = ClipboardContentType.allCases[typeIndex]
            }
        }
    }

    public func nextTab() {
        setTabIndex(currentTabIndex + 1)
    }

    public func previousTab() {
        setTabIndex(currentTabIndex - 1)
    }

    @Published public var maxHistoryItems: Int {
        didSet {
            UserDefaults.standard.set(maxHistoryItems, forKey: maxHistoryKey)
            pruneExcessItems()
        }
    }

    @Published public var trackText: Bool {
        didSet { UserDefaults.standard.set(trackText, forKey: trackTextKey) }
    }
    @Published public var trackRichText: Bool {
        didSet { UserDefaults.standard.set(trackRichText, forKey: trackRichTextKey) }
    }
    @Published public var trackImages: Bool {
        didSet { UserDefaults.standard.set(trackImages, forKey: trackImagesKey) }
    }
    @Published public var trackFiles: Bool {
        didSet { UserDefaults.standard.set(trackFiles, forKey: trackFilesKey) }
    }

    private let fileManager = FileManager.default
    private let saveQueue = DispatchQueue(label: "com.boomdevs.ClipboardManager.saveQueue", qos: .utility)
    private var imageMemoryCache = NSCache<NSString, NSImage>()

    private var appSupportDirectory: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("ClipboardManager", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var imagesDirectory: URL {
        let dir = appSupportDirectory.appendingPathComponent("Images", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var databaseFileURL: URL {
        return appSupportDirectory.appendingPathComponent("history.json")
    }

    private init() {
        self.maxHistoryItems = UserDefaults.standard.object(forKey: maxHistoryKey) != nil ? UserDefaults.standard.integer(forKey: maxHistoryKey) : 200
        self.trackText = UserDefaults.standard.object(forKey: trackTextKey) != nil ? UserDefaults.standard.bool(forKey: trackTextKey) : true
        self.trackRichText = UserDefaults.standard.object(forKey: trackRichTextKey) != nil ? UserDefaults.standard.bool(forKey: trackRichTextKey) : true
        self.trackImages = UserDefaults.standard.object(forKey: trackImagesKey) != nil ? UserDefaults.standard.bool(forKey: trackImagesKey) : true
        self.trackFiles = UserDefaults.standard.object(forKey: trackFilesKey) != nil ? UserDefaults.standard.bool(forKey: trackFilesKey) : true

        loadHistory()
    }

    // MARK: - Filtered Items

    public var filteredItems: [ClipboardItem] {
        items.filter { item in
            if showOnlyPinned && !item.isPinned {
                return false
            }
            if let filter = selectedTypeFilter, item.contentType != filter {
                return false
            }
            if !searchQuery.isEmpty && !item.matches(query: searchQuery) {
                return false
            }
            return true
        }
    }

    // MARK: - Mutations

    public func addItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            // If identical to the most recent item, ignore
            if let first = self.items.first, first.contentHash == item.contentHash {
                return
            }

            // If it exists previously, remove the old one (preserve pinned if pinned)
            var newItem = item
            if let existingIndex = self.items.firstIndex(where: { $0.contentHash == item.contentHash }) {
                if self.items[existingIndex].isPinned {
                    newItem.isPinned = true
                }
                self.items.remove(at: existingIndex)
            }

            self.items.insert(newItem, at: 0)
            self.pruneExcessItems()
            self.scheduleSave()
        }
    }

    public func removeItem(id: UUID) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                let item = self.items[index]
                if let imgName = item.imageFileName {
                    self.deleteImageFile(named: imgName)
                }
                self.items.remove(at: index)
                SoundManager.shared.playDeleteSound()
                self.scheduleSave()
            }
        }
    }

    public func togglePin(id: UUID) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                self.items[index].isPinned.toggle()
                SoundManager.shared.playPinSound()
                self.scheduleSave()
            }
        }
    }

    public func clearHistory() {
        DispatchQueue.main.async {
            // Keep pinned items, delete unpinned
            let unpinned = self.items.filter { !$0.isPinned }
            for item in unpinned {
                if let img = item.imageFileName {
                    self.deleteImageFile(named: img)
                }
            }
            self.items.removeAll { !$0.isPinned }
            self.scheduleSave()
        }
    }

    public func clearAllIncludingPinned() {
        DispatchQueue.main.async {
            for item in self.items {
                if let img = item.imageFileName {
                    self.deleteImageFile(named: img)
                }
            }
            self.items.removeAll()
            self.scheduleSave()
        }
    }

    private func pruneExcessItems() {
        guard maxHistoryItems > 0 else { return }
        let pinnedCount = items.filter { $0.isPinned }.count
        let allowedUnpinned = max(0, maxHistoryItems - pinnedCount)

        var unpinnedSeen = 0
        var toKeep: [ClipboardItem] = []

        for item in items {
            if item.isPinned {
                toKeep.append(item)
            } else {
                if unpinnedSeen < allowedUnpinned {
                    toKeep.append(item)
                    unpinnedSeen += 1
                } else {
                    if let img = item.imageFileName {
                        deleteImageFile(named: img)
                    }
                }
            }
        }
        self.items = toKeep
    }

    // MARK: - Image Persistence

    public func saveImagePayload(data: Data) -> (fileName: String, width: Double, height: Double, hash: String)? {
        guard let nsImage = NSImage(data: data) else { return nil }
        
        let hash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
        let fileName = "\(hash).png"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        if fileManager.fileExists(atPath: fileURL.path) {
            imageMemoryCache.setObject(nsImage, forKey: fileName as NSString)
            return (fileName, Double(nsImage.size.width), Double(nsImage.size.height), hash)
        }

        guard let tiffRepresentation = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return nil
        }

        do {
            try pngData.write(to: fileURL)
            imageMemoryCache.setObject(nsImage, forKey: fileName as NSString)
            return (fileName, Double(nsImage.size.width), Double(nsImage.size.height), hash)
        } catch {
            NSLog("[ClipboardManager] Failed to write image payload: \(error)")
            return nil
        }
    }

    public func loadImage(named fileName: String) -> NSImage? {
        if let cached = imageMemoryCache.object(forKey: fileName as NSString) {
            return cached
        }
        let url = imagesDirectory.appendingPathComponent(fileName)
        guard let image = NSImage(contentsOf: url) else { return nil }
        imageMemoryCache.setObject(image, forKey: fileName as NSString)
        return image
    }

    private func deleteImageFile(named fileName: String) {
        imageMemoryCache.removeObject(forKey: fileName as NSString)
        let url = imagesDirectory.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Disk Persistence

    private func scheduleSave() {
        let currentItems = self.items
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(currentItems)
                try data.write(to: self.databaseFileURL, options: .atomic)
            } catch {
                NSLog("[ClipboardManager] Failed to save history: \(error)")
            }
        }
    }

    private func loadHistory() {
        saveQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.fileManager.fileExists(atPath: self.databaseFileURL.path) else { return }
            do {
                let data = try Data(contentsOf: self.databaseFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let loaded = try decoder.decode([ClipboardItem].self, from: data)
                DispatchQueue.main.async {
                    self.items = loaded
                }
            } catch {
                NSLog("[ClipboardManager] Failed to load history: \(error)")
            }
        }
    }
}
