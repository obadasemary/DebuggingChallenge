/**
 Combine-based extensions for DefaultReminderService

 This file contains three alternative Combine implementations for parallel reminder fetching:
 - remindersPublisherUsingZip3: Uses Publishers.Zip3
 - remindersPublisherUsingCombineLatest3: Uses Publishers.CombineLatest3
 - remindersPublisherUsingPublishersSequence: Uses Publishers.Sequence with flatMap
 */

import Combine
import Foundation

extension DefaultReminderService {

    // MARK: - Combine Implementations

    /**
     Fetches reminders in parallel using Publishers.Zip3 to combine three publisher streams.

     This implementation creates three independent Future publishers and combines them using Zip3,
     which waits for all three to complete before emitting the combined result.

     - Returns: A publisher that emits an array of all fetched reminders when all three pages complete

     ## How It Works
     1. Creates three separate Future publishers, each fetching one page
     2. Combines them using Publishers.Zip3
     3. Maps the tuple of arrays into a single flattened array
     4. Returns an AnyPublisher type-erased result

     ## Pros
     - **Explicit and readable**: Clear intent to fetch exactly 3 pages
     - **Type-safe**: Zip3 preserves individual publisher types
     - **Guaranteed completion**: Only emits when ALL publishers complete
     - **No buffering**: Minimal memory overhead
     - **Predictable timing**: Completes when slowest publisher finishes
     - **Simple composition**: Easy to understand data flow

     ## Cons
     - **Fixed count**: Hardcoded to exactly 3 publishers (not flexible)
     - **Verbose setup**: Need to explicitly create each publisher
     - **Scalability**: Would need Zip4, Zip5, etc. for more publishers
     - **Tuple handling**: Result is a tuple that needs mapping
     - **No early completion**: Must wait for all, even if some fail

     ## Best Used When
     - You know the exact number of sources (2-4 publishers)
     - All sources must complete before processing results
     - Want explicit, type-safe composition
     - Working with small, fixed number of parallel operations
     - Need predictable completion behavior

     ## 💡 Tip
     For more than 4 publishers, consider using Publishers.MergeMany or Publishers.Sequence
     instead of creating Zip5, Zip6, etc.
     */
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

    /**
     Fetches reminders in parallel using Publishers.CombineLatest3 to merge three publisher streams.

     This implementation creates three Future publishers and combines them using CombineLatest3,
     which emits whenever ANY publisher emits a new value (though Futures only emit once).

     - Returns: A publisher that emits an array of all fetched reminders when all three pages complete

     ## How It Works
     1. Creates an array of three Future publishers
     2. Combines them using Publishers.CombineLatest3
     3. Maps the tuple into a single flattened array
     4. Returns an AnyPublisher type-erased result

     ## Pros
     - **Reactive updates**: Would emit on every change if publishers emitted multiple values
     - **Latest values**: Always has the most recent value from each publisher
     - **Good for UI**: Useful when displaying live-updating data
     - **Flexible**: Can handle publishers that emit multiple values
     - **Type-safe**: Preserves publisher types like Zip3

     ## Cons
     - **Overkill for single emissions**: Futures only emit once, making this identical to Zip3
     - **Fixed count**: Hardcoded to exactly 3 publishers
     - **Memory overhead**: Stores latest value from each publisher
     - **Confusing choice**: Not semantically correct for one-time operations
     - **Tuple handling**: Requires mapping from tuple to array

     ## Best Used When
     - Publishers emit multiple values over time
     - Need to react to latest state from multiple sources
     - Building reactive UI that updates as data changes
     - Combining streams like user input, network state, etc.
     - Want to display "current state" from multiple publishers

     ## ⚠️ Note
     For single-emission publishers like Future, Zip3 is more semantically appropriate.
     CombineLatest shines with publishers that emit multiple values (like @Published properties).

     ## Example Use Cases
     - Combining user location + network status + authentication state
     - Displaying form validation (username valid + password valid + email valid)
     - Reactive search (search term + filter options + sort order)
     */
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

    /**
     Fetches reminders in parallel using Publishers.Sequence with flatMap for dynamic concurrency.

     This implementation creates a sequence of Future publishers and flattens them with controlled
     parallelism using flatMap's maxPublishers parameter.

     - Returns: A publisher that emits an array of all fetched reminders when all pages complete

     ## How It Works
     1. Creates an array of Future publishers using map
     2. Wraps them in Publishers.Sequence
     3. Uses flatMap with maxPublishers: .max(3) to control parallelism
     4. Collects all results into a single array
     5. Flattens nested arrays and returns AnyPublisher

     ## Pros
     - **Scalable**: Works with any number of publishers (not limited to 3)
     - **Controlled concurrency**: maxPublishers limits parallel execution
     - **Flexible**: Can easily change number of pages to fetch
     - **Composable**: Easy to add more publishers dynamically
     - **Production-ready**: Handles variable data sources
     - **Best for dynamic scenarios**: Number of fetches can be determined at runtime

     ## Cons
     - **More complex**: Harder to understand than Zip3
     - **Buffering**: collect() buffers all results in memory
     - **Less explicit**: Concurrency control is implicit in maxPublishers
     - **Nested mapping**: Requires map { $0.flatMap { $0 } } to flatten
     - **Harder to debug**: More operators in the chain

     ## Best Used When
     - Number of publishers is dynamic or configurable
     - Need to control concurrency (limit parallel operations)
     - Working with variable-length data sources
     - Building reusable, generic publisher chains
     - Want to limit resource usage (network, CPU, etc.)

     ## ✅ Recommended
     This is the most flexible and production-ready approach for scenarios where the number
     of parallel operations might vary or needs to be constrained.

     ## Example Use Cases
     - Fetching pages dynamically (1-100 pages based on user data)
     - Batch processing with concurrency limits
     - Parallel image downloads with max concurrent requests
     - Processing arrays of unknown size with controlled parallelism
     */
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
}
