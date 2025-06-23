import SwiftUI

enum TabItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case detection = "Detection"
    case library = "Library"
    case simulation = "Simulation"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard:
            return "chart.bar.xaxis"
        case .detection:
            return "camera.viewfinder"
        case .library:
            return "cube.box"
        case .simulation:
            return "gearshape.2"
        case .settings:
            return "slider.horizontal.3"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .dashboard:
            return "chart.bar.xaxis.fill"
        case .detection:
            return "camera.viewfinder.fill"
        case .library:
            return "cube.box.fill"
        case .simulation:
            return "gearshape.2.fill"
        case .settings:
            return "slider.horizontal.3.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabItem
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabItemView(tab: tab, selectedTab: $selectedTab)
            }
        }
        .padding(.vertical, 8)
        .background(AppColors.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct TabItemView: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(selectedTab == tab ? AppColors.accent.opacity(0.2) : Color.clear)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: selectedTab == tab ? tab.activeIcon : tab.icon)
                        .font(.system(size: 18))
                        .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.secondaryText)
                }
                
                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(selectedTab == tab ? .medium : .regular)
                    .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(.dashboard))
    }
    .background(AppColors.background)
} 