import Combine

class AnalyticsDetailsViewModel: ObservableObject {
    @Published var recentProjects: [Project] = []
    @Published var isLoading: Bool = false
    let projectService: ProjectService

    init(projectService: ProjectService) {
        self.projectService = projectService
    }

    @MainActor
    func loadRecentProjects() async {
        Task {
            isLoading = true
            do {
                let projects = await projectService.fetchProjects()
                recentProjects = projects
            } catch {
                print("error \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
