//
//  HistoryItemRow.swift
//  ClipboardManager
//

import SwiftUI
import AppKit

struct HistoryItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // High-Tech Glass Thumbnail Container
            leadingThumbnailView
                .frame(width: 38, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.05))
                )
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isSelected ? 0.4 : 0.15),
                                    Color.white.opacity(isSelected ? 0.15 : 0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1)

            // Content Preview & Meta Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(item.displayTitle)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .default))
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .white : .primary)

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(isSelected ? Color.yellow : Color.orange)
                            .shadow(color: Color.orange.opacity(0.5), radius: 3)
                    }

                    Spacer()

                    // Quick shortcut glass pill (⌘1 - ⌘9)
                    if index < 9 {
                        Text("⌘\(index + 1)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(isSelected ? 0.35 : 0.1), lineWidth: 0.6)
                            )
                            .foregroundColor(isSelected ? .white : .secondary)
                    }

                    Text(item.formattedTimeAgo)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary.opacity(0.8))
                }

                if !item.displaySubtitle.isEmpty {
                    Text(item.displaySubtitle)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                }

                // Source App & Type Details
                HStack(spacing: 5) {
                    if let app = item.sourceAppName, !app.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "app.badge.fill")
                                .font(.system(size: 7))
                            Text(app)
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
                    }

                    Text("•")
                        .font(.system(size: 7))
                        .foregroundColor(isSelected ? .white.opacity(0.5) : .secondary.opacity(0.4))

                    Text(item.contentType.displayName)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary.opacity(0.8))
                }
            }

            // Trailing Action Glass Buttons on Hover
            if isHovered || isSelected {
                HStack(spacing: 4) {
                    Button(action: onTogglePin) {
                        Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white : (item.isPinned ? .orange : .secondary))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.1))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin Item" : "Pin Item")

                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isSelected ? .white : Color.red.opacity(0.9))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(isSelected ? Color.white.opacity(0.22) : Color.red.opacity(0.15))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Delete from history")
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isSelected
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.05, green: 0.48, blue: 0.98),
                                    Color(red: 0.02, green: 0.38, blue: 0.88)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        : (isHovered ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(Color.clear))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isSelected
                        ? LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : (isHovered
                           ? LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                           )
                           : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)),
                    lineWidth: 1
                )
        )
        .shadow(color: isSelected ? Color.blue.opacity(0.35) : Color.clear, radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                self.isHovered = hovering
            }
        }
        .onTapGesture {
            onSelect()
        }
    }

    @ViewBuilder
    private var leadingThumbnailView: some View {
        switch item.contentType {
        case .image:
            if let imgName = item.imageFileName,
               let nsImage = ClipboardStore.shared.loadImage(named: imgName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 38)
                    .clipped()
            } else {
                Image(systemName: "photo.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .white : .blue)
            }
        case .color:
            if let hex = item.plainText, let color = parseColor(hex: hex) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: color))
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color(nsColor: color).opacity(0.4), radius: 3)
            } else {
                Image(systemName: "paintpalette.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .white : .purple)
            }
        case .file:
            Image(systemName: "folder.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 15))
                .foregroundColor(isSelected ? .white : .orange)
        case .url:
            Image(systemName: "link")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .cyan)
        case .richText:
            Image(systemName: "text.alignleft")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 15))
                .foregroundColor(isSelected ? .white : .indigo)
        case .text:
            Image(systemName: "doc.text.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 15))
                .foregroundColor(isSelected ? .white : .blue)
        }
    }

    private func parseColor(hex: String) -> NSColor? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        guard cleanHex.count == 6 || cleanHex.count == 8 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)

        if cleanHex.count == 6 {
            let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgbValue & 0x0000FF) / 255.0
            return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
        } else {
            let r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgbValue & 0x000000FF) / 255.0
            return NSColor(srgbRed: r, green: g, blue: b, alpha: a)
        }
    }
}
