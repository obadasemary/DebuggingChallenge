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
        let expectation = expectation(description: "Should fetch all reminders using barrier")

        sut.fetchRemindersWithBarrier { reminders in
            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

            let uniqueIds = Set(reminders.map { $0.id })
            XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithBarrier_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders in parallel using barrier")
        let startTime = Date()

        sut.fetchRemindersWithBarrier { reminders in
            let elapsedTime = Date().timeIntervalSince(startTime)

            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
            // Note: Barrier writes add some synchronization overhead
            XCTAssertLessThan(elapsedTime, 1.0, "Parallel execution should complete in less than 1.0s")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithBarrier_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using barrier")

        sut.fetchRemindersWithBarrier { reminders in
            XCTAssertEqual(reminders.count, 12)

            for reminder in reminders {
                XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - fetchRemindersWithSemaphore Tests

    func testFetchRemindersWithSemaphore() {
        let expectation = expectation(description: "Should fetch all reminders using semaphore")

        sut.fetchRemindersWithSemaphore { reminders in
            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

            let uniqueIds = Set(reminders.map { $0.id })
            XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithSemaphore_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders using semaphore")
        let startTime = Date()

        sut.fetchRemindersWithSemaphore { reminders in
            let elapsedTime = Date().timeIntervalSince(startTime)

            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
            // Note: Semaphore serializes writes, so it's slightly slower than truly parallel approaches
            XCTAssertLessThan(elapsedTime, 1.0, "Should complete in less than 1.0s")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithSemaphore_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using semaphore")

        sut.fetchRemindersWithSemaphore { reminders in
            XCTAssertEqual(reminders.count, 12)

            for reminder in reminders {
                XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - fetchRemindersWithLock Tests

    func testFetchRemindersWithLock() {
        let expectation = expectation(description: "Should fetch all reminders using NSLock")

        sut.fetchRemindersWithLock { reminders in
            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

            let uniqueIds = Set(reminders.map { $0.id })
            XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithLock_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders using NSLock")
        let startTime = Date()

        sut.fetchRemindersWithLock { reminders in
            let elapsedTime = Date().timeIntervalSince(startTime)

            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
            XCTAssertLessThan(elapsedTime, 1.0, "Should complete in less than 1.0s")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithLock_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using NSLock")

        sut.fetchRemindersWithLock { reminders in
            XCTAssertEqual(reminders.count, 12)

            for reminder in reminders {
                XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - fetchRemindersWithSerialQueue Tests

    func testFetchRemindersWithSerialQueue() {
        let expectation = expectation(description: "Should fetch all reminders using serial queue")

        sut.fetchRemindersWithSerialQueue { reminders in
            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

            let uniqueIds = Set(reminders.map { $0.id })
            XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithSerialQueue_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders using serial queue")
        let startTime = Date()

        sut.fetchRemindersWithSerialQueue { reminders in
            let elapsedTime = Date().timeIntervalSince(startTime)

            XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
            XCTAssertLessThan(elapsedTime, 1.0, "Should complete in less than 1.0s")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testFetchRemindersWithSerialQueue_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using serial queue")

        sut.fetchRemindersWithSerialQueue { reminders in
            XCTAssertEqual(reminders.count, 12)

            for reminder in reminders {
                XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
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
