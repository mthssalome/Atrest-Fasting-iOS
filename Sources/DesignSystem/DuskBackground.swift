import SwiftUI

public struct DuskBackground: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [Palette.horizonWarm, Palette.duskBase, Palette.deepNight],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}
