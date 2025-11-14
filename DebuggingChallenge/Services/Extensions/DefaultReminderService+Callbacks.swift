/**
 Callback-based extensions for DefaultReminderService

 This file contains four alternative callback implementations for parallel reminder fetching:
 - fetchRemindersWithBarrier: Uses concurrent queue with barrier flags
 - fetchRemindersWithSemaphore: Uses DispatchSemaphore for synchronization
 - fetchRemindersWithLock: Uses NSLock for mutual exclusion
 - fetchRemindersWithSerialQueue: Uses serial DispatchQueue for ordered execution
 */

import Foundation

extension DefaultReminderService {

    // MARK: - Callback Implementations

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
