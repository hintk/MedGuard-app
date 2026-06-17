import SwiftUI

struct RiskCard: View {
    let risk: RiskInfo
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: risk.level.icon)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(risk.level.color)

                Text(risk.level.rawValue)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(risk.level.color)

                Spacer()

                Text(risk.medications.joined(separator: " + "))
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.primaryText)
            }

            Text(risk.description)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if !risk.recommendation.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Colors.warning)
                    Text(risk.recommendation)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.warning)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(risk.level.bgColor(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .cardShadow(Theme.Shadow.card)
    }
}
