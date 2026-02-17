import Foundation
import Domain

public final class CalendarViewModel: ObservableObject {
    @Published public private(set) var entries: [CalendarEntry]

    public init(entries: [CalendarEntry]) {
        self.entries = entries
    }

    public func update(entries: [CalendarEntry]) {
        self.entries = entries
    }

    public var visibleEntries: [CalendarEntry] {
        entries.filter { $0.isInspectable }
    }

    public var lockedEntries: [CalendarEntry] {
        entries.filter { !$0.isInspectable }
    }
}
