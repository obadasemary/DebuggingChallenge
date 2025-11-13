import Combine

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    let projectService: ProjectService

    init(projectService: ProjectService) {
        self.projectService = projectService
    }
    
    func loadProjects() async {
        Task {
            isLoading = true
            
            do {
                let fetchedProjects = await projectService.fetchProjects()
                projects = fetchedProjects
            } catch {
                print(
                    "Error while fetchedProjects \(error.localizedDescription)"
                )
            }
            isLoading = false
        }
    }
}
