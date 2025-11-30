import SwiftUI

@main
struct SelectFoodsApp: App {
    private let menuRepository = InMemoryMenuRepository()
    private let planRepository = InMemoryPlanRepository(startDate: Calendar.current.startOfDay(for: Date()), endDate: Calendar.current.date(byAdding: .day, value: 6, to: Date()) ?? Date())

    var body: some Scene {
        WindowGroup {
            ContentView(menuRepository: menuRepository, planRepository: planRepository)
        }
    }
}
