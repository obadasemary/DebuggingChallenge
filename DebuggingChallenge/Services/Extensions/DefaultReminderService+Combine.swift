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
}
