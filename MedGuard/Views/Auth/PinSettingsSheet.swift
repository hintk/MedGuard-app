import SwiftUI

/// Sheet shown from `ProfileView > 安全` for managing the device PIN.
///
/// - `setNew`:  set a PIN for the first time.
/// - `change`:  verify the current PIN, then set a new one.
/// - `disable`: verify the current PIN, then clear it.
///
/// `onFinished` is called with a short Chinese status string that the
/// caller can surface to the user (alert, toast, etc.).
struct PinSettingsSheet: View {
    let initialMode: PinKeypadView.Mode
    let title: String
    let onFinished: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var stage: Stage

    init(initialMode: PinKeypadView.Mode,
         title: String,
         onFinished: @escaping (String) -> Void) {
        self.initialMode = initialMode
        self.title = title
        self.onFinished = onFinished
        // `change` starts with verifying the old PIN, then transitions.
        _stage = State(initialValue: initialMode == .change ? .verifyOld : .entry)
    }

    private enum Stage { case entry, verifyOld, setNew, disable }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("关闭") { dismiss() }
                    }
                }
        }
        .interactiveDismissDisabled(true)
    }

    @ViewBuilder
    private var content: some View {
        switch (initialMode, stage) {
        case (.setNew, _):
            PinKeypadView(
                mode: .setNew,
                prompt: "设置 6 位数字密码",
                onMatch: nil,
                onMismatch: nil,
                onSaved: { _ in
                    onFinished("密码已设置")
                    dismiss()
                },
                onDisabled: nil,
                onCancel: { dismiss() }
            )

        case (.change, .verifyOld):
            PinKeypadView(
                mode: .verify,
                prompt: "请输入当前 6 位数字密码",
                onMatch: { stage = .setNew },
                onMismatch: { _ in },
                onSaved: nil,
                onDisabled: nil,
                onCancel: { dismiss() }
            )

        case (.change, .setNew):
            PinKeypadView(
                mode: .setNew,
                prompt: "设置新的 6 位数字密码",
                onMatch: nil,
                onMismatch: nil,
                onSaved: { _ in
                    onFinished("密码已更新")
                    dismiss()
                },
                onDisabled: nil,
                onCancel: { dismiss() }
            )

        case (.disable, _):
            PinKeypadView(
                mode: .disable,
                prompt: "请输入当前 6 位数字密码以关闭",
                onMatch: nil,
                onMismatch: { _ in },
                onSaved: nil,
                onDisabled: {
                    PinStore.clear()
                    onFinished("已关闭 6 位数字密码")
                    dismiss()
                },
                onCancel: { dismiss() }
            )

        default:
            PinKeypadView(
                mode: initialMode,
                prompt: "设置 6 位数字密码",
                onMatch: nil,
                onMismatch: nil,
                onSaved: { _ in
                    onFinished("密码已设置")
                    dismiss()
                },
                onDisabled: nil,
                onCancel: { dismiss() }
            )
        }
    }
}
