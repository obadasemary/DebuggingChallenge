# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS debugging challenge project built with SwiftUI. The application is a task management system with three debugging tasks that test different aspects of iOS development: UI bugs and memory leaks, concurrency patterns, and authentication flows.

## Development Commands

### Building and Running

```bash
# Build the project
xcodebuild -project DebuggingChallenge.xcodeproj -scheme DebuggingChallenge build

# Run tests
xcodebuild test -project DebuggingChallenge.xcodeproj -scheme DebuggingChallenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Run specific test class
xcodebuild test -project DebuggingChallenge.xcodeproj -scheme DebuggingChallenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DebuggingChallengeTests/DefaultReminderServiceTests

# Run single test method
xcodebuild test -project DebuggingChallenge.xcodeproj -scheme DebuggingChallenge -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:DebuggingChallengeTests/DefaultReminderServiceTests/testFetchReminders
```

## Architecture Overview

### Application Structure

The app uses a SwiftUI-based architecture with the following key components:

- **Entry Point**: `DebuggingChallengeApp.swift` - Controls switching between login and main screens via `CurrentScreen` enum
- **Coordinator Pattern**: `MainCoordinator.swift` manages navigation state for both Projects and Analytics tabs using `NavigationPath`
- **MVVM Pattern**: View models handle business logic and state management, marked with `@MainActor` for UI safety

### Core Components

**Navigation Flow:**
- Two-screen flow: Login → Main (TabView with Projects/Analytics tabs)
- `MainCoordinator` maintains separate navigation paths for Projects and Analytics tabs
- Navigation uses `NavigationPath` with type-safe navigation via `.append()` for `Project`, `WorkItem`, and `AnalyticsDetails`

**View Models:**
- `ProjectsViewModel` - Manages project list and loading state
- `AnalyticsViewModel` - Handles analytics metrics and recent projects
- `AnalyticsDetailsViewModel` - Manages detailed metric views
- All view models are `@MainActor` and use `ObservableObject` protocol

**Services:**
- `ProjectService` protocol with `MockProjectService` - Fetches project data (DO NOT MODIFY)
- `AnalyticsService` with `MockAnalyticsService` - Provides analytics data
- `ReminderService` with `DefaultReminderService` - Handles three concurrency patterns (callbacks, Combine, async/await)
- `SessionService` with `DefaultSessionService` - Manages user sessions

**Data Models:**
- `Project` - Contains id, name, and array of `WorkItem` (DO NOT MODIFY)
- `WorkItem` - Task items with id, title, and priority
- `Priority` - Enum for task priorities
- `AnalyticsDetails` - Detailed metrics with historical data
- `Reminder` - Used in concurrency tests

### Key Architecture Patterns

**State Management:**
- Use `@StateObject` for view model initialization in views
- Use `@Published` properties in view models for reactive updates
- Pass services via dependency injection in initializers

**Concurrency:**
- Services use async/await patterns
- View models wrap async calls in `Task` blocks
- `ReminderService` demonstrates three concurrency paradigms side-by-side

**Navigation:**
- Environment object for coordinator shared across tab views
- Type-safe navigation using strongly-typed models (not strings/IDs)

## Critical Constraints

### Protected Code Sections

**DO NOT MODIFY** entire files:
- `DebuggingChallenge/Services/ProjectService.swift`
- `DebuggingChallenge/Entities/Project.swift`
- `DebuggingChallengeTests/Services/DefaultReminderServiceTests.swift`
- `DebuggingChallengeTests/Stubs/ReminderDataSourceStub.swift`

**Protected sections** (marked with comment blocks):
- `ReminderService.swift` - Lines 92-112 (protocols below "DO NOT MODIFY" marker)
- Any code marked with "DO NOT MODIFY" comment blocks

**Task-Specific Requirements:**
- Task #1: Fix UI bugs, memory leaks, and crashes in the main app without modifying protected files
- Task #2: Fix concurrency in `DefaultReminderService` - each method must use its designated paradigm (callbacks/Combine/async-await) and fetch 3 pages in parallel returning 12 reminders
- Task #3: Fix single bug preventing login screen from working

### Development Constraints (from README)

- No external libraries
- No AI coding assistants during actual challenge
- Can use official Apple documentation
- Can use standard IDE debugging tools

## Task Switching

To switch between tasks, modify `currentScreen` in `DebuggingChallengeApp.swift`:
- `.login` - Start at Task #3 (login bug)
- `.main` - Start at Task #1 (main app debugging)

Task #2 tests are always available via `DefaultReminderServiceTests`.

## Testing Strategy

**For ReminderService (Task #2):**
- `testFetchReminders()` - Validates callback-based implementation returns 12 reminders
- `testRemindersPublisher()` - Validates Combine implementation returns 12 unique reminders
- `testFetchRemindersAsync()` - Validates async/await returns 12 reminders in <0.5s (parallel execution)

Each test expects exactly 12 reminders from 3 parallel page fetches (4 reminders per page).

## Common Issues to Watch For

Based on the task descriptions, be aware of:
- Memory leaks from retain cycles (especially with closures and coordinators)
- Navigation path management issues
- Task lifecycle and actor isolation in SwiftUI
- Concurrent data access in the callback-based reminder fetching
- Proper Combine publisher composition for parallel operations
