import Foundation
import AppKit
import Observation

@Observable
final class ClipboardManager {
    var items: [ClipboardItem] = []
    var searchText: String = ""
    var activeContentFilter: ClipboardContentType? = nil
    var selectedAppFilter: String? = nil

    var filteredItems: [ClipboardItem] {
        let pinned   = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }
        let ordered  = pinned + unpinned

        return ordered.filter { item in
            let matchesSearch = searchText.isEmpty
                || (item.textContent?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesFilter = activeContentFilter == nil || item.contentType == activeContentFilter
            let matchesApp    = selectedAppFilter == nil   || item.sourceApp == selectedAppFilter
            return matchesSearch && matchesFilter && matchesApp
        }
    }

    var uniqueSourceApps: [String] {
        var seen = Set<String>()
        return items.compactMap { item in
            guard !seen.contains(item.sourceApp) else { return nil }
            seen.insert(item.sourceApp)
            return item.sourceApp
        }
    }

    var pinnedFilteredItems: [ClipboardItem] {
        items.filter { item in
            guard item.isPinned else { return false }
            let matchesSearch = searchText.isEmpty
                || (item.textContent?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesFilter = activeContentFilter == nil || item.contentType == activeContentFilter
            let matchesApp    = selectedAppFilter == nil   || item.sourceApp == selectedAppFilter
            return matchesSearch && matchesFilter && matchesApp
        }
    }

    var totalCount: Int { filteredItems.count }

    init() {
        loadMockData()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(of: item) else { return }
        items[index].isPinned.toggle()
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearAll() {
        items.removeAll { !$0.isPinned }
    }

    private func loadMockData() {
        items = [
            ClipboardItem(
                contentType: .image,
                sourceApp: "Cursor",
                date: Date().addingTimeInterval(-30)
            ),
            ClipboardItem(
                contentType: .url,
                textContent: "https://gaitatzis.medium.com/clipboard-app-tutorial",
                sourceApp: "Chrome",
                date: Date().addingTimeInterval(-90)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "ClipboardApp",
                sourceApp: "Cursor",
                date: Date().addingTimeInterval(-150),
                isPinned: true
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "Q#mhLa@w2iDV7/f",
                sourceApp: "1Password",
                date: Date().addingTimeInterval(-210)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "Swift",
                sourceApp: "Cursor",
                date: Date().addingTimeInterval(-270)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "Estrutura completa (Tauri + Rust)",
                sourceApp: "Chrome",
                date: Date().addingTimeInterval(-330)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "swift language",
                sourceApp: "Cursor",
                date: Date().addingTimeInterval(-390)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "não tem outra pessoa",
                sourceApp: "WhatsApp",
                date: Date().addingTimeInterval(-450)
            ),
            ClipboardItem(
                contentType: .url,
                textContent: "https://developer.apple.com/swift/",
                sourceApp: "Safari",
                date: Date().addingTimeInterval(-510)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "import SwiftUI\n\nstruct ContentView: View {",
                sourceApp: "Cursor",
                date: Date().addingTimeInterval(-570)
            ),
            ClipboardItem(
                contentType: .file,
                textContent: "project.pbxproj",
                sourceApp: "Finder",
                date: Date().addingTimeInterval(-630)
            ),
            ClipboardItem(
                contentType: .text,
                textContent: "hellyson@email.com",
                sourceApp: "Mail",
                date: Date().addingTimeInterval(-690)
            ),
        ]
    }
}
