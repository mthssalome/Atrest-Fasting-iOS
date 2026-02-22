import SwiftUI
import DesignSystem

public struct TreeMaterializationView: View {
    let variantIndex: Int
    let toneIndex: Int
    let progress: Double
    let showStar: Bool

    public init(variantIndex: Int, toneIndex: Int, progress: Double, showStar: Bool) {
        self.variantIndex = variantIndex
        self.toneIndex = toneIndex
        self.progress = progress
        self.showStar = showStar
    }

    public var body: some View {
        GeometryReader { geo in
            let treeSize = geo.size.width * 0.72
            let treeOriginY = geo.size.height * 0.28

            ZStack {
                TreeView(
                    variantIndex: variantIndex,
                    toneIndex: toneIndex,
                    progress: progress,
                    isIncomplete: false,
                    size: treeSize
                )
                .position(x: geo.size.width / 2, y: treeOriginY + treeSize / 2)

                if showStar {
                    StarView()
                        .frame(width: 18, height: 18)
                        .position(
                            x: geo.size.width / 2 + treeSize * 0.38,
                            y: treeOriginY + treeSize * 0.08
                        )
                        .transition(.opacity.animation(Motion.starAppear))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
