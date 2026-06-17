import SwiftUI

/// Shown after first-time profile setup if user is elderly, to guide binding.
/// Kept for backward compatibility — actual setup is now inline in LoginView.
struct ProfileSetupView: View {
    @EnvironmentObject var authStore: AuthStore

    @State private var nickname = ""
    @State private var selectedRole: UserRole = .elderly
    @State private var showBinding = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.healthBlue.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.Colors.healthBlue)
                    }
                    Text("完善您的资料")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Colors.primaryText)
                }

                VStack(spacing: Theme.Spacing.md) {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.Colors.secondaryText)
                            .frame(width: 24)
                        TextField("昵称", text: $nickname)
                    }
                    .font(Theme.Typography.body)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Theme.Colors.tertiaryBg, lineWidth: 1)
                    )
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("选择角色")
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.primaryText)
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(UserRole.allCases, id: \.self) { role in
                            roleCard(role)
                        }
                    }
                }

                PrimaryButton("完成", icon: "checkmark") {
                    let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    let user = authStore.setupProfile(
                        nickname: trimmed.isEmpty ? "用户" : trimmed,
                        role: selectedRole
                    )
                    if user.role == .elderly {
                        showBinding = true
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("完善资料")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $showBinding) {
            AccountBindingView()
        }
    }

    private func roleCard(_ role: UserRole) -> some View {
        let isSelected = selectedRole == role
        return Button {
            selectedRole = role
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: role.icon)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Theme.Colors.healthBlue : Theme.Colors.secondaryText)
                Text(role.displayName)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.Colors.healthBlue : Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(isSelected ? Theme.Colors.healthBlue.opacity(0.1) : Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Theme.Colors.healthBlue : Theme.Colors.tertiaryBg, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProfileSetupView()
            .environmentObject(AuthStore.shared)
    }
}
