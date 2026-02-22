import Foundation
import CoreGraphics
import Domain

public final class ForestViewModel: ObservableObject {
    @Published public private(set) var historyItems: [HistoryItem]
    @Published public private(set) var treeLayouts: [TreeLayout]
    @Published public private(set) var starLayouts: [StarLayout]

    public struct TreeLayout: Identifiable {
        public let id: UUID
        public let memory: TreeMemory
        public let position: CGPoint   // normalized (0...1)
        public let depthLayer: Int     // 0=foreground,1=mid,2=background
        public let toneIndex: Int
        public let variantIndex: Int

        public var stateProgress: Double {
            switch memory.state {
            case .established:
                return 1.0
            case .incomplete:
                return 0.30
            case let .materializing(progress):
                return progress
            }
        }
    }

    public struct StarLayout: Identifiable {
        public let id: UUID
        public let position: CGPoint   // normalized (0...1)
        public let depthLayer: Int
    }

    public init(historyItems: [HistoryItem]) {
        self.historyItems = historyItems
        self.treeLayouts = []
        self.starLayouts = []
        recomputeLayouts()
    }

    public func update(historyItems: [HistoryItem]) {
        self.historyItems = historyItems
        recomputeLayouts()
    }

    private func recomputeLayouts() {
        let trees = TreeMapper.trees(for: historyItems.map { $0.session })
        treeLayouts = trees.enumerated().map { index, memory in
            let variantIndex = abs(memory.session.id.hashValue) % 8
            let toneIndex = abs(memory.session.id.hashValue / 8) % 5
            let depthLayer = index % 3
            let seed = abs(memory.session.id.hashValue)
            let x = Self.seededFraction(seed ^ 0x1f1f)
            let y = Self.depthY(depthLayer: depthLayer, seed: seed ^ 0x2f2f)
            return TreeLayout(
                id: memory.session.id,
                memory: memory,
                position: CGPoint(x: x, y: y),
                depthLayer: depthLayer,
                toneIndex: toneIndex,
                variantIndex: variantIndex
            )
        }

        starLayouts = trees.enumerated().compactMap { index, memory in
            guard memory.state == .established else { return nil }
            let depthLayer = index % 3
            let seed = abs(memory.session.id.hashValue ^ 0x3f3f)
            let x = Self.seededFraction(seed)
            // Stars live in upper 40% of the canvas
            let yMin: Double = 0.05
            let yMax: Double = 0.40
            let y = yMin + (yMax - yMin) * Self.seededFraction(seed ^ 0x4f4f)
            return StarLayout(
                id: memory.session.id,
                position: CGPoint(x: x, y: y),
                depthLayer: depthLayer
            )
        }
    }

    private static func seededFraction(_ seed: Int) -> Double {
        // Simple deterministic pseudo-random in 0...1
        let masked = UInt64(bitPattern: Int64(seed)) & 0x0000FFFF_FFFFFFFF
        return Double(masked % 10_000_000) / 10_000_000.0
    }

    private static func depthY(depthLayer: Int, seed: Int) -> Double {
        let bands: [(Double, Double)] = [(0.55, 0.90), (0.35, 0.65), (0.15, 0.45)]
        let band = bands[depthLayer % bands.count]
        return band.0 + (band.1 - band.0) * seededFraction(seed)
    }
}
