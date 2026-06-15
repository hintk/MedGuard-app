import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.title3)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(subtitle)
                .font(Theme.Typography.caption1)
                .foregroundColor(Theme.Colors.secondaryText)
        }
    }
}
