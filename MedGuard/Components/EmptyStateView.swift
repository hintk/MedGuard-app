import SwiftUI

struct EmptyStateView: View {
    enum Style {
        case success
        case info
        case warning
    }

    let icon: String
    let title: String
    let message: String
    let style: Style

    init(icon: String, title: String, message: String, style: Style = .info) {
        self.icon = icon
        self.title = title
        self.message = message
        self.style = style
    }

    private var foregroundColor: Color {
        switch style {
        case .success: return Theme.Colors.success
        case .info: return Theme.Colors.iosGray
        case .warning: return Theme.Colors.warning
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(foregroundColor)

            Text(title)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.primaryText)

            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xl)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Theme.Colors.success)

            Text(title)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.iosGray)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
        .cardShadow(Theme.Shadow.subtle)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "checkmark.shield.fill",
            title: "未检测到风险",
            message: "当前药品档案中的药物暂未发现已知的相互作用风险",
            style: .success
        )

        EmptyStateCard(
            icon: "checkmark.circle.fill",
            title: "今日药物已全部处理完毕"
        )
    }
    .padding()
}
