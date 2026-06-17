import SwiftUI

struct AccountBindingView: View {
    @EnvironmentObject var authStore: AuthStore
    @Environment(\.dismiss) private var dismiss

    @State private var inputCode = ""
    @State private var generatedCode: String?
    @State private var timeRemaining: Int = 300
    @State private var errorMessage: String?
    @State private var bindingSuccess = false
    @State private var timer: Timer?

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
        .alert("绑定成功", isPresented: $bindingSuccess) {
            Button("确定") { dismiss() }
        } message: {
            Text("绑定成功！现在可以互相接收用药提醒通知了。")
        }
        .alert("绑定失败", isPresented: .constant(errorMessage != nil)) {
            Button("确定") { errorMessage = nil }
        } message: {
            if let msg = errorMessage { Text(msg) }
        }
        .onDisappear { timer?.invalidate() }
    }

    // MARK: - Elderly

    private var elderlySection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().fill(Theme.Colors.healthBlue.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Colors.healthBlue)
                }

                Text("生成绑定码")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primaryText)

                Text("将 6 位绑定码告诉您的子女，5 分钟内有效")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let code = generatedCode {
                VStack(spacing: Theme.Spacing.md) {
                    Text("绑定码")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)

                    Text(code)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.Colors.healthBlue)
                        .tracking(6)

                    Text("剩余 \(timeString(from: timeRemaining))")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(timeRemaining < 60 ? Theme.Colors.danger : Theme.Colors.secondaryText)

                    Button {
                        UIPasteboard.general.string = code
                        Theme.Haptics.success()
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                            .font(Theme.Typography.subheadline.weight(.medium))
                    }
                    .buttonStyle(.bordered).tint(Theme.Colors.healthBlue)
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(Theme.Colors.healthBlue.opacity(0.3), lineWidth: 2))
            } else {
                PrimaryButton("生成绑定码", icon: "number") {
                    generateCode()
                }
            }
        }
    }

    // MARK: - Child

    private var childSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle().fill(Theme.Colors.success.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.Colors.success)
                }

                Text("绑定老人账号")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primaryText)

                Text("输入老人手机上显示的 6 位绑定码")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "number").foregroundStyle(Theme.Colors.secondaryText).frame(width: 24)
                    TextField("输入 6 位绑定码", text: $inputCode)
                        .keyboardType(.numberPad)
                        .onChange(of: inputCode) { newValue in
                            if newValue.count > 6 { inputCode = String(newValue.prefix(6)) }
                        }
                }
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                .overlay(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.tertiaryBg, lineWidth: 1))

                if let user = authStore.currentUser {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "person.fill").font(.system(size: 14)).foregroundStyle(Theme.Colors.secondaryText)
                        Text("将以「\(user.nickname)」的身份绑定").font(Theme.Typography.caption1).foregroundStyle(Theme.Colors.tertiaryText)
                    }
                }
            }

            PrimaryButton("确认绑定", icon: "link") {
                performBinding()
            }
        }
    }

    // MARK: - Actions

    private func generateCode() {
        let code = authStore.generateBindingCode()
        generatedCode = code.code
        timeRemaining = 300
        Theme.Haptics.success()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let current = authStore.currentBindingCode, current.isValid {
                timeRemaining = Int(current.timeRemaining)
            } else {
                generatedCode = nil
                timeRemaining = 0
                timer?.invalidate()
            }
        }
    }

    private func performBinding() {
        do {
            try authStore.bindWithCode(inputCode)
            bindingSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return "\(m)分\(s)秒"
    }
}

#Preview {
    NavigationStack { AccountBindingView().environmentObject(AuthStore.shared) }
}
