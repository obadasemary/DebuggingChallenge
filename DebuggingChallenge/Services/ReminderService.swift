/**
 # Task #2

 ## Task
 Fix the concurrency implementation in `DefaultReminderService` to correctly handle parallel reminder fetching using three different paradigms:

 1. Callback-Based (`fetchReminders`)
 2. Combine (`remindersPublisher`)
 3. Swift Concurrency (`fetchRemindersAsync`)

 Each implementation must:
 - Fetch three pages of reminders in parallel
 - Return a total of 12 reminders
 - Pass all associated tests in `DefaultReminderServiceTests`

 ## Success Criteria
 - All tests in `DefaultReminderServiceTests` pass successfully
 - Each method fetches exactly three pages concurrently
 - All methods return 12 unique reminders
 - Each implementation uses its designated concurrency paradigm
 - Each method has a unique implementation

 ## Important Notes
 - Some files are marked as "DO NOT MODIFY" - these must remain unchanged
 - In certain files, only specific sections are marked as protected with clear comments
 - Modifying any protected code (either entire files or marked sections) will result in automatic task failure
 - Work with the existing code structure; do not rewrite from scratch
 - Stay within each method's designated paradigm (Callbacks/Combine/Swift Concurrency)
 - Do not call other methods of the class within implementations
 */

import Combine
import Foundation

final class DefaultReminderService: ReminderService {
    let dataSource: ReminderDataSource

    init(dataSource: ReminderDataSource) {
        self.dataSource = dataSource
    }

    func fetchReminders(completion: @escaping ([Reminder]) -> Void) {
        var reminders: [Reminder] = []
        let group = DispatchGroup()

        for _ in 0 ..< 3 {
            group.enter()
            dataSource.fetchReminders { newReminders in
                reminders.append(contentsOf: newReminders)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(reminders)
        }
    }

    func remindersPublisher() -> AnyPublisher<[Reminder], Never> {
        let puplishers = (0..<3).map { _ in
            Future<[Reminder], Never> { promise in
                self.dataSource.fetchReminders { reminders in
                    promise(.success(reminders))
                }
            }
        }
        
        return Publishers.MergeMany(puplishers)
            .collect()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }

    // MARK: - Swift Concurrency Approach #1: TaskGroup with for-await
    // Uses structured concurrency with TaskGroup to spawn multiple parallel tasks
    // and collect results iteratively
    func fetchRemindersAsync() async -> [Reminder] {
        await withTaskGroup(of: [Reminder].self) { group in
            for _ in 0..<3 {
                group.addTask {
                    await self.dataSource.fetchReminders()
                }
            }

            var allReminders: [Reminder] = []

            for await reminders in group {
                allReminders.append(contentsOf: reminders)
            }

            return allReminders
        }
    }

    // MARK: - Swift Concurrency Approach #2: async let
    // Uses async let bindings for fixed number of parallel operations
    // Clean syntax for when you know the exact number of concurrent calls
    /*
    func fetchRemindersAsync() async -> [Reminder] {
        async let reminders1 = dataSource.fetchReminders()
        async let reminders2 = dataSource.fetchReminders()
        async let reminders3 = dataSource.fetchReminders()

        let results = await [reminders1, reminders2, reminders3]
        return results.flatMap { $0 }
    }
    */

    // MARK: - Swift Concurrency Approach #3: Task Array
    // Creates an array of Tasks and awaits them all
    // Useful when you need to store task references
    /*
    func fetchRemindersAsync() async -> [Reminder] {
        let tasks = (0..<3).map { _ in
            Task {
                await dataSource.fetchReminders()
            }
        }

        var allReminders: [Reminder] = []

        for task in tasks {
            let reminders = await task.value
            allReminders.append(contentsOf: reminders)
        }

        return allReminders
    }
    */

    // MARK: - Swift Concurrency Approach #4: TaskGroup with reduce
    // Uses TaskGroup but collects results functionally with reduce
    // More functional programming style
    /*
    func fetchRemindersAsync() async -> [Reminder] {
        await withTaskGroup(of: [Reminder].self) { group in
            for _ in 0..<3 {
                group.addTask {
                    await self.dataSource.fetchReminders()
                }
            }

            return await group.reduce(into: [Reminder]()) { result, reminders in
                result.append(contentsOf: reminders)
            }
        }
    }
    */
}
/*
 *****************************************************************************
 *                                                                           *
 *     >>>>>>>>>>>  DO NOT MODIFY ANYTHING FROM THIS POINT  <<<<<<<<<<<      *
 *                                                                           *
 *                YOU WILL AUTOMATICALLY FAIL IF YOU DO!                     *
 *                                                                           *
 *****************************************************************************
 */

protocol ReminderService: AnyObject {
    func fetchReminders(completion: @escaping ([Reminder]) -> Void)
    func remindersPublisher() -> AnyPublisher<[Reminder], Never>
    func fetchRemindersAsync() async -> [Reminder]
}

protocol ReminderDataSource: AnyObject {
    func fetchReminders(completion: @escaping ([Reminder]) -> Void)
    func fetchReminders() async -> [Reminder]
}
