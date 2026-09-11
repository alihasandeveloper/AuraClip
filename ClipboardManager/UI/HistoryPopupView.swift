//
//  HistoryPopupView.swift
//  ClipboardManager
//

import SwiftUI
import AppKit

struct HistoryPopupView: View {
    @ObservedObject var store = ClipboardStore.shared
    let onPasteItem: (ClipboardItem) -> Void
    let onOpenSettings: () -> Void
    let onClose: () -> Void

    @FocusState private var isSearchFocused: Bool
    @State private var isAccessibilityTrusted: Bool = PasteSimulator.isAccessibilityGranted

    var body: some View {
        VStack(spacing: 0) {
            // Header: Glass Search Bar & Category Dock
            headerView
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()
                .opacity(0.18)

            // Permission Banner (if not granted)
            if !isAccessibilityTrusted {
                accessibilityBanner
            }

            // Main List with Glass Cards
            mainContentView

            Divider()
                .opacity(0.18)

            // Futuristic Glass Footer Dock
            footerView
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Color.white.opacity(0.02)
                )
        }
        .frame(width: 460, height: 540)
        .background(VisualEffectBlur(material: .popover, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .onAppear {
            isAccessibilityTrusted = PasteSimulator.isAccessibilityGranted
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
        }
    }

    // MARK: - Header Search & Glass Capsule Dock

    private var headerView: some View {
        VStack(spacing: 10) {
            // Search Input Pill
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 13, weight: .semibold))

                TextField("Search history...", text: $store.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .regular))
                    .focused($isSearchFocused)

                if !store.searchQuery.isEmpty {
                    Button(action: {
                        store.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )

            // Category Filter Pills (Glass Dock)
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        FilterPill(title: "All", icon: "square.grid.2x2.fill", isSelected: store.selectedTypeFilter == nil && !store.showOnlyPinned) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                store.selectedTypeFilter = nil
                                store.showOnlyPinned = false
                            }
                        }
                        .id("tab_all")

                        FilterPill(title: "Pinned", icon: "pin.fill", isSelected: store.showOnlyPinned) {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                store.showOnlyPinned = true
                                store.selectedTypeFilter = nil
                            }
                        }
                        .id("tab_pinned")

                        ForEach(ClipboardContentType.allCases, id: \.self) { type in
                            FilterPill(title: type.displayName, icon: type.systemIcon, isSelected: store.selectedTypeFilter == type && !store.showOnlyPinned) {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    store.showOnlyPinned = false
                                    store.selectedTypeFilter = type
                                }
                            }
                            .id("tab_\(type.rawValue)")
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                }
                .onChange(of: store.currentTabId) { newTabId in
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        scrollProxy.scrollTo(newTabId, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Accessibility Banner

    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 12))

            Text("Accessibility permission needed for auto-pasting.")
                .font(.system(size: 11))
                .foregroundColor(.primary)

            Spacer()

            Button("Grant") {
                PasteSimulator.requestAccessibilityPermission()
                PasteSimulator.openAccessibilitySettings()
            }
            .font(.system(size: 10, weight: .semibold))
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.16))
    }

    // MARK: - List Content

    private var mainContentView: some View {
        let items = store.filteredItems

        return Group {
            if items.isEmpty {
                emptyStateView
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                HistoryItemRow(
                                    item: item,
                                    index: index,
                                    isSelected: index == store.selectedIndex,
                                    onSelect: {
                                        onPasteItem(item)
                                    },
                                    onTogglePin: {
                                        store.togglePin(id: item.id)
                                    },
                                    onDelete: {
                                        store.removeItem(id: item.id)
                                    }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: store.selectedIndex) { newIndex in
                        if newIndex >= 0 && newIndex < items.count {
                            withAnimation(.easeInOut(duration: 0.08)) {
                                proxy.scrollTo(items[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: store.searchQuery.isEmpty ? "sparkles.rectangle.stack" : "magnifyingglass")
                .font(.system(size: 34))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.secondary.opacity(0.5))

            Text(store.searchQuery.isEmpty ? "Clipboard History is Empty" : "No items matching '\(store.searchQuery)'")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)

            if store.searchQuery.isEmpty {
                Text("Copy text, code, images, or links to see them here.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
            } else {
                Button("Clear Search") {
                    store.searchQuery = ""
                }
                .font(.system(size: 11))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Futuristic Footer Toolbar

    private var footerView: some View {
        HStack(spacing: 8) {
            // Keyboard hints
            HStack(spacing: 5) {
                KeyboardBadge(title: "↵", label: "Paste")
                KeyboardBadge(title: "↑↓", label: "Navigate")
                KeyboardBadge(title: "⌘1-9", label: "Quick Paste")
                KeyboardBadge(title: "Esc", label: "Close")
            }

            Spacer()

            // Clear history glass button
            if !store.items.isEmpty {
                Button(action: {
                    store.clearHistory()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.white.opacity(0.06))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Clear Unpinned History")
            }

            // Settings glass button
            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color.white.opacity(0.06))
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Preferences...")
        }
    }
}

// MARK: - Next-Gen Apple Glass Filter Pill

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.08, green: 0.52, blue: 1.0),
                                        Color(red: 0.02, green: 0.38, blue: 0.88)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color.white.opacity(0.06))
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.white.opacity(0.45), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 0.8
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .shadow(color: isSelected ? Color.blue.opacity(0.4) : Color.clear, radius: 5, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Next-Gen Keyboard Badge

struct KeyboardBadge: View {
    let title: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Visual Effect Blur (Native Apple Glass)

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
