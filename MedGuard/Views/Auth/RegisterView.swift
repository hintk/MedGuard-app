import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = ""
    @State private var selectedRole: UserRole = .elderly
    @State private var showBinding = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                headerSection
                inputSection
                roleSelectionSection
                registerButton
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("注册")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showBinding) {
            AccountBindingView()
        }
        .alert("注册失败", isPresented: .constant(errorMessage != nil)) {
            Button("确定") { errorMessage = nil }
        } message: {
            if let msg = errorMessage {
                Text(msg)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("创建账号")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primaryText)
            Text("填写以下信息完成注册")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private var inputSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            inputField(icon: "person.fill", placeholder: "昵称", text: $nickname)
            inputField(icon: "phone.fill", placeholder: "手机号", text: $phone, keyboardType: .phonePad)
            inputField(icon: "lock.fill", placeholder: "密码（至少6位）", text: $password, isSecure: true)
            inputField(icon: "lock.fill", placeholder: "确认密码", text: $confirmPassword, isSecure: true)
        }
    }

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.secondaryText)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .textContentType(keyboardType == .phonePad ? .telephoneNumber : .none)
            }
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

    private var roleSelectionSection: some View {
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

    private var registerButton: some View {
        PrimaryButton("注册", icon: "person.badge.plus") {
            performRegister()
        }
    }

    private func performRegister() {
        guard password == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            return
        }
        do {
            _ = try authStore.register(phone: phone, password: password, nickname: nickname, role: selectedRole)
            if selectedRole == .elderly {
                showBinding = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthStore.shared)
    }
}
