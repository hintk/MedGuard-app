import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var nickname = ""
    @State private var selectedRole: UserRole = .elderly
    @State private var showBinding = false
    @State private var showNewUser = false
    @State private var biometricError: String?
    @State private var showBiometricError = false

    private var isFirstLaunch: Bool { !authStore.hasProfile }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    headerSection

                    if isFirstLaunch {
                        setupForm
                    } else {
                        unlockSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.xxl)
            }
            .background(Theme.Colors.background)
            .navigationDestination(isPresented: $showBinding) {
                AccountBindingView()
            }
            .alert("验证失败", isPresented: $showBiometricError) {
                Button("确定") {}
            } message: {
                Text(biometricError ?? "无法验证身份")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.healthBlue.opacity(0.12)).frame(width: 88, height: 88)
                Image(systemName: "pills.fill")
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Colors.healthBlue)
            }
            Text("MedGuard")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primaryText)
            Text("用药安全守护助手")
                .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    // MARK: - Unlock Section

    private var unlockSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Current user card
            if let user = authStore.currentUser ?? authStore.allUsers.first {
                VStack(spacing: Theme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(roleColor(user: user).opacity(0.12)).frame(width: 64, height: 64)
                        Image(systemName: user.role.icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(roleColor(user: user))
                    }
                    Text(user.nickname).font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.primaryText)
                }
            }

            PrimaryButton("面容 ID 解锁", icon: "faceid") { authenticate() }

            // Switch account
            if authStore.allUsers.count > 1 {
                Menu {
                    ForEach(authStore.allUsers) { user in
                        Button {
                            authStore.currentUser = user
                            authenticate()
                        } label: {
                            Label("\(user.nickname)（\(user.role.displayName)）", systemImage: user.role.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.swap")
                        Text("切换账号")
                    }
                    .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.healthBlue)
                }
            }

            // New user
            Button { showNewUser = true } label: {
                Text("创建新账号")
                    .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
            }
            .sheet(isPresented: $showNewUser) {
                NewUserSetupView()
            }
        }
    }

    // MARK: - Setup (first launch)

    private var setupForm: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("首次使用，请设置您的资料").font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.primaryText)

            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.Colors.secondaryText).frame(width: 24)
                    TextField("昵称", text: $nickname)
                }
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium).stroke(Theme.Colors.tertiaryBg, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("选择角色").font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.primaryText)
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        roleCard(role)
                    }
                }
            }

            PrimaryButton("开始使用", icon: "checkmark") {
                let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = trimmed.isEmpty ? "用户" : trimmed
                let user = authStore.setupProfile(nickname: name, role: selectedRole)
                if user.role == .elderly { showBinding = true }
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
            .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(isSelected ? Theme.Colors.healthBlue : Theme.Colors.tertiaryBg, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Biometric

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let err = error {
                biometricError = err.code == LAError.biometryNotEnrolled.rawValue
                    ? "未设置面容 ID，请在系统设置中添加"
                    : err.localizedDescription
            } else {
                biometricError = "生物识别不可用"
            }
            showBiometricError = true
            return
        }

        let reason = context.biometryType == .faceID
            ? "使用面容 ID 解锁 MedGuard" : "使用指纹解锁 MedGuard"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success { authStore.unlock() }
                else if let err = error as? LAError {
                    switch err.code {
                    case .userCancel, .userFallback, .systemCancel: break
                    default:
                        biometricError = err.localizedDescription
                        showBiometricError = true
                    }
                }
            }
        }
    }

    private func roleColor(user: User) -> Color {
        user.role == .elderly ? Theme.Colors.healthBlue : Theme.Colors.success
    }
}

// MARK: - New User Sheet

private struct NewUserSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authStore: AuthStore

    @State private var nickname = ""
    @State private var selectedRole: UserRole = .elderly
    @State private var showBinding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("创建新账号").font(Theme.Typography.title2)
                        .foregroundStyle(Theme.Colors.primaryText)

                    VStack(spacing: Theme.Spacing.md) {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.Colors.secondaryText).frame(width: 24)
                            TextField("昵称", text: $nickname)
                        }
                        .font(Theme.Typography.body)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                        .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium).stroke(Theme.Colors.tertiaryBg, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("选择角色").font(Theme.Typography.subheadline.weight(.semibold))
                        HStack(spacing: Theme.Spacing.md) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                roleCard(role)
                            }
                        }
                    }

                    PrimaryButton("创建并登录", icon: "person.badge.plus") {
                        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                        let name = trimmed.isEmpty ? "用户" : trimmed
                        let user = authStore.setupProfile(nickname: name, role: selectedRole)
                        if user.role == .elderly { showBinding = true }
                        dismiss()
                    }
                }
                .padding(Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("新账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } } }
            .navigationDestination(isPresented: $showBinding) { AccountBindingView() }
        }
    }

    private func roleCard(_ role: UserRole) -> some View {
        let isSelected = selectedRole == role
        return Button {
            selectedRole = role
        } label: {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: role.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.Colors.healthBlue : Theme.Colors.secondaryText)
                Text(role.displayName)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.Colors.healthBlue : Theme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(isSelected ? Theme.Colors.healthBlue.opacity(0.1) : Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(isSelected ? Theme.Colors.healthBlue : Theme.Colors.tertiaryBg, lineWidth: isSelected ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LoginView().environmentObject(AuthStore.shared)
}
