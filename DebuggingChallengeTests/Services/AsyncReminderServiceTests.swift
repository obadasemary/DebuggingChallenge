/**
 Tests for alternative Swift Concurrency implementations in DefaultReminderService

 This file tests the three alternative async/await implementations:
 - fetchRemindersUsingAsyncLet: Uses async let for fixed parallel operations
 - fetchRemindersUsingTaskArray: Uses Task array for storing task references
 - fetchRemindersUsingTaskGroupReduce: Uses TaskGroup with reduce for functional style
 */

@testable import DebuggingChallenge
import XCTest

final class AsyncReminderServiceTests: XCTestCase {

    var sut: DefaultReminderService!

    override func setUp() {
        super.setUp()
        sut = DefaultReminderService(dataSource: ReminderDataSourceStub())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - fetchRemindersUsingAsyncLet Tests (async let Implementation)

    func testFetchRemindersUsingAsyncLet() async {
        await assertBasicFetch(
            for: { await self.sut.fetchRemindersUsingAsyncLet() },
            description: "Should fetch all reminders using async let"
        )
    }

    func testFetchRemindersUsingAsyncLet_VerifyParallelExecution() async {
        await assertParallelExecution(
            for: { await self.sut.fetchRemindersUsingAsyncLet() },
            description: "Should fetch reminders in parallel using async let",
            maxTime: 0.5
        )
    }

    func testFetchRemindersUsingAsyncLet_VerifyReminderContent() async {
        await assertReminderContent(
            for: { await self.sut.fetchRemindersUsingAsyncLet() },
            description: "Should fetch valid reminder objects using async let"
        )
    }

    // MARK: - fetchRemindersUsingTaskArray Tests (Task Array Implementation)

    func testFetchRemindersUsingTaskArray() async {
        await assertBasicFetch(
            for: { await self.sut.fetchRemindersUsingTaskArray() },
            description: "Should fetch all reminders using Task array"
        )
    }

    func testFetchRemindersUsingTaskArray_VerifyParallelExecution() async {
        await assertParallelExecution(
            for: { await self.sut.fetchRemindersUsingTaskArray() },
            description: "Should fetch reminders in parallel using Task array",
            maxTime: 0.5
        )
    }

    func testFetchRemindersUsingTaskArray_VerifyReminderContent() async {
        await assertReminderContent(
            for: { await self.sut.fetchRemindersUsingTaskArray() },
            description: "Should fetch valid reminder objects using Task array"
        )
    }

    // MARK: - fetchRemindersUsingTaskGroupReduce Tests (TaskGroup + reduce Implementation)

    func testFetchRemindersUsingTaskGroupReduce() async {
        await assertBasicFetch(
            for: { await self.sut.fetchRemindersUsingTaskGroupReduce() },
            description: "Should fetch all reminders using TaskGroup reduce"
        )
    }

    func testFetchRemindersUsingTaskGroupReduce_VerifyParallelExecution() async {
        await assertParallelExecution(
            for: { await self.sut.fetchRemindersUsingTaskGroupReduce() },
            description: "Should fetch reminders in parallel using TaskGroup reduce",
            maxTime: 0.5
        )
    }

    func testFetchRemindersUsingTaskGroupReduce_VerifyReminderContent() async {
        await assertReminderContent(
            for: { await self.sut.fetchRemindersUsingTaskGroupReduce() },
            description: "Should fetch valid reminder objects using TaskGroup reduce"
        )
    }

    // MARK: - Comparison Tests

    func testAllAsyncImplementationsReturnSameCount() async {
        let remindersAsyncLet = await sut.fetchRemindersUsingAsyncLet()
        let remindersTaskArray = await sut.fetchRemindersUsingTaskArray()
        let remindersTaskGroupReduce = await sut.fetchRemindersUsingTaskGroupReduce()

        XCTAssertEqual(remindersAsyncLet.count, 12, "async let should return 12 reminders")
        XCTAssertEqual(remindersTaskArray.count, 12, "Task array should return 12 reminders")
        XCTAssertEqual(remindersTaskGroupReduce.count, 12, "TaskGroup reduce should return 12 reminders")
        XCTAssertEqual(remindersAsyncLet.count, remindersTaskArray.count, "All implementations should return same count")
        XCTAssertEqual(remindersTaskArray.count, remindersTaskGroupReduce.count, "All implementations should return same count")
    }

    func testAllAsyncImplementationsReturnUniqueReminders() async {
        let remindersAsyncLet = await sut.fetchRemindersUsingAsyncLet()
        let remindersTaskArray = await sut.fetchRemindersUsingTaskArray()
        let remindersTaskGroupReduce = await sut.fetchRemindersUsingTaskGroupReduce()

        let uniqueIdsAsyncLet = Set(remindersAsyncLet.map { $0.id })
        let uniqueIdsTaskArray = Set(remindersTaskArray.map { $0.id })
        let uniqueIdsTaskGroupReduce = Set(remindersTaskGroupReduce.map { $0.id })

        XCTAssertEqual(uniqueIdsAsyncLet.count, 12, "async let should return 12 unique reminders")
        XCTAssertEqual(uniqueIdsTaskArray.count, 12, "Task array should return 12 unique reminders")
        XCTAssertEqual(uniqueIdsTaskGroupReduce.count, 12, "TaskGroup reduce should return 12 unique reminders")
    }
}

private extension AsyncReminderServiceTests {

    // MARK: - Helper Functions

    private func assertBasicFetch(
        for method: @escaping () async -> [Reminder],
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let reminders = await method()

        XCTAssertEqual(reminders.count, 12, "Expected 12 reminders", file: file, line: line)

        let uniqueIds = Set(reminders.map { $0.id })
        XCTAssertEqual(uniqueIds.count, 12, "All reminders should have unique IDs", file: file, line: line)
    }

    private func assertParallelExecution(
        for method: @escaping () async -> [Reminder],
        description: String,
        maxTime: TimeInterval = 0.5,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let startTime = Date()
        let reminders = await method()
        let elapsedTime = Date().timeIntervalSince(startTime)

        XCTAssertEqual(reminders.count, 12, "Expected 12 reminders", file: file, line: line)
        XCTAssertLessThan(elapsedTime, maxTime, "Parallel execution should complete in less than \(maxTime)s (actual: \(elapsedTime)s)", file: file, line: line)
    }

    private func assertReminderContent(
        for method: @escaping () async -> [Reminder],
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let reminders = await method()

        XCTAssertEqual(reminders.count, 12, file: file, line: line)

        for reminder in reminders {
            XCTAssertFalse(reminder.message.isEmpty, "Reminder message should not be empty", file: file, line: line)
        }
    }
}
