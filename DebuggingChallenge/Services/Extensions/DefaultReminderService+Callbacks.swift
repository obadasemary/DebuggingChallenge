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

    /**
     Fetches reminders in parallel using a concurrent queue with barrier flags for thread-safe writes.

     This implementation uses a concurrent DispatchQueue and applies the `.barrier` flag to write operations,
     ensuring that writes happen exclusively while allowing concurrent reads (if any existed).

     - Parameter completion: Completion handler called on the main queue with all fetched reminders

     ## How It Works
     1. Creates a concurrent queue for parallel operations
     2. Fetches 3 pages in parallel using DispatchGroup
     3. Uses barrier flag to serialize writes to the shared array
     4. Notifies completion on main queue when all fetches complete

     ## Pros
     - **Most efficient for read-heavy scenarios**: Allows concurrent reads while serializing writes
     - **Better performance**: Concurrent queue enables parallel execution where possible
     - **Scalable**: Can handle multiple readers without blocking
     - **GCD-native**: Uses built-in Grand Central Dispatch features

     ## Cons
     - **Overkill for write-only scenarios**: No concurrent reads in this use case
     - **Slightly more complex**: Requires understanding of barrier semantics
     - **Queue overhead**: Creates additional queue infrastructure
     - **Not the simplest option**: More moving parts than simpler approaches

     ## Best Used When
     - You have both read and write operations
     - Performance optimization is critical
     - Working with read-heavy data structures
     - Building reusable concurrent data structures
     */
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

    /**
     Fetches reminders in parallel using DispatchSemaphore to synchronize access to shared state.

     This implementation uses a binary semaphore (value: 1) to create a mutex, ensuring only one thread
     can modify the reminders array at a time.

     - Parameter completion: Completion handler called on the main queue with all fetched reminders

     ## How It Works
     1. Creates a binary semaphore with initial value 1
     2. Fetches 3 pages in parallel using DispatchGroup
     3. Uses wait() before and signal() after each write operation
     4. Notifies completion on main queue when all fetches complete

     ## Pros
     - **Traditional concurrency primitive**: Well-understood pattern from other languages
     - **Explicit control**: Clear entry and exit points for critical sections
     - **Low overhead**: Minimal memory footprint
     - **Cross-platform knowledge**: Semaphores exist in many languages

     ## Cons
     - **Can cause priority inversion**: Lower priority thread holding semaphore blocks higher priority threads
     - **Potential deadlocks**: If signal() isn't called, other threads wait forever
     - **Error-prone**: Easy to forget signal() in error paths
     - **Slower than some alternatives**: Serializes all writes completely
     - **Not recommended by Apple**: Apple discourages semaphore use for synchronization

     ## Best Used When
     - Porting code from other languages that use semaphores
     - Working with legacy codebases that use semaphores
     - Need to limit access to N resources (not just mutex)
     - Educational purposes to understand semaphore patterns

     ## ⚠️ Warning
     Apple recommends using other synchronization primitives (locks, serial queues) over semaphores
     for most use cases to avoid priority inversion issues.
     */
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

    /**
     Fetches reminders in parallel using NSLock for mutual exclusion of shared state.

     This implementation uses NSLock to create a mutex that protects the reminders array from
     concurrent modifications.

     - Parameter completion: Completion handler called on the main queue with all fetched reminders

     ## How It Works
     1. Creates an NSLock instance
     2. Fetches 3 pages in parallel using DispatchGroup
     3. Uses lock() before and unlock() after each write operation
     4. Notifies completion on main queue when all fetches complete

     ## Pros
     - **Simple and straightforward**: Easy to understand lock/unlock pattern
     - **Explicit locking**: Clear critical sections in code
     - **Low overhead**: Minimal performance impact
     - **Well-tested**: NSLock is a mature, reliable API
     - **No priority inversion**: Unlike semaphores, NSLock handles priority properly

     ## Cons
     - **Verbose**: Requires explicit lock() and unlock() calls
     - **Error-prone**: Must remember to unlock in all code paths (including errors)
     - **No automatic unlocking**: Unlike defer or RAII patterns
     - **Can't be used with defer easily**: Need manual unlock management
     - **Blocking**: Threads wait when lock is held by another thread

     ## Best Used When
     - Need simple mutual exclusion
     - Critical sections are short and well-defined
     - Working with traditional locking patterns
     - Migrating from Objective-C code
     - Want explicit control over lock duration

     ## 💡 Tip
     Consider using `defer { lock.unlock() }` immediately after `lock.lock()` to ensure
     unlocking happens even if early returns or errors occur.
     */
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

    /**
     Fetches reminders in parallel using a serial DispatchQueue for thread-safe array access.

     This implementation delegates all array modifications to a serial queue, ensuring operations
     execute one at a time in FIFO order.

     - Parameter completion: Completion handler called on the main queue with all fetched reminders

     ## How It Works
     1. Creates a serial DispatchQueue
     2. Fetches 3 pages in parallel using DispatchGroup
     3. Dispatches all write operations to the serial queue
     4. Notifies completion on main queue when all fetches complete

     ## Pros
     - **Simplest and safest**: No explicit locking needed
     - **Apple-recommended**: Preferred pattern for thread-safety in Swift
     - **FIFO ordering**: Guaranteed order of operations
     - **No deadlock risk**: Serial queue prevents common deadlock scenarios
     - **Clean code**: No lock/unlock boilerplate
     - **Composable**: Easy to add more operations to the queue

     ## Cons
     - **Queue overhead**: Creates additional dispatch queue
     - **Async overhead**: Small performance cost of async dispatch
     - **Less explicit**: Synchronization is implicit via queue
     - **Slightly slower**: Queue dispatch adds minimal latency
     - **Memory**: Additional queue structure in memory

     ## Best Used When
     - Need simple, safe thread synchronization
     - Following Apple's recommended patterns
     - Want clean, maintainable code
     - Building new Swift code (not porting from other languages)
     - Critical section needs guaranteed ordering

     ## ✅ Recommended
     This is generally the recommended approach for thread-safety in Swift/iOS development
     due to its simplicity, safety, and alignment with Apple's concurrency patterns.
     */
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
