import SwiftUI

/// Sheet shown from `LoginView` for PIN-based unlock.
///
/// - If a PIN is already set: verifies the typed PIN, then calls `onSuccess`
///   so the caller can flip `isLoggedIn` to true.
/// - If no PIN is set yet: walks the user through setting one (entered
///   twice). The user can cancel and go back to the biometric flow.
struct PinUnlockSheet: View {
    let onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var savedToast: String?

    var body: some View {
        NavigationStack {
            if PinStore.hasPin {
                PinKeypadView(
                    mode: .verify,
                    prompt: "请输入 6 位数字密码",
                    onMatch: {
                        onSuccess()
                        dismiss()
                    },
                    onMismatch: { _ in },
                    onSaved: nil,
                    onDisabled: nil,
                    onCancel: { dismiss() }
                )
                .navigationTitle("数字密码解锁")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                PinKeypadView(
                    mode: .setNew,
                    prompt: "设置 6 位数字密码",
                    onMatch: nil,
                    onMismatch: nil,
                    onSaved: { _ in
                        savedToast = "密码已设置"
                        // Stay on the sheet briefly so the user sees the
                        // success state, then dismiss and unlock.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            onSuccess()
                            dismiss()
                        }
                    },
                    onDisabled: nil,
                    onCancel: { dismiss() }
                )
                .navigationTitle("设置数字密码")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .interactiveDismissDisabled(true)
    }
}
