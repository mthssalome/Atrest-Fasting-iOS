import SwiftUI
import Domain

public struct TreeGlyph: View {
    private let memory: TreeMemory
    private let isLocked: Bool
    private let accessibilityLabel: String

    public init(memory: TreeMemory, isLocked: Bool, accessibilityLabel: String) {
        self.memory = memory
        self.isLocked = isLocked
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        let variantIndex = abs(memory.session.id.hashValue) % 8
        let toneIndex = abs(memory.session.id.hashValue / 8) % 5
        let progress: Double = memory.state == .incomplete ? 0.30 : 1.0
        let incomplete = memory.state == .incomplete

        TreeView(
            variantIndex: variantIndex,
            toneIndex: toneIndex,
            progress: progress,
            isIncomplete: incomplete,
            size: 80
        )
        .opacity(isLocked ? 0.20 : 1.0)
        .accessibilityLabel(accessibilityLabel)
    }
}
