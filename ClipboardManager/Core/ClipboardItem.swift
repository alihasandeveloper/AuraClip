//
//  ClipboardItem.swift
//  ClipboardManager
//

import Foundation
import AppKit
import CryptoKit

public enum ClipboardContentType: String, Codable, CaseIterable {
    case text
    case richText
    case image
    case file
    case url
    case color

    public var displayName: String {
        switch self {
        case .text: return "Text"
        case .richText: return "Rich Text"
        case .image: return "Images"
        case .file: return "Files"
        case .url: return "Links"
        case .color: return "Colors"
        }
    }

    public var systemIcon: String {
        switch self {
        case .text: return "doc.text"
        case .richText: return "text.alignleft"
        case .image: return "photo"
        case .file: return "folder"
        case .url: return "link"
        case .color: return "paintpalette"
        }
    }
}

public struct ClipboardItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var contentType: ClipboardContentType
    public var plainText: String?
    public var rtfData: Data?
    public var htmlContent: String?
    public var imageFileName: String?
    public var imageWidth: Double?
    public var imageHeight: Double?
    public var filePaths: [String]?
    public var createdAt: Date
    public var isPinned: Bool
    public var sourceAppBundleId: String?
    public var sourceAppName: String?
    public var characterCount: Int
    public var byteSize: Int
    public var contentHash: String

    public init(
        id: UUID = UUID(),
        contentType: ClipboardContentType,
        plainText: String? = nil,
        rtfData: Data? = nil,
        htmlContent: String? = nil,
        imageFileName: String? = nil,
        imageWidth: Double? = nil,
        imageHeight: Double? = nil,
        filePaths: [String]? = nil,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        sourceAppBundleId: String? = nil,
        sourceAppName: String? = nil,
        characterCount: Int = 0,
        byteSize: Int = 0,
        contentHash: String = ""
    ) {
        self.id = id
        self.contentType = contentType
        self.plainText = plainText
        self.rtfData = rtfData
        self.htmlContent = htmlContent
        self.imageFileName = imageFileName
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.filePaths = filePaths
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.sourceAppBundleId = sourceAppBundleId
        self.sourceAppName = sourceAppName
        self.characterCount = characterCount
        self.byteSize = byteSize

        if !contentHash.isEmpty {
            self.contentHash = contentHash
        } else {
            // Generate deterministic hash
            switch contentType {
            case .text, .richText, .url, .color:
                let str = plainText ?? ""
                let hash = SHA256.hash(data: Data(str.utf8))
                self.contentHash = hash.compactMap { String(format: "%02x", $0) }.joined()
            case .file:
                let str = (filePaths ?? []).joined(separator: "|")
                let hash = SHA256.hash(data: Data(str.utf8))
                self.contentHash = hash.compactMap { String(format: "%02x", $0) }.joined()
            case .image:
                self.contentHash = imageFileName ?? UUID().uuidString
            }
        }
    }

    public var displayTitle: String {
        switch contentType {
        case .text, .richText:
            if let text = plainText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                let firstLine = text.components(separatedBy: .newlines).first ?? text
                return String(firstLine.prefix(120))
            }
            return "Empty Text"
        case .url:
            if let text = plainText?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                return text
            }
            return "Web Link"
        case .image:
            return "Image"
        case .file:
            if let paths = filePaths, !paths.isEmpty {
                if paths.count == 1 {
                    return URL(fileURLWithPath: paths[0]).lastPathComponent
                } else {
                    let first = URL(fileURLWithPath: paths[0]).lastPathComponent
                    return "\(first) (+\(paths.count - 1) items)"
                }
            }
            return "File"
        case .color:
            return plainText ?? "Color"
        }
    }

    public var displaySubtitle: String {
        switch contentType {
        case .text, .richText:
            if let text = plainText?.trimmingCharacters(in: .whitespacesAndNewlines) {
                let lines = text.components(separatedBy: .newlines)
                if lines.count > 1 {
                    let remaining = lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    if !remaining.isEmpty {
                        return String(remaining.prefix(100))
                    }
                }
            }
            return ""
        case .url:
            if let url = URL(string: plainText ?? ""), let host = url.host {
                return host
            }
            return ""
        case .image:
            if let w = imageWidth, let h = imageHeight {
                return "\(Int(w)) × \(Int(h))"
            }
            return ""
        case .file:
            if let paths = filePaths, let first = paths.first {
                return (first as NSString).deletingLastPathComponent
            }
            return ""
        case .color:
            return ""
        }
    }

    public var formattedTimeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    public func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return true }

        // 1. Match item text / content
        if let text = plainText, text.lowercased().contains(trimmed) {
            return true
        }

        // 2. Match file paths / filenames
        if let paths = filePaths {
            for path in paths {
                if path.lowercased().contains(trimmed) {
                    return true
                }
            }
        }

        // 3. Match source application name
        if let appName = sourceAppName, appName.lowercased().contains(trimmed) {
            return true
        }

        // 4. Match tab names and content types
        if contentType.displayName.lowercased().contains(trimmed) || contentType.rawValue.lowercased().contains(trimmed) {
            return true
        }

        // 5. Match keyword aliases for tabs
        if (trimmed == "pin" || trimmed == "pinned" || trimmed == "favorite" || trimmed == "star") && isPinned {
            return true
        }
        if (trimmed == "img" || trimmed == "image" || trimmed == "images" || trimmed == "photo" || trimmed == "photos" || trimmed == "pic" || trimmed == "screenshot") && contentType == .image {
            return true
        }
        if (trimmed == "txt" || trimmed == "text" || trimmed == "plain" || trimmed == "string" || trimmed == "code") && (contentType == .text || contentType == .richText) {
            return true
        }
        if (trimmed == "rich" || trimmed == "rtf" || trimmed == "html" || trimmed == "formatted") && contentType == .richText {
            return true
        }
        if (trimmed == "file" || trimmed == "files" || trimmed == "folder" || trimmed == "folders" || trimmed == "doc" || trimmed == "docs" || trimmed == "pdf") && contentType == .file {
            return true
        }
        if (trimmed == "link" || trimmed == "links" || trimmed == "url" || trimmed == "urls" || trimmed == "web" || trimmed == "http" || trimmed == "https") && contentType == .url {
            return true
        }
        if (trimmed == "color" || trimmed == "colors" || trimmed == "hex" || trimmed == "rgb" || trimmed == "rgba") && contentType == .color {
            return true
        }

        return false
    }

    public static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        if lhs.id == rhs.id { return true }
        if !lhs.contentHash.isEmpty && !rhs.contentHash.isEmpty {
            return lhs.contentHash == rhs.contentHash
        }
        if lhs.contentType != rhs.contentType { return false }
        if lhs.contentType == .text || lhs.contentType == .url || lhs.contentType == .color {
            return lhs.plainText == rhs.plainText
        }
        if lhs.contentType == .file {
            return lhs.filePaths == rhs.filePaths
        }
        return false
    }
}
