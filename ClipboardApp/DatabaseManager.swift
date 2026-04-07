import Foundation
import AppKit
import SQLite3

// MARK: - SQLITE_TRANSIENT helper
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class DatabaseManager {
    private var db: OpaquePointer?

    init() {
        openDatabase()
        createTable()
        runMigrations()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Setup

    private func openDatabase() {
        do {
            let folder = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("ClipboardApp", isDirectory: true)

            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

            let fileURL = folder.appendingPathComponent("clipboard.db")

            if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
                print("[DB] Erro ao abrir banco: \(String(cString: sqlite3_errmsg(db)))")
            }
        } catch {
            print("[DB] Erro ao localizar diretório: \(error)")
        }
    }

    private func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS clipboard_items (
            id                  TEXT PRIMARY KEY,
            content_type        TEXT NOT NULL,
            text_content        TEXT,
            image_data          BLOB,
            source_app          TEXT NOT NULL DEFAULT 'Unknown',
            source_app_bundle_id TEXT,
            date                REAL NOT NULL,
            is_pinned           INTEGER NOT NULL DEFAULT 0
        );
        """
        execute(sql)
    }

    private func runMigrations() {
        // Índice para buscas por data (mais recente primeiro)
        execute("CREATE INDEX IF NOT EXISTS idx_date ON clipboard_items(date DESC);")
    }

    // MARK: - CRUD

    func insert(_ item: ClipboardItem) {
        let sql = """
        INSERT OR REPLACE INTO clipboard_items
            (id, content_type, text_content, image_data,
             source_app, source_app_bundle_id, date, is_pinned)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, item.id.uuidString,         -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, item.contentType.rawValue,  -1, SQLITE_TRANSIENT)

        if let text = item.textContent {
            sqlite3_bind_text(stmt, 3, text, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 3)
        }

        if let data = pngData(from: item.imageContent) {
            data.withUnsafeBytes { ptr in
                sqlite3_bind_blob(stmt, 4, ptr.baseAddress, Int32(data.count), SQLITE_TRANSIENT)
            }
        } else {
            sqlite3_bind_null(stmt, 4)
        }

        sqlite3_bind_text(stmt, 5, item.sourceApp,                -1, SQLITE_TRANSIENT)
        if let bundle = item.sourceAppBundleId {
            sqlite3_bind_text(stmt, 6, bundle, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 6)
        }
        sqlite3_bind_double(stmt, 7, item.date.timeIntervalSince1970)
        sqlite3_bind_int(stmt,    8, item.isPinned ? 1 : 0)

        sqlite3_step(stmt)
    }

    func fetchAll(limit: Int = 300) -> [ClipboardItem] {
        let sql = """
        SELECT id, content_type, text_content, image_data,
               source_app, source_app_bundle_id, date, is_pinned
        FROM clipboard_items
        ORDER BY is_pinned DESC, date DESC
        LIMIT ?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, Int32(limit))

        var items: [ClipboardItem] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard
                let idStr   = sqlite3_column_text(stmt, 0),
                let typeStr = sqlite3_column_text(stmt, 1),
                let id      = UUID(uuidString: String(cString: idStr)),
                let type    = ClipboardContentType(rawValue: String(cString: typeStr))
            else { continue }

            let text     = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
            let image    = blobImage(stmt: stmt, column: 3)
            let app      = sqlite3_column_text(stmt, 4).map { String(cString: $0) } ?? "Unknown"
            let bundle   = sqlite3_column_text(stmt, 5).map { String(cString: $0) }
            let date     = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6))
            let isPinned = sqlite3_column_int(stmt, 7) != 0

            items.append(ClipboardItem(
                id: id,
                contentType: type,
                textContent: text,
                imageContent: image,
                sourceApp: app,
                sourceAppBundleId: bundle,
                date: date,
                isPinned: isPinned
            ))
        }
        return items
    }

    func delete(id: UUID) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "DELETE FROM clipboard_items WHERE id = ?;", -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
    }

    func deleteAllNonPinned() {
        execute("DELETE FROM clipboard_items WHERE is_pinned = 0;")
    }

    func updatePin(id: UUID, isPinned: Bool) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "UPDATE clipboard_items SET is_pinned = ? WHERE id = ?;", -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt,  1, isPinned ? 1 : 0)
        sqlite3_bind_text(stmt, 2, id.uuidString, -1, SQLITE_TRANSIENT)
        sqlite3_step(stmt)
    }

    func trimOldest(keeping limit: Int) {
        let sql = """
        DELETE FROM clipboard_items
        WHERE is_pinned = 0
          AND id NOT IN (
              SELECT id FROM clipboard_items
              WHERE is_pinned = 0
              ORDER BY date DESC
              LIMIT ?
          );
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(limit))
        sqlite3_step(stmt)
    }

    // MARK: - Helpers

    private func execute(_ sql: String) {
        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK, let e = err {
            print("[DB] \(String(cString: e))")
            sqlite3_free(err)
        }
    }

    private func pngData(from image: NSImage?) -> Data? {
        guard let image,
              let tiff = image.tiffRepresentation,
              let rep  = NSBitmapImageRep(data: tiff)
        else { return nil }
        return rep.representation(using: .png, properties: [.compressionFactor: 0.8])
    }

    private func blobImage(stmt: OpaquePointer?, column: Int32) -> NSImage? {
        guard let ptr = sqlite3_column_blob(stmt, column) else { return nil }
        let size = sqlite3_column_bytes(stmt, column)
        let data = Data(bytes: ptr, count: Int(size))
        return NSImage(data: data)
    }
}
