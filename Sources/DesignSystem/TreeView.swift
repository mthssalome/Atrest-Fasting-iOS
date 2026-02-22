import SwiftUI

public struct TreeView: View {
    let variantIndex: Int      // 0–7
    let toneIndex: Int         // 0–4
    let progress: Double       // 0.0–1.0
    let isIncomplete: Bool
    let size: CGFloat

    public init(variantIndex: Int, toneIndex: Int, progress: Double, isIncomplete: Bool, size: CGFloat) {
        self.variantIndex = variantIndex
        self.toneIndex = toneIndex
        self.progress = progress
        self.isIncomplete = isIncomplete
        self.size = size
    }

    public var body: some View {
        TreeShape(variantIndex: variantIndex)
            .fill(tintColor)
            .opacity(0.05 + progress * 0.95)
            .frame(width: size, height: size)
    }

    private var tintColor: Color {
        if isIncomplete { return Palette.treeGrey }
        let tone = Palette.earthTones[toneIndex % Palette.earthTones.count]
        return Color.interpolate(from: Palette.treeGrey, to: tone.light, t: progress)
    }
}
