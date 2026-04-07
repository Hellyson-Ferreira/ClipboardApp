import Foundation
import AppKit

enum ClipboardContentType: String, CaseIterable, Identifiable, Equatable {
    case text
    case image
    case url
    case file

    var id: String { rawValue }

    var filterIcon: String {
        switch self {
        case .text:  return "textformat"
        case .image: return "photo"
        case .url:   return "link"
        case .file:  return "doc"
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id: UUID
    var contentType: ClipboardContentType
    var textContent: String?
    var imageContent: NSImage?
    var sourceApp: String
    var sourceAppBundleId: String?
    var date: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        contentType: ClipboardContentType,
        textContent: String? = nil,
        imageContent: NSImage? = nil,
        sourceApp: String,
        sourceAppBundleId: String? = nil,
        date: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.contentType = contentType
        self.textContent = textContent
        self.imageContent = imageContent
        self.sourceApp = sourceApp
        self.sourceAppBundleId = sourceAppBundleId
        self.date = date
        self.isPinned = isPinned
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}
