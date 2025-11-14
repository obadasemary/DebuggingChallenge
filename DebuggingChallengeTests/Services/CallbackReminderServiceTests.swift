/**
 Tests for alternative callback-based implementations in DefaultReminderService

 This file tests the four alternative callback implementations:
 - fetchRemindersWithBarrier: Uses concurrent queue with barrier flags
 - fetchRemindersWithSemaphore: Uses DispatchSemaphore for synchronization
 - fetchRemindersWithLock: Uses NSLock for mutual exclusion
 - fetchRemindersWithSerialQueue: Uses serial DispatchQueue for ordered execution
 */

@testable import DebuggingChallenge
import XCTest

final class CallbackReminderServiceTests: XCTestCase {

    var sut: DefaultReminderService!

    override func setUp() {
        super.setUp()
        sut = DefaultReminderService(dataSource: ReminderDataSourceStub())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - fetchRemindersWithBarrier Tests

    func testFetchRemindersWithBarrier() {
        assertBasicFetch(
            for: sut.fetchRemindersWithBarrier,
            description: "Should fetch all reminders using barrier"
        )
    }

    func testFetchRemindersWithBarrier_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.fetchRemindersWithBarrier,
            description: "Should fetch reminders in parallel using barrier",
            maxTime: 1.0
        )
    }

    func testFetchRemindersWithBarrier_VerifyReminderContent() {
        assertReminderContent(
            for: sut.fetchRemindersWithBarrier,
            description: "Should fetch valid reminder objects using barrier"
        )
    }

    // MARK: - fetchRemindersWithSemaphore Tests

    func testFetchRemindersWithSemaphore() {
        assertBasicFetch(
            for: sut.fetchRemindersWithSemaphore,
            description: "Should fetch all reminders using semaphore"
        )
    }

    func testFetchRemindersWithSemaphore_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.fetchRemindersWithSemaphore,
            description: "Should fetch reminders using semaphore",
            maxTime: 1.0
        )
    }

    func testFetchRemindersWithSemaphore_VerifyReminderContent() {
        assertReminderContent(
            for: sut.fetchRemindersWithSemaphore,
            description: "Should fetch valid reminder objects using semaphore"
        )
    }

    // MARK: - fetchRemindersWithLock Tests

    func testFetchRemindersWithLock() {
        assertBasicFetch(
            for: sut.fetchRemindersWithLock,
            description: "Should fetch all reminders using NSLock"
        )
    }

    func testFetchRemindersWithLock_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.fetchRemindersWithLock,
            description: "Should fetch reminders using NSLock",
            maxTime: 1.0
        )
    }

    func testFetchRemindersWithLock_VerifyReminderContent() {
        assertReminderContent(
            for: sut.fetchRemindersWithLock,
            description: "Should fetch valid reminder objects using NSLock"
        )
    }

    // MARK: - fetchRemindersWithSerialQueue Tests

    func testFetchRemindersWithSerialQueue() {
        assertBasicFetch(
            for: sut.fetchRemindersWithSerialQueue,
            description: "Should fetch all reminders using serial queue"
        )
    }

    func testFetchRemindersWithSerialQueue_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.fetchRemindersWithSerialQueue,
            description: "Should fetch reminders using serial queue",
            maxTime: 1.0
        )
    }

    func testFetchRemindersWithSerialQueue_VerifyReminderContent() {
        assertReminderContent(
            for: sut.fetchRemindersWithSerialQueue,
            description: "Should fetch valid reminder objects using serial queue"
        )
    }

    // MARK: - Comparison Tests

    func testAllCallbackImplementationsReturnSameCount() {
        let expectation1 = expectation(description: "Barrier callback completes")
        let expectation2 = expectation(description: "Semaphore callback completes")
        let expectation3 = expectation(description: "Lock callback completes")
        let expectation4 = expectation(description: "Serial queue callback completes")

        var countBarrier = 0
        var countSemaphore = 0
        var countLock = 0
        var countSerialQueue = 0

        sut.fetchRemindersWithBarrier { reminders in
            countBarrier = reminders.count
            expectation1.fulfill()
        }

        sut.fetchRemindersWithSemaphore { reminders in
            countSemaphore = reminders.count
            expectation2.fulfill()
        }

        sut.fetchRemindersWithLock { reminders in
            countLock = reminders.count
            expectation3.fulfill()
        }

        sut.fetchRemindersWithSerialQueue { reminders in
            countSerialQueue = reminders.count
            expectation4.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4], timeout: 2.0)

        XCTAssertEqual(countBarrier, 12, "Barrier callback should return 12 reminders")
        XCTAssertEqual(countSemaphore, 12, "Semaphore callback should return 12 reminders")
        XCTAssertEqual(countLock, 12, "Lock callback should return 12 reminders")
        XCTAssertEqual(countSerialQueue, 12, "Serial queue callback should return 12 reminders")
        XCTAssertEqual(countBarrier, countSemaphore, "All implementations should return same count")
        XCTAssertEqual(countSemaphore, countLock, "All implementations should return same count")
        XCTAssertEqual(countLock, countSerialQueue, "All implementations should return same count")
    }
}

private extension CallbackReminderServiceTests {
    
    // MARK: - Helper Functions

    private func assertBasicFetch(
        for method: (@escaping ([Reminder]) -> Void) -> Void,
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: description)

        method { reminders in
            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders", file: file, line: line)

            let uniqueIds = Set(reminders.map { $0.id })
            XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs", file: file, line: line)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    private func assertParallelExecution(
        for method: (@escaping ([Reminder]) -> Void) -> Void,
        description: String,
        maxTime: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: description)
        let startTime = Date()

        method { reminders in
            let elapsedTime = Date().timeIntervalSince(startTime)

            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders", file: file, line: line)
            XCTAssertLessThan(elapsedTime, maxTime, "Should complete in less than \(maxTime)s", file: file, line: line)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    private func assertReminderContent(
        for method: (@escaping ([Reminder]) -> Void) -> Void,
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: description)

        method { reminders in
            XCTAssertEqual(reminders.count, 12, file: file, line: line)

            for reminder in reminders {
                XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty", file: file, line: line)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

}
