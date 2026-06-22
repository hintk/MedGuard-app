import SwiftUI

/// Reusable 6-digit PIN entry view.
///
/// - `verify` mode: the user types their current PIN; we call `onMatch` /
///   `onMismatch`. The view itself does not unlock the app — the caller
///   decides what a successful match does (call `authStore.unlock()` etc.).
/// - `setNew` mode: the user enters a new PIN twice for confirmation. On
///   success the saved PIN is reported via `onSaved`.
/// - `change` mode: the user must first confirm the current PIN, then is
///   walked through `setNew` for the new one.
/// - `disable` mode: the user must confirm the current PIN; on success the
///   caller should call `PinStore.clear()`.
struct PinKeypadView: View {
    enum Mode { case verify, setNew, change, disable }
    enum Step { case enter, confirm }

    let mode: Mode
    let prompt: String
    let onMatch: (() -> Void)?
    let onMismatch: ((Int) -> Void)?   // receives the # of failed attempts
    let onSaved: ((String) -> Void)?
    let onDisabled: (() -> Void)?
    let onCancel: () -> Void

    @State private var step: Step = .enter
    @State private var entered: String = ""
    @State private var firstDraft: String = ""
    @State private var mismatches: Int = 0
    @State private var errorMessage: String?
    @State private var showError: Bool = false

    private let pinLength = 6

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            header

            DotsRow(filled: entered.count, total: pinLength, hasError: showError)

            if let msg = errorMessage {
                Text(msg)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.danger)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            Keypad { digit in
                handleDigit(digit)
            } onBackspace: {
                guard !isProcessing else { return }
                if !entered.isEmpty { entered.removeLast() }
                errorMessage = nil
                showError = false
            }

            Button("取消", role: .cancel) { onCancel() }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
                .padding(.top, Theme.Spacing.xs)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .background(Theme.Colors.background)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Theme.Colors.healthBlue)
                .padding(.top, Theme.Spacing.lg)
            Text(prompt)
                .font(Theme.Typography.title3.weight(.semibold))
                .foregroundStyle(Theme.Colors.primaryText)
                .multilineTextAlignment(.center)
        }
    }

    @State private var isProcessing = false

    // MARK: - Input handling

    private func handleDigit(_ digit: String) {
        guard entered.count < pinLength, !isProcessing else { return }
        entered.append(digit)
        errorMessage = nil
        showError = false
        if entered.count == pinLength {
            isProcessing = true
            // 短暂延迟，让用户看到最后一颗圆点变蓝
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                submit()
            }
        }
    }

    private func submit() {
        defer { isProcessing = false }
        switch (mode, step) {
        case (.verify, .enter):
            verifyCurrentPin()
        case (.setNew, .enter):
            step = .confirm
            firstDraft = entered
            entered = ""
        case (.setNew, .confirm):
            confirmSetNew()
        case (.change, .enter):
            verifyCurrentPin()
        case (.disable, .enter):
            verifyCurrentPin()
        default:
            break
        }
    }

    private func verifyCurrentPin() {
        if PinStore.verify(entered) {
            switch mode {
            case .verify, .change:
                onMatch?()
            case .disable:
                onDisabled?()
            default:
                break
            }
        } else {
            mismatches += 1
            entered = ""
            errorMessage = "密码错误,请重试"
            showError = true
            onMismatch?(mismatches)
        }
    }

    private func confirmSetNew() {
        if entered == firstDraft {
            do {
                try PinStore.setPin(entered)
                onSaved?(entered)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                entered = ""
            }
        } else {
            entered = ""
            firstDraft = ""
            step = .enter
            errorMessage = "两次输入不一致,请重新设置"
            showError = true
        }
    }
}

// MARK: - Dots row

private struct DotsRow: View {
    let filled: Int
    let total: Int
    let hasError: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .strokeBorder(filled > i
                                  ? (hasError ? Theme.Colors.danger : Theme.Colors.healthBlue)
                                  : Theme.Colors.tertiaryBg,
                                  lineWidth: 2)
                    .background(Circle().fill(filled > i
                                              ? (hasError ? Theme.Colors.danger.opacity(0.18) : Theme.Colors.healthBlue.opacity(0.18))
                                              : Color.clear))
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Keypad

private struct Keypad: View {
    let onDigit: (String) -> Void
    let onBackspace: () -> Void

    private let rows: [[String]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
        ["",  "0", "<"]
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<rows.count, id: \.self) { r in
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(0..<rows[r].count, id: \.self) { c in
                        key(rows[r][c])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func key(_ label: String) -> some View {
        if label.isEmpty {
            Color.clear.frame(maxWidth: .infinity).frame(height: 64)
        } else if label == "<" {
            Button(action: onBackspace) {
                Image(systemName: "delete.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.Colors.primaryText)
                    .frame(maxWidth: .infinity).frame(height: 64)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            }
            .buttonStyle(.plain)
        } else {
            Button {
                onDigit(label)
            } label: {
                Text(label)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.Colors.primaryText)
                    .frame(maxWidth: .infinity).frame(height: 64)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            }
            .buttonStyle(.plain)
        }
    }
}
