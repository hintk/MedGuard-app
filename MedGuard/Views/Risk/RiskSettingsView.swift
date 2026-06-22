import SwiftUI

// MARK: - Risk Settings View

/// Settings page that lets users configure the AI model / API.
/// Protected by a PIN-verification gate so only authorized users
/// can change the underlying AI endpoint or key.
struct RiskSettingsView: View {
    @StateObject private var configStore = APIConfigStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var textModel: String = ""
    @State private var visionModel: String = ""
    @State private var baseURL: String = ""

    @State private var showSaveToast = false
    @State private var showResetAlert = false
    @State private var showUnsavedAlert = false

    private var hasChanges: Bool {
        apiKey != configStore.config.apiKey ||
        textModel != configStore.config.textModel ||
        visionModel != configStore.config.visionModel ||
        baseURL != configStore.config.baseURL
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: API Key
                Section {
                    TextField("API Key", text: $apiKey)
                        .font(Theme.Typography.subheadline)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("API 密钥")
                } footer: {
                    Text("用于鉴权的 API Key，请妥善保管。")
                }

                // MARK: Model Endpoints
                Section {
                    TextField("文本模型 ID / Endpoint", text: $textModel)
                        .font(Theme.Typography.subheadline)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("视觉模型 ID / Endpoint", text: $visionModel)
                        .font(Theme.Typography.subheadline)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("模型接入点")
                } footer: {
                    Text("填入对应平台的模型 ID 或推理接入点标识。文本模型用于药物风险分析，视觉模型用于拍照识别药品。")
                }

                // MARK: Base URL
                Section {
                    TextField("API Base URL", text: $baseURL)
                        .font(Theme.Typography.subheadline)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("接口地址")
                } footer: {
                    Text("OpenAI 兼容的 Chat Completions 接口地址。")
                }

                // MARK: Actions
                Section {
                    Button {
                        saveConfig()
                    } label: {
                        HStack {
                            Spacer()
                            Label("保存配置", systemImage: "checkmark.icloud")
                                .font(Theme.Typography.headline)
                            Spacer()
                        }
                    }
                    .disabled(!hasChanges)
                    .listRowBackground(
                        hasChanges ? Theme.Colors.healthBlue.opacity(0.1) : Color.clear
                    )

                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("恢复默认配置", systemImage: "arrow.counterclockwise")
                            Spacer()
                        }
                    }
                }

                // MARK: Current Status
                Section {
                    HStack {
                        Text("配置状态")
                        Spacer()
                        if configStore.isCustom {
                            Label("自定义", systemImage: "gearshape.2.fill")
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.warning)
                        } else {
                            Label("默认", systemImage: "checkmark.shield.fill")
                                .font(Theme.Typography.caption1)
                                .foregroundStyle(Theme.Colors.success)
                        }
                    }
                } header: {
                    Text("状态")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
            .navigationTitle("AI 模型配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if hasChanges { showUnsavedAlert = true }
                        else { dismiss() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            .alert("放弃修改？", isPresented: $showUnsavedAlert) {
                Button("放弃", role: .destructive) { dismiss() }
                Button("继续编辑", role: .cancel) {}
            } message: {
                Text("当前有未保存的修改。")
            }
            .alert("恢复默认配置", isPresented: $showResetAlert) {
                Button("恢复", role: .destructive) {
                    configStore.resetToDefault()
                    loadFromStore()
                    Theme.Haptics.medium()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将清除自定义配置，恢复为豆包默认的 API 设置。")
            }
            .overlay(alignment: .bottom) {
                if showSaveToast {
                    toastBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(Theme.Animation.spring, value: showSaveToast)
            .onAppear { loadFromStore() }
        }
    }

    // MARK: - Helpers

    private func loadFromStore() {
        apiKey = configStore.config.apiKey
        textModel = configStore.config.textModel
        visionModel = configStore.config.visionModel
        baseURL = configStore.config.baseURL
    }

    private func saveConfig() {
        let newConfig = APIConfig(
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            textModel: textModel.trimmingCharacters(in: .whitespacesAndNewlines),
            visionModel: visionModel.trimmingCharacters(in: .whitespacesAndNewlines),
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        configStore.save(newConfig)
        Theme.Haptics.success()
        showSaveToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSaveToast = false
        }
    }

    private var toastBanner: some View {
        Text("配置已保存")
            .font(Theme.Typography.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.success, in: Capsule())
            .padding(.bottom, Theme.Spacing.lg)
    }
}

// MARK: - PIN-Gated Settings Sheet

/// Wraps `RiskSettingsView` behind a PIN-verification gate.
/// - If a PIN is set: verify first, then reveal settings.
/// - If no PIN: show settings directly (shouldn't happen after
///   the registration changes, but handled for safety).
struct RiskSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isVerified = false

    var body: some View {
        Group {
            if isVerified {
                RiskSettingsView()
            } else if PinStore.hasPin {
                PinKeypadView(
                    mode: .verify,
                    prompt: "请输入 6 位数字密码\n以访问 AI 模型配置",
                    onMatch: {
                        isVerified = true
                    },
                    onMismatch: { _ in },
                    onSaved: nil,
                    onDisabled: nil,
                    onCancel: { dismiss() }
                )
            } else {
                RiskSettingsView()
            }
        }
        .interactiveDismissDisabled(!isVerified)
    }
}

#Preview {
    RiskSettingsSheet()
}
