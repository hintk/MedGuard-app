import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var selectedTab = 0

    var body: some View {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("首页", systemImage: "house.fill")
                    }
                    .tag(0)
                    .accessibilityLabel("首页标签")

                ScanView()
                    .tabItem {
                        Label("扫描", systemImage: "barcode.viewfinder")
                    }
                    .tag(1)
                    .accessibilityLabel("扫描标签")

                MedicationArchiveView()
                    .tabItem {
                        Label("档案", systemImage: "pills.fill")
                    }
                    .tag(2)
                    .accessibilityLabel("档案标签")

                RiskView()
                    .tabItem {
                        Label("风险", systemImage: "exclamationmark.triangle.fill")
                    }
                    .tag(3)
                    .accessibilityLabel("风险标签")

                ProfileView()
                    .tabItem {
                        Label("我的", systemImage: "person.fill")
                        if authStore.unreadCount > 0 {
                            Text("\(authStore.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.Colors.danger)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -8)
                        }
                    }
                    .tag(4)
                    .accessibilityLabel("我的标签")
            }
            .tint(Theme.Colors.healthBlue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthStore.shared)
        .environmentObject(MedicationStore())
}
