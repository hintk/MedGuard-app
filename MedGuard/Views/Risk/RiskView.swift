import SwiftUI

struct RiskView: View {
    private let risks = MockData.riskInfos
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Text("根据当前药品档案生成的风险提示")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.horizontal, Theme.Spacing.md)
                    
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(risks) { risk in
                            RiskCard(risk: risk)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("风险")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.Colors.background.opacity(0.9), for: .navigationBar)
        }
    }
}

#Preview {
    RiskView()
}
