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
    private let dataSource: ReminderDataSource

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
    
    // Approach 1: Using Zip3
    func remindersPublisherUsingZip3() -> AnyPublisher<[Reminder], Never> {
        let publisher1 = Future<[Reminder], Never> { promise in
            self.dataSource.fetchReminders { reminders in
                promise(.success(reminders))
            }
        }

        let publisher2 = Future<[Reminder], Never> { promise in
            self.dataSource.fetchReminders { reminders in
                promise(.success(reminders))
            }
        }

        let publisher3 = Future<[Reminder], Never> { promise in
            self.dataSource.fetchReminders { reminders in
                promise(.success(reminders))
            }
        }

        return Publishers.Zip3(publisher1, publisher2, publisher3)
            .map { $0 + $1 + $2 }
            .eraseToAnyPublisher()
    }

    // Approach 2: Using CombineLatest3
    func remindersPublisherUsingCombineLatest3() -> AnyPublisher<[Reminder], Never> {
        let publishers = (0..<3).map { _ in
            Future<[Reminder], Never> { promise in
                self.dataSource.fetchReminders { reminders in
                    promise(.success(reminders))
                }
            }
            .eraseToAnyPublisher()
        }

        return Publishers.CombineLatest3(publishers[0], publishers[1], publishers[2])
            .map { $0 + $1 + $2 }
            .eraseToAnyPublisher()
    }

    // Approach 3: Using Publishers.Sequence with flatMap
    func remindersPublisherUsingPublishersSequence() -> AnyPublisher<[Reminder], Never> {
        let publishers = (0..<3).map { _ in
            Future<[Reminder], Never> { promise in
                self.dataSource.fetchReminders { reminders in
                    promise(.success(reminders))
                }
            }
        }

        return Publishers.Sequence(sequence: publishers)
            .flatMap(maxPublishers: .max(3)) { $0 }
            .collect()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }

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

    // MARK: - Alternative Callback Implementations

    // Approach 1: Using DispatchQueue with barriers for thread-safe array access
    func fetchRemindersWithBarrier(completion: @escaping ([Reminder]) -> Void) {
        var reminders: [Reminder] = []
        let concurrentQueue = DispatchQueue(label: "com.reminder.barrier", attributes: .concurrent)
        let group = DispatchGroup()

        for _ in 0..<3 {
            group.enter()
            dataSource.fetchReminders { newReminders in
                concurrentQueue.async(flags: .barrier) {
                    reminders.append(contentsOf: newReminders)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(reminders)
        }
    }

    // Approach 2: Using DispatchSemaphore to coordinate parallel fetches
    func fetchRemindersWithSemaphore(completion: @escaping ([Reminder]) -> Void) {
        var reminders: [Reminder] = []
        let semaphore = DispatchSemaphore(value: 1)
        let group = DispatchGroup()

        for _ in 0..<3 {
            group.enter()
            dataSource.fetchReminders { newReminders in
                semaphore.wait()
                reminders.append(contentsOf: newReminders)
                semaphore.signal()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(reminders)
        }
    }

    // Approach 3: Using NSLock for thread-safe array access
    func fetchRemindersWithLock(completion: @escaping ([Reminder]) -> Void) {
        var reminders: [Reminder] = []
        let lock = NSLock()
        let group = DispatchGroup()

        for _ in 0..<3 {
            group.enter()
            dataSource.fetchReminders { newReminders in
                lock.lock()
                reminders.append(contentsOf: newReminders)
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(reminders)
        }
    }

    // Approach 4: Using serial queue for thread-safe array access
    func fetchRemindersWithSerialQueue(completion: @escaping ([Reminder]) -> Void) {
        var reminders: [Reminder] = []
        let serialQueue = DispatchQueue(label: "com.reminder.serial")
        let group = DispatchGroup()

        for _ in 0..<3 {
            group.enter()
            dataSource.fetchReminders { newReminders in
                serialQueue.async {
                    reminders.append(contentsOf: newReminders)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(reminders)
        }
    }
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
