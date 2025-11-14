/**
 Additional tests for alternative Combine implementations in DefaultReminderService

 This file tests the three alternative publisher implementations:
 - remindersPublisher2() - Using Zip3
 - remindersPublisher3() - Using CombineLatest3
 - remindersPublisher4() - Using Publishers.Sequence with flatMap
 */

@testable import DebuggingChallenge
import Combine
import XCTest

final class AdditionalReminderServiceTests: XCTestCase {

    var sut: DefaultReminderService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = DefaultReminderService(dataSource: ReminderDataSourceStub())
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        sut = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - remindersPublisherUsingZip3 Tests (Zip3 Implementation)

    func testRemindersPublisherUsingZip3() {
        let expectation = expectation(description: "Should fetch all reminders using Zip3")

        sut.remindersPublisherUsingZip3()
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

                let uniqueIds = Set(reminders.map { $0.id })
                XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRemindersPublisherUsingZip3_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders in parallel using Zip3")
        let startTime = Date()

        sut.remindersPublisherUsingZip3()
            .sink { reminders in
                let elapsedTime = Date().timeIntervalSince(startTime)

                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
                XCTAssertLessThan(elapsedTime, 0.5, "Parallel execution should complete in less than 0.5s")

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRemindersPublisherUsingZip3_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using Zip3")

        sut.remindersPublisherUsingZip3()
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12)

                for reminder in reminders {
                    XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
                }

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - remindersPublisherUsingCombineLatest3 Tests (CombineLatest3 Implementation)

    func testRemindersPublisherUsingCombineLatest3() {
        let expectation = expectation(description: "Should fetch all reminders using CombineLatest3")

        sut.remindersPublisherUsingCombineLatest3()
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

                let uniqueIds = Set(reminders.map { $0.id })
                XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRemindersPublisherUsingCombineLatest3_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders in parallel using CombineLatest3")
        let startTime = Date()

        sut.remindersPublisherUsingCombineLatest3()
            .sink { reminders in
                let elapsedTime = Date().timeIntervalSince(startTime)

                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
                XCTAssertLessThan(elapsedTime, 1.0, "Parallel execution should complete in less than 1.0s")

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRemindersPublisherUsingCombineLatest3_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using CombineLatest3")

        sut.remindersPublisherUsingCombineLatest3()
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12)

                for reminder in reminders {
                    XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
                }

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - remindersPublisherUsingPublishersSequence Tests (Publishers.Sequence + flatMap Implementation)

    func testRemindersPublisherUsingPublishersSequence() {
        let expectation = expectation(description: "Should fetch all reminders using Publishers.Sequence")

        sut.remindersPublisherUsingPublishersSequence()
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders to be returned")

                let uniqueIds = Set(reminders.map { $0.id })
                XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs")

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRemindersPublisherUsingPublishersSequence_VerifyParallelExecution() {
        let expectation = expectation(description: "Should fetch reminders in parallel using Publishers.Sequence")
        let startTime = Date()

        sut.remindersPublisherUsingPublishersSequence()
            .sink { reminders in
                let elapsedTime = Date().timeIntervalSince(startTime)

                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders")
                XCTAssertLessThan(elapsedTime, 0.5, "Parallel execution should complete in less than 0.5s")

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    func testRemindersPublisherUsingPublishersSequence_VerifyReminderContent() {
        let expectation = expectation(description: "Should fetch valid reminder objects using Publishers.Sequence")

        sut.remindersPublisherUsingPublishersSequence()
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12)

                for reminder in reminders {
                    XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty")
                }

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Alternative Callback Tests

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
            XCTAssertLessThan(elapsedTime, 0.5, "Should complete in less than 0.5s")

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
            XCTAssertLessThan(elapsedTime, 0.5, "Should complete in less than 0.5s")

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Comparison Tests

    func testAllPublisherImplementationsReturnSameCount() {
        let expectation1 = expectation(description: "Zip3 publisher completes")
        let expectation2 = expectation(description: "CombineLatest3 publisher completes")
        let expectation3 = expectation(description: "Sequence publisher completes")

        var countZip3 = 0
        var countCombineLatest3 = 0
        var countSequence = 0

        sut.remindersPublisherUsingZip3()
            .sink { reminders in
                countZip3 = reminders.count
                expectation1.fulfill()
            }
            .store(in: &cancellables)

        sut.remindersPublisherUsingCombineLatest3()
            .sink { reminders in
                countCombineLatest3 = reminders.count
                expectation2.fulfill()
            }
            .store(in: &cancellables)

        sut.remindersPublisherUsingPublishersSequence()
            .sink { reminders in
                countSequence = reminders.count
                expectation3.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation1, expectation2, expectation3], timeout: 2.0)

        XCTAssertEqual(countZip3, 12, "Zip3 publisher should return 12 reminders")
        XCTAssertEqual(countCombineLatest3, 12, "CombineLatest3 publisher should return 12 reminders")
        XCTAssertEqual(countSequence, 12, "Sequence publisher should return 12 reminders")
        XCTAssertEqual(countZip3, countCombineLatest3, "All implementations should return same count")
        XCTAssertEqual(countCombineLatest3, countSequence, "All implementations should return same count")
    }

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
