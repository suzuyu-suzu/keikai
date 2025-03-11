import SwiftUI

@main
struct KeikaiApp: App {
    @StateObject private var dataStore = DataStore()
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dataStore)
                .environmentObject(healthKitManager)
        }
    }
}
