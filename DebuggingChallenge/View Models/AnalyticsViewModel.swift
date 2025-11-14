import Combine

class AnalyticsViewModel: ObservableObject {
    @Published var analyticsDetails: [AnalyticsDetails] = []
    @Published var recentProjects: [Project] = []
    @Published var isLoading: Bool = false
    let analyticsService: AnalyticsService
    let projectService: ProjectService

    init(analyticsService: AnalyticsService, projectService: ProjectService) {
        self.analyticsService = analyticsService
        self.projectService = projectService
    }

    @MainActor
    func loadAnalytics() async {
        isLoading = true
        async let details = analyticsService.fetchAnalyticsDetails()
        async let projects = projectService.fetchProjects()
        analyticsDetails = await details
        recentProjects = await projects
        isLoading = false
    }
}
