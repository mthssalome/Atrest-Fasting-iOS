import Foundation
import Data
import Domain

@MainActor
public final class WaterViewModel: ObservableObject {
    @Published public private(set) var entries: [WaterIntakeEntry] = []
    @Published public private(set) var todayTotal: Int = 0

    private let store: WaterStore
    private let calendar: Calendar

    public init(store: WaterStore) {
        self.store = store
        self.calendar = Calendar.autoupdatingCurrent
    }

    public func load() async {
        let state = await store.load()
        apply(state: state)
    }

    public func add(amountMilliliters: Int = 250) async {
        if let state = try? await store.add(amountMilliliters: amountMilliliters) {
            apply(state: state)
        }
    }

    public func remove(id: UUID) async {
        if let state = try? await store.remove(id: id) {
            apply(state: state)
        }
    }

    private func apply(state: WaterStoreState) {
        entries = state.entries
        todayTotal = state.entries
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amountMilliliters }
    }
}
