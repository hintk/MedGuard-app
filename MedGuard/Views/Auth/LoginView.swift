import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var phone = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    headerSection

                    inputSection

                    loginButton

                    registerLink
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.xxl)
            }
            .background(Theme.Colors.background)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .alert("登录失败", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.healthBlue.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "pills.fill")
                    .font(.system(size: 36, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Colors.healthBlue)
            }

            Text("MedGuard")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primaryText)

            Text("登录您的账号")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private var inputSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            inputField(icon: "phone.fill", placeholder: "手机号", text: $phone, keyboardType: .phonePad)
            inputField(icon: "lock.fill", placeholder: "密码", text: $password, isSecure: true)
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

    private var loginButton: some View {
        PrimaryButton("登录", icon: "arrow.right") {
            performLogin()
        }
        .padding(.top, Theme.Spacing.sm)
    }

    private var registerLink: some View {
        HStack(spacing: 4) {
            Text("还没有账号？")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
            Button("立即注册") {
                showRegister = true
            }
            .font(Theme.Typography.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Colors.healthBlue)
        }
    }

    private func performLogin() {
        do {
            _ = try authStore.login(phone: phone, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthStore.shared)
}
