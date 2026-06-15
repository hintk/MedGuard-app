import SwiftUI

struct StatusCard: View {
    let status: SafetyStatus
    let takenCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("今日用药状态")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.secondaryText)

                    Text(status.title)
                        .font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.primaryText)

                    Text(status.message)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "cross.case.fill")
                    .font(.system(size: 28, design: .rounded))
                    .foregroundStyle(status.color)
            }

            HStack {
                Text("已处理 \(takenCount)/\(totalCount)")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
            }

            ProgressView(value: totalCount == 0 ? 0 : Double(takenCount), total: Double(max(totalCount, 1)))
                .tint(status.color)
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.extraLarge))
        .cardShadow(Theme.Shadow.card)
    }
}
