import XCTest
@testable import yummy
import UIKit

final class HapticsManagerTests: XCTestCase {
    private func runOnMain(_ block: @escaping () -> Void) {
        let exp = expectation(description: "runOnMain")
        DispatchQueue.main.async {
            block()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }

    func testSharedSingletonIsStable() {
        let first = HapticsManager.shared
        let second = HapticsManager.shared
        XCTAssertTrue(first === second)
    }

    func testNotificationFeedbackDoesNotCrash() {
        runOnMain {
            let manager = HapticsManager.shared
            manager.notification(type: .success)
            manager.notification(type: .warning)
            manager.notification(type: .error)
        }
    }

    func testImpactFeedbackDoesNotCrash() {
        runOnMain {
            let manager = HapticsManager.shared
            manager.impact(style: .light)
            manager.impact(style: .medium)
            manager.impact(style: .heavy)
            if #available(iOS 13.0, *) {
                manager.impact(style: .soft)
                manager.impact(style: .rigid)
            }
        }
    }

    func testSelectionFeedbackDoesNotCrash() {
        runOnMain {
            let manager = HapticsManager.shared
            manager.selection()
        }
    }

    func testSuccessWithSoundDoesNotCrash() {
        runOnMain {
            let manager = HapticsManager.shared
            manager.successWithSound()
        }
    }
}








