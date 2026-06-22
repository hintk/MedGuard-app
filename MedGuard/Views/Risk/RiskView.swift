import SwiftUI

struct RiskView: View {
    @EnvironmentObject private var medicationStore: MedicationStore

    @State private var aiRisks: [DoubaoService.InteractionRisk] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    if medicationStore.medications.count < 2 {
                        emptyState(icon: "checkmark.shield.fill",
                                   title: "药品不足",
                                   message: "添加至少 2 种药品后才能分析相互作用风险")
                    } else if isLoading {
                        VStack(spacing: Theme.Spacing.md) {
                            ProgressView().scaleEffect(1.5)
                            Text("AI 正在分析药物相互作用...")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xxl)
                    } else if let error = errorMessage {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40)).foregroundStyle(Theme.Colors.warning)
                            Text("分析失败").font(Theme.Typography.title3)
                            Text(error).font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.secondaryText).multilineTextAlignment(.center)

                            PrimaryButton("重试", icon: "arrow.clockwise") {
                                loadRisks()
                            }
                            // Fallback to local engine
                            PrimaryButton("使用本地规则分析", icon: "bolt.fill", style: .secondary) {
                                fallbackAnalysis()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.xl)
                    } else if aiRisks.isEmpty {
                        emptyState(icon: "checkmark.shield.fill",
                                   title: "未检测到风险",
                                   message: "AI 分析显示当前用药方案暂无已知相互作用风险")
                    } else {
                        Text("AI 动态分析结果 · 豆包大模型")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .padding(.horizontal, Theme.Spacing.md)

                        LazyVStack(spacing: Theme.Spacing.md) {
                            ForEach(aiRisks) { risk in
                                if let level = risk.riskLevel {
                                    InteractionRiskCard(risk: risk, level: level)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)

                        Text("以上分析由 AI 生成，仅供参考。如有疑问请咨询医生或药师。")
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.tertiaryText)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                }
                .padding(.vertical, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("风险")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.Colors.background.opacity(0.9), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                RiskSettingsSheet()
            }
            .task { loadRisks() }
        }
    }

    private func loadRisks() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await DoubaoService.shared.analyzeRisks(medications: medicationStore.medications)
                await MainActor.run {
                    aiRisks = result
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    fallbackAnalysis()
                }
            }
        }
    }

    private func fallbackAnalysis() {
        let localRisks = RiskEngine.shared.evaluate(medications: medicationStore.medications)
        aiRisks = localRisks.map { risk in
            DoubaoService.InteractionRisk(
                id: risk.id,
                level: risk.level.rawValue == "高风险" ? "high" :
                       risk.level.rawValue == "中风险" ? "medium" : "low",
                medications: risk.medications,
                description: risk.description,
                recommendation: risk.recommendation
            )
        }
        isLoading = false
        if aiRisks.isEmpty && localRisks.isEmpty {
            errorMessage = "AI 分析超时，本地规则也未发现风险"
        }
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon).font(.system(size: 48)).foregroundStyle(Theme.Colors.success)
            Text(title).font(Theme.Typography.title3).foregroundStyle(Theme.Colors.primaryText)
            Text(message).font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}

// MARK: - AI Interaction Risk Card

private struct InteractionRiskCard: View {
    let risk: DoubaoService.InteractionRisk
    let level: RiskLevel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: level.icon)
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(level.color)
                Text(level.rawValue)
                    .font(Theme.Typography.headline).foregroundStyle(level.color)
                Spacer()
                Text(risk.medications.joined(separator: " + "))
                    .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.primaryText)
            }

            Text(risk.description)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if !risk.recommendation.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11)).foregroundStyle(Theme.Colors.warning)
                    Text(risk.recommendation)
                        .font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.warning)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(level.bgColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .cardShadow(Theme.Shadow.card)
    }
}

#Preview {
    RiskView().environmentObject(MedicationStore())
}
