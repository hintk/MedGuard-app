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

            ScanView()
                .tabItem {
                    Label("扫描", systemImage: "barcode.viewfinder")
                }
                .tag(1)

            MedicationArchiveView()
                .tabItem {
                    Label("档案", systemImage: "pills.fill")
                }
                .tag(2)

            RiskView()
                .tabItem {
                    Label("风险", systemImage: "exclamationmark.triangle.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(Theme.Colors.healthBlue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthStore.shared)
        .environmentObject(MedicationStore())
}
