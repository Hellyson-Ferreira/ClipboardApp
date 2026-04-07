import Foundation
import Observation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let maxItems = "maxItems"
    }

    var maxItems: Int {
        didSet {
            let clamped = maxItems.clamped(to: 50...5000)
            if clamped != maxItems { maxItems = clamped; return }
            UserDefaults.standard.set(maxItems, forKey: Keys.maxItems)
        }
    }

    private init() {
        let stored = UserDefaults.standard.integer(forKey: Keys.maxItems)
        maxItems = stored > 0 ? stored.clamped(to: 50...5000) : 500
    }
}

// MARK: - Comparable clamping helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
