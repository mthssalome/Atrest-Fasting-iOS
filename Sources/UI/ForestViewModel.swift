import Foundation
import Domain

public final class ForestViewModel: ObservableObject {
    @Published public private(set) var historyItems: [HistoryItem]

    public init(historyItems: [HistoryItem]) {
        self.historyItems = historyItems
    }

    public func update(historyItems: [HistoryItem]) {
        self.historyItems = historyItems
    }

    public var accessibleItems: [HistoryItem] {
        historyItems.filter { $0.isInspectable }
    }

    public var lockedItems: [HistoryItem] {
        historyItems.filter { !$0.isInspectable }
    }

    public struct TreePresentation: Equatable, Identifiable {
        public let id: UUID
        public let memory: TreeMemory
        public let isLocked: Bool
    }

    public var trees: [TreePresentation] {
        historyItems.map { item in
            let memory = TreeMemory(session: item.session, state: .established)
            return TreePresentation(id: item.session.id, memory: memory, isLocked: !item.isInspectable)
        }
    }
}
