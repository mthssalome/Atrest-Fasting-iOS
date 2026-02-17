import SnapshotTesting
import SwiftUI
import XCTest

@MainActor
final class SnapshotHarnessTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = true // TODO: Set to false after baseline capture on Mac
    }

    override func tearDown() {
        super.tearDown()
    }

    func testSwiftUIViewSnapshot() {
        let view = VStack {
            Text("Sample")
            Capsule()
                .frame(width: 72, height: 36)
        }
        let controller = UIHostingController(rootView: view)
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }
}
