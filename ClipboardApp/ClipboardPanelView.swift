import SwiftUI
import AppKit

enum PanelTab: String, CaseIterable {
    case recentes = "Recents"
    case fixados  = "Pinned"

    var icon: String {
        switch self {
        case .recentes: return "clock"
        case .fixados:  return "pin.fill"
        }
    }
}

struct ClipboardPanelView: View {
    @State private var manager        = ClipboardManager()
    @State private var activeTab      = PanelTab.recentes
    @State private var isSearching    = false
    @State private var showClearAlert = false
    @State private var selectedItemId: UUID? = nil
    @State private var panelState     = PanelState.shared
    @FocusState private var searchFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var displayedItems: [ClipboardItem] {
        switch activeTab {
        case .recentes: return manager.filteredItems
        case .fixados:  return manager.pinnedFilteredItems
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topToolbar
            appFilterBar
            itemsCountBar
            itemsGrid
            bottomBar
        }
        .frame(width: 480, height: 560)
        .background(Color(hex: "#111111"))
        .preferredColorScheme(.dark)
        .environment(manager)
        .onAppear {
            if selectedItemId == nil {
                selectedItemId = displayedItems.first?.id
            }
        }
        .onChange(of: displayedItems.first?.id) { _, newId in
            if selectedItemId == nil { selectedItemId = newId }
        }
        .alert("Clear History", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { manager.clearAll() }
        } message: {
            Text("All unpinned clips will be removed. Pinned items will be kept.")
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack(spacing: 2) {
            toolbarBtn("clock.arrow.circlepath") {}
            toolbarBtn("gearshape") {
                NotificationCenter.default.post(name: .showSettingsNotification, object: nil)
            }
            toolbarBtn("keyboard") {}
            toolbarBtn("trash") { showClearAlert = true }
            toolbarBtn("doc.on.clipboard.fill", accent: true) {}

            // Pin panel button
            pinPanelButton

            Spacer()

            if isSearching {
                searchField
            } else {
                toolbarBtn("magnifyingglass") {
                    isSearching = true
                    searchFocused = true
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(hex: "#1A1A1A"))
    }

    private var pinPanelButton: some View {
        Button {
            panelState.isPinned.toggle()
            NotificationCenter.default.post(name: .togglePinPanelNotification, object: nil)
        } label: {
            Image(systemName: panelState.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(panelState.isPinned ? Color(hex: "#30D158") : .white.opacity(0.6))
                .frame(width: 30, height: 26)
                .background(panelState.isPinned ? Color(hex: "#30D158").opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(panelState.isPinned ? "Unpin panel" : "Pin panel — keep it open")
    }

    @ViewBuilder
    private func toolbarBtn(_ icon: String, accent: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accent ? Color(hex: "#30D158") : .white.opacity(0.6))
                .frame(width: 30, height: 26)
                .background(accent ? Color(hex: "#30D158").opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.35))

            TextField("Search clips...", text: $manager.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .focused($searchFocused)

            if !manager.searchText.isEmpty {
                Button {
                    manager.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(hex: "#2A2A2A"))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .frame(width: 165)
        .onExitCommand {
            isSearching = false
            manager.searchText = ""
        }
    }

    // MARK: - App Filter Bar

    private var appFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(manager.uniqueSourceApps, id: \.self) { app in
                    AppIconChip(
                        appName: app,
                        isSelected: manager.selectedAppFilter == app
                    ) {
                        manager.selectedAppFilter = manager.selectedAppFilter == app ? nil : app
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "#161616"))
    }

    // MARK: - Items Count Bar

    private var itemsCountBar: some View {
        HStack(spacing: 3) {
            Text("\(displayedItems.count)")
            if activeTab == .fixados {
                Text("pinned")
            } else {
                Text("items")
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(.white.opacity(0.28))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }

    // MARK: - Items Grid

    private var itemsGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if displayedItems.isEmpty {
                emptyState(for: activeTab)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                        ClipboardItemCard(
                            item: item,
                            isSelected: selectedItemId == item.id,
                            onPin:    { manager.togglePin(item) },
                            onDelete: { manager.remove(item) },
                            onCopy:   {
                                selectedItemId = item.id
                                manager.copyToClipboard(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: activeTab)
    }

    @ViewBuilder
    private func emptyState(for tab: PanelTab) -> some View {
        VStack(spacing: 10) {
            Image(systemName: tab == .fixados ? "pin.slash" : "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.1))
            if tab == .fixados {
                Text("No pinned items")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
                Text("Hover over a clip and click 📌 to pin it")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.12))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 200)
            } else {
                Text("No items found")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 55)
    }

    // MARK: - Bottom Bar (tabs + filtros)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.06))

            HStack(spacing: 0) {
                // Tabs
                tabSelector

                Spacer()

                // Filtros de tipo (só no tab Recentes)
                if activeTab == .recentes {
                    HStack(spacing: 2) {
                        bottomFilterBtn(nil,    icon: "square.grid.2x2")
                        bottomFilterBtn(.image, icon: "photo")
                        bottomFilterBtn(.text,  icon: "textformat")
                        bottomFilterBtn(.file,  icon: "doc")
                        bottomFilterBtn(.url,   icon: "link")
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer()

                bottomActionBtn("paintpalette") {}
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(hex: "#1A1A1A"))
            .animation(.easeInOut(duration: 0.18), value: activeTab)
        }
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(PanelTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeTab = tab
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(LocalizedStringKey(tab.rawValue))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(activeTab == tab ? Color(hex: "#30D158") : .white.opacity(0.45))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        activeTab == tab
                            ? Color(hex: "#30D158").opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(
                                activeTab == tab ? Color(hex: "#30D158").opacity(0.4) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)

                if tab != PanelTab.allCases.last {
                    Divider()
                        .frame(height: 14)
                        .padding(.horizontal, 2)
                        .opacity(0.2)
                }
            }
        }
        .padding(2)
        .background(Color(hex: "#222222"))
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    @ViewBuilder
    private func bottomActionBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 30, height: 26)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func bottomFilterBtn(_ type: ClipboardContentType?, icon: String) -> some View {
        let isActive = type == nil
            ? manager.activeContentFilter == nil
            : manager.activeContentFilter == type

        Button {
            if type == nil {
                manager.activeContentFilter = nil
            } else {
                manager.activeContentFilter = isActive ? nil : type
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isActive ? Color(hex: "#30D158") : .white.opacity(0.5))
                .frame(width: 30, height: 26)
                .background(isActive ? Color(hex: "#30D158").opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - App Icon Chip

struct AppIconChip: View {
    let appName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if let icon = NSImage.appIcon(for: appName) {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color(hex: "#2A2A2A"))
                        Text(String(appName.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .frame(width: 26, height: 26)
                }
            }
            .padding(3)
            .background(isSelected ? Color(hex: "#30D158").opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: "#30D158") : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .help(appName)
    }
}

// MARK: - Preview

#Preview {
    ClipboardPanelView()
}
