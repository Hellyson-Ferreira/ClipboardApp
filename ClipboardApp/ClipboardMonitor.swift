import AppKit
import Foundation

final class ClipboardMonitor {
    var onNewItem: ((ClipboardItem) -> Void)?

    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var timer: Timer?

    // MARK: - Lifecycle

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Polling

    private func poll() {
        let pasteboard    = NSPasteboard.general
        let currentCount  = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount   = currentCount

        guard let item = buildItem(from: pasteboard) else { return }
        onNewItem?(item)
    }

    // MARK: - Item builder

    private func buildItem(from pasteboard: NSPasteboard) -> ClipboardItem? {
        let frontApp  = NSWorkspace.shared.frontmostApplication
        let sourceApp = frontApp?.localizedName ?? "Unknown"
        let bundleId  = frontApp?.bundleIdentifier

        // Ignorar mudanças originadas pelo próprio app
        if bundleId == Bundle.main.bundleIdentifier { return nil }

        // Imagem
        for type in [NSPasteboard.PasteboardType.tiff, .png] {
            if let data = pasteboard.data(forType: type), let image = NSImage(data: data) {
                return ClipboardItem(
                    contentType: .image,
                    imageContent: image,
                    sourceApp: sourceApp,
                    sourceAppBundleId: bundleId
                )
            }
        }

        // Texto / URL
        guard let string = pasteboard.string(forType: .string),
              !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        let contentType: ClipboardContentType = isURL(string) ? .url : .text

        return ClipboardItem(
            contentType: contentType,
            textContent: string,
            sourceApp: sourceApp,
            sourceAppBundleId: bundleId
        )
    }

    // MARK: - Helpers

    private func isURL(_ string: String) -> Bool {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme
        else { return false }
        return ["http", "https", "ftp"].contains(scheme) && url.host != nil
    }
}
