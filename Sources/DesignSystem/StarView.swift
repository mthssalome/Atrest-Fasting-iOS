import SwiftUI

public struct StarView: View {
    public init() {}

    public var body: some View {
        ZStack {
            Capsule().fill(Palette.starLight).frame(width: 2, height: 18)
            Capsule().fill(Palette.starLight).frame(width: 2, height: 18)
                .rotationEffect(.degrees(90))
            Capsule().fill(Palette.starLight).frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(45))
            Capsule().fill(Palette.starLight).frame(width: 1.5, height: 14)
                .rotationEffect(.degrees(135))
        }
        .shadow(color: Palette.starLight.opacity(0.6), radius: 8)
    }
}
