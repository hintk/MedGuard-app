import SwiftUI

struct MedicationCard: View {
    let medication: Medication
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(Theme.Colors.healthBlue.opacity(0.14))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "pills.fill")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Colors.healthBlue)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primaryText)
                    
                    Text("\(medication.category)  \(medication.dosage)  \(medication.timeString)")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                        Text(medication.inventorySummary)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundStyle(medication.needsRefill ? Theme.Colors.danger : Theme.Colors.tertiaryText)
                        Text(medication.projectedRunOutDateText)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(medication.needsRefill ? Theme.Colors.danger : Theme.Colors.tertiaryText)
                    }
                }
                
                Spacer()
                
                HStack(spacing: Theme.Spacing.sm) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.Colors.healthBlue)
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .cardShadow(Theme.Shadow.card)
    }
}
