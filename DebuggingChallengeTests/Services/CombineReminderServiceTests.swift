/**
 Combine tests for alternative Combine implementations in DefaultReminderService

 This file tests the three alternative publisher implementations:
 - remindersPublisherUsingZip3: Uses Publishers.Zip3 for parallel fetching
 - remindersPublisherUsingCombineLatest3: Uses Publishers.CombineLatest3
 - remindersPublisherUsingPublishersSequence: Uses Publishers.Sequence with flatMap
 */

@testable import DebuggingChallenge
import Combine
import XCTest

final class CombineReminderServiceTests: XCTestCase {

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
        assertBasicFetch(
            for: sut.remindersPublisherUsingZip3(),
            description: "Should fetch all reminders using Zip3"
        )
    }

    func testRemindersPublisherUsingZip3_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.remindersPublisherUsingZip3(),
            description: "Should fetch reminders in parallel using Zip3",
            maxTime: 1.0
        )
    }

    func testRemindersPublisherUsingZip3_VerifyReminderContent() {
        assertReminderContent(
            for: sut.remindersPublisherUsingZip3(),
            description: "Should fetch valid reminder objects using Zip3"
        )
    }

    // MARK: - remindersPublisherUsingCombineLatest3 Tests (CombineLatest3 Implementation)

    func testRemindersPublisherUsingCombineLatest3() {
        assertBasicFetch(
            for: sut.remindersPublisherUsingCombineLatest3(),
            description: "Should fetch all reminders using CombineLatest3"
        )
    }

    func testRemindersPublisherUsingCombineLatest3_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.remindersPublisherUsingCombineLatest3(),
            description: "Should fetch reminders in parallel using CombineLatest3",
            maxTime: 1.0
        )
    }

    func testRemindersPublisherUsingCombineLatest3_VerifyReminderContent() {
        assertReminderContent(
            for: sut.remindersPublisherUsingCombineLatest3(),
            description: "Should fetch valid reminder objects using CombineLatest3"
        )
    }

    // MARK: - remindersPublisherUsingPublishersSequence Tests (Publishers.Sequence + flatMap Implementation)

    func testRemindersPublisherUsingPublishersSequence() {
        assertBasicFetch(
            for: sut.remindersPublisherUsingPublishersSequence(),
            description: "Should fetch all reminders using Publishers.Sequence"
        )
    }

    func testRemindersPublisherUsingPublishersSequence_VerifyParallelExecution() {
        assertParallelExecution(
            for: sut.remindersPublisherUsingPublishersSequence(),
            description: "Should fetch reminders in parallel using Publishers.Sequence",
            maxTime: 1.0
        )
    }

    func testRemindersPublisherUsingPublishersSequence_VerifyReminderContent() {
        assertReminderContent(
            for: sut.remindersPublisherUsingPublishersSequence(),
            description: "Should fetch valid reminder objects using Publishers.Sequence"
        )
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

private extension CombineReminderServiceTests {
    
    // MARK: - Helper Functions

    private func assertBasicFetch(
        for publisher: AnyPublisher<[Reminder], Never>,
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: description)

        publisher
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders", file: file, line: line)

                let uniqueIds = Set(reminders.map { $0.id })
                XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs", file: file, line: line)

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    private func assertParallelExecution(
        for publisher: AnyPublisher<[Reminder], Never>,
        description: String,
        maxTime: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: description)
        let startTime = Date()

        publisher
            .sink { reminders in
                let elapsedTime = Date().timeIntervalSince(startTime)

                XCTAssertEqual(reminders.count, 12, "Expected 12 reminders", file: file, line: line)
                XCTAssertLessThan(elapsedTime, maxTime, "Parallel execution should complete in less than \(maxTime)s", file: file, line: line)

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }

    private func assertReminderContent(
        for publisher: AnyPublisher<[Reminder], Never>,
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = expectation(description: description)

        publisher
            .sink { reminders in
                XCTAssertEqual(reminders.count, 12, file: file, line: line)

                for reminder in reminders {
                    XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty", file: file, line: line)
                }

                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
    }
}
