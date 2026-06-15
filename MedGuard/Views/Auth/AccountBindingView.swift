import SwiftUI

struct AccountBindingView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var inviteCode: String = ""
    @State private var childName: String = ""
    @State private var childPhone: String = ""
    @State private var myInviteCode: String = ""
    @State private var errorMessage: String?
    @State private var bindingSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                if authStore.currentUser?.role == .elderly {
                    elderlySection
                } else {
                    childSection
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
        .navigationTitle("账号绑定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = authStore.currentUser {
                myInviteCode = user.inviteCode
                if user.role == .elderly {
                    // Automatically create a binding request when the elderly first visits
                    _ = authStore.sendBindingRequest()
                }
            }
        }
        .alert("绑定成功", isPresented: $bindingSuccess) {
            Button("确定") {}
        } message: {
            Text("与 \(childName) 绑定成功！现在可以互相接收用药提醒通知了。")
        }
        .alert("绑定失败", isPresented: .constant(errorMessage != nil)) {
            Button("确定") { errorMessage = nil }
        } message: {
            if let msg = errorMessage {
                Text(msg)
            }
        }
    }

    // MARK: - Elderly Section

    private var elderlySection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.healthBlue.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Colors.healthBlue)
                }

                Text("分享您的邀请码")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primaryText)

                Text("将邀请码发送给您的子女，让他们来绑定您的账号")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            inviteCodeCard

            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "link.badge.plus")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.success)
                Text("等待子女绑定中...")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
            }
            .padding(.top, Theme.Spacing.lg)
        }
    }

    private var inviteCodeCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("您的邀请码")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)

            Text(myInviteCode)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(Theme.Colors.healthBlue)

            HStack(spacing: Theme.Spacing.md) {
                Button {
                    UIPasteboard.general.string = myInviteCode
                    Theme.Haptics.success()
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                        .font(Theme.Typography.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(Theme.Colors.healthBlue)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .stroke(Theme.Colors.healthBlue.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Child Section

    private var childSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.success.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Colors.success)
                }

                Text("绑定老人账号")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primaryText)

                Text("输入老人分享给您的邀请码，将他们的账号与您绑定")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Theme.Spacing.md) {
                inputField(icon: "number", placeholder: "请输入邀请码", text: $inviteCode)
                Text("或")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.tertiaryText)
                inputField(icon: "person.fill", placeholder: "您的昵称", text: $childName)
                inputField(icon: "phone.fill", placeholder: "您的手机号", text: $childPhone, keyboardType: .phonePad)
            }

            PrimaryButton("确认绑定", icon: "link") {
                performBinding()
            }
            .padding(.top, Theme.Spacing.md)
        }
    }

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.secondaryText)
                .frame(width: 24)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
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

    private func performBinding() {
        do {
            childName = authStore.currentUser?.nickname ?? ""
            try authStore.bindByCode(inviteCode, childName: childName, childPhone: childPhone)
            bindingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        AccountBindingView()
            .environmentObject(AuthStore.shared)
    }
}
