import Foundation
import AppKit
import Observation

@Observable
final class ClipboardManager {
    var items: [ClipboardItem] = []
    var searchText: String = ""
    var activeContentFilter: ClipboardContentType? = nil
    var selectedAppFilter: String? = nil

    private let db      = DatabaseManager()
    private let monitor = ClipboardMonitor()
    private let maxNonPinned = 200

    // MARK: - Filtered views

    var filteredItems: [ClipboardItem] {
        applyFilters(to: items)
    }

    var pinnedFilteredItems: [ClipboardItem] {
        applyFilters(to: items.filter { $0.isPinned })
    }

    var uniqueSourceApps: [String] {
        var seen  = Set<String>()
        return items.compactMap { item in
            guard !seen.contains(item.sourceApp) else { return nil }
            seen.insert(item.sourceApp)
            return item.sourceApp
        }
    }

    var totalCount: Int { filteredItems.count }

    // MARK: - Init

    init() {
        items = db.fetchAll()

        monitor.onNewItem = { [weak self] newItem in
            self?.handleNew(newItem)
        }
        monitor.start()
    }

    // MARK: - Mutations

    func togglePin(_ item: ClipboardItem) {
        guard let idx = items.firstIndex(of: item) else { return }
        items[idx].isPinned.toggle()
        db.updatePin(id: item.id, isPinned: items[idx].isPinned)
    }

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        db.delete(id: item.id)
    }

    func clearAll() {
        items.removeAll { !$0.isPinned }
        db.deleteAllNonPinned()
    }

    func copyToClipboard(_ item: ClipboardItem) {
        monitor.suppressNextChange()

        let pb = NSPasteboard.general
        pb.clearContents()

        switch item.contentType {
        case .text, .url, .file:
            if let text = item.textContent {
                pb.setString(text, forType: .string)
            }
        case .image:
            if let image = item.imageContent {
                pb.writeObjects([image])
            }
        }

        NotificationCenter.default.post(name: .closePanelNotification, object: nil)
    }

    // MARK: - Private

    private func handleNew(_ item: ClipboardItem) {
        // Deduplicar: ignora se o último item não-imagem tiver o mesmo conteúdo
        if item.imageContent == nil,
           let last = items.first(where: { !$0.isPinned }),
           last.contentType  == item.contentType,
           last.textContent  == item.textContent {
            return
        }

        items.insert(item, at: 0)
        db.insert(item)
        trimIfNeeded()
    }

    private func trimIfNeeded() {
        let nonPinned = items.filter { !$0.isPinned }
        guard nonPinned.count > maxNonPinned else { return }

        let toRemove = nonPinned.suffix(nonPinned.count - maxNonPinned)
        for old in toRemove {
            items.removeAll { $0.id == old.id }
        }
        db.trimOldest(keeping: maxNonPinned)
    }

    private func applyFilters(to source: [ClipboardItem]) -> [ClipboardItem] {
        source.filter { item in
            let matchesSearch = searchText.isEmpty
                || (item.textContent?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesFilter = activeContentFilter == nil || item.contentType == activeContentFilter
            let matchesApp    = selectedAppFilter   == nil || item.sourceApp   == selectedAppFilter
            return matchesSearch && matchesFilter && matchesApp
        }
    }
}
