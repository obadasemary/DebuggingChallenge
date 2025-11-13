import SwiftUI

class MainCoordinator: ObservableObject {
    @Published var projectPath = NavigationPath()
    @Published var analyticsPath = NavigationPath()

    func navigateToProject(_ project: Project) {
        projectPath.append(project)
    }

    func navigateToWorkItem(_ item: WorkItem) {
        projectPath.append(item)
    }

    func navigateToAnalytics(_ details: AnalyticsDetails) {
        analyticsPath.append(details)
    }

    func popToRoot() {
        projectPath.removeLast(projectPath.count)
        analyticsPath.removeLast(analyticsPath.count)
    }
}
