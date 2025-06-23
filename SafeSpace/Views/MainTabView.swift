import SwiftUI

struct MainTabView: View {
    @StateObject private var appState = AppState()
    @State private var selectedTab: TabItem = .dashboard
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 80)
                }
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom)
        }
        .background(AppColors.background)
        .environmentObject(appState)
    }
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .dashboard:
            DashboardView()
        case .detection:
            DetectionView()
        case .library:
            LibraryView()
        case .simulation:
            SimulationView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    MainTabView()
} 