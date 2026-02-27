import SwiftUI

public struct TreeShape: Shape {
    private let pathString: String

    public init(variantIndex: Int) {
        let name = "tree_\(variantIndex)"
        if let url = Bundle.module.url(forResource: name, withExtension: "svg"),
           let data = try? Data(contentsOf: url),
           let svg = String(data: data, encoding: .utf8),
           let dValue = TreeShape.extractPathD(from: svg) {
            self.pathString = dValue
        } else {
            self.pathString = ""
        }
    }

    public func path(in rect: CGRect) -> Path {
        guard !pathString.isEmpty else {
            return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.05))
        }
        let path = Path(pathString)
        let bounds = path.boundingRect
        guard bounds.width > 0, bounds.height > 0 else { return path }
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        let transform = CGAffineTransform(translationX: -bounds.minX, y: -bounds.minY)
            .scaledBy(x: scale, y: scale)
            .translatedBy(
                x: (rect.width / scale - bounds.width) / 2,
                y: (rect.height / scale - bounds.height) / 2
            )
        return path.applying(transform)
    }

    private static func extractPathD(from svg: String) -> String? {
        guard let range = svg.range(of: #"(?<=d=")[^"]*"#, options: .regularExpression) else {
            return nil
        }
        return String(svg[range])
    }
}
