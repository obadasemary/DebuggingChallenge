/**
 Additional tests for alternative Combine implementations in DefaultReminderService

 This file tests the three alternative publisher implementations:
 - remindersPublisherUsingZip3: Uses Publishers.Zip3 for parallel fetching
 - remindersPublisherUsingCombineLatest3: Uses Publishers.CombineLatest3
 - remindersPublisherUsingPublishersSequence: Uses Publishers.Sequence with flatMap
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
}
