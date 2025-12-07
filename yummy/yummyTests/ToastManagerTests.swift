import XCTest
@testable import yummy

final class ToastManagerTests: XCTestCase {

    override func setUp() async throws {
        await MainActor.run {
            ToastManager.shared.dismissImmediately()
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            ToastManager.shared.dismissImmediately()
        }
    }

    // MARK: - Helpers
    private func waitUntil(_ timeout: TimeInterval = 2.0, condition: @escaping @Sendable () async -> Bool) async -> Bool {
        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            if await condition() { return true }
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        }
        return await condition()
    }

    // MARK: - Tests
    func testShowDisplaysCurrentItem() async throws {
        await MainActor.run {
            ToastManager.shared.show("Hello", style: .success, duration: 0.2, haptics: false, position: .top)
        }

        let appeared = await waitUntil(1.0) {
            await MainActor.run { ToastManager.shared.currentItem != nil }
        }
        XCTAssertTrue(appeared, "Toast did not appear in time")

        await MainActor.run {
            let item = ToastManager.shared.currentItem
            XCTAssertEqual(item?.message, "Hello")
            XCTAssertEqual(item?.style, .success)
            XCTAssertEqual(item?.position, .top)
        }
    }

    func testQueueShowsSecondAfterFirstDismiss() async throws {
        await MainActor.run {
            ToastManager.shared.show("A", style: .success, duration: 0.15, haptics: false, position: .bottom)
            ToastManager.shared.show("B", style: .error, duration: 0.15, haptics: false, position: .bottom)
        }

        // First should appear quickly
        let firstAppeared = await waitUntil(1.0) {
            await MainActor.run { ToastManager.shared.currentItem?.message == "A" }
        }
        XCTAssertTrue(firstAppeared, "First toast A didn't appear")

        // After ~0.15s + animation ~0.28s, second should become current
        let secondAppeared = await waitUntil(2.0) {
            await MainActor.run { ToastManager.shared.currentItem?.message == "B" }
        }
        XCTAssertTrue(secondAppeared, "Second toast B didn't appear after A dismissed")
    }

    func testDedupeWhileShowingRefreshesTimer_NoDuplicateQueued() async throws {
        await MainActor.run {
            ToastManager.shared.show("Same", style: .warning, duration: 0.2, haptics: false, position: .bottom)
        }

        // Ensure it shows
        let appeared = await waitUntil(1.0) {
            await MainActor.run { ToastManager.shared.currentItem?.message == "Same" }
        }
        XCTAssertTrue(appeared)
        let originalId = await MainActor.run { ToastManager.shared.currentItem?.id }

        // Midway, show same toast again with longer duration to simulate refresh
        try? await Task.sleep(nanoseconds: 80_000_000) // 0.08s
        await MainActor.run {
            ToastManager.shared.show("Same", style: .warning, duration: 0.35, haptics: false, position: .bottom)
        }

        // After refresh, it should still be the same item (id unchanged), proving no duplicate queued
        let refreshedId = await MainActor.run { ToastManager.shared.currentItem?.id }
        XCTAssertEqual(originalId, refreshedId)

        // Eventually it should dismiss
        let dismissed = await waitUntil(2.0) {
            await MainActor.run { ToastManager.shared.currentItem == nil }
        }
        XCTAssertTrue(dismissed, "Toast did not dismiss after refreshed duration")
    }

    func testDismissImmediatelyClearsState() async throws {
        await MainActor.run {
            ToastManager.shared.show("Temp", style: .success, duration: 1.0, haptics: false, position: .bottom)
            ToastManager.shared.dismissImmediately()
        }

        await MainActor.run {
            XCTAssertNil(ToastManager.shared.currentItem)
        }
    }
}


