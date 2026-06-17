import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var medicationStore: MedicationStore
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showBindingSheet = false
    @State private var showUnbindAlert = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showExportSheet = false
    @State private var exportData: URL?
    @State private var exportFileName: String = ""
    @State private var showExportError = false
    @State private var exportErrorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    profileHeader
                    if let user = authStore.currentUser {
                        userInfoCard(user: user)
                        if user.role == .elderly {
                            boundChildCard(user: user)
                            notificationSettingsCard
                        } else {
                            boundElderlyCard(user: user)
                        }
                    notificationRecordsSection
                    dataManagementSection
                    dangerZone
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showBindingSheet) {
                AccountBindingView()
            }
            .alert("确认解除绑定？", isPresented: $showUnbindAlert) {
                Button("解除绑定", role: .destructive) { authStore.unbind() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("解除绑定后，双方将不再收到用药提醒通知。")
            }
            .alert("确认退出登录？", isPresented: $showLogoutAlert) {
                Button("退出登录", role: .destructive) { authStore.logout() }
                Button("取消", role: .cancel) {}
            }
            .alert("确认删除账号？", isPresented: $showDeleteAccountAlert) {
                Button("删除账号", role: .destructive) { authStore.deleteAccount() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后所有数据将被清除，且无法恢复。")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportData { ShareSheet(activityItems: [url]) }
            }
            .alert("导出失败", isPresented: $showExportError) {
                Button("确定", role: .cancel) {}
            } message: { Text(exportErrorMessage) }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: authStore.currentUser?.role.icon ?? "person.fill")
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundStyle(roleColor)
            }

            VStack(spacing: 2) {
                Text(authStore.currentUser?.nickname ?? "")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Colors.primaryText)
                Text(authStore.currentUser?.role.displayName ?? "")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(roleColor)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, 2)
                    .background(roleColor.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.bottom, Theme.Spacing.sm)
    }

    private var roleColor: Color {
        authStore.currentUser?.role == .elderly ? Theme.Colors.healthBlue : Theme.Colors.success
    }

    // MARK: - User Info Card

    private func userInfoCard(user: User) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "person.fill").font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.secondaryText).frame(width: 24)
                Text("昵称").font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
                Spacer()
                Text(user.nickname).font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.primaryText)
            }
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.md)
            Divider().padding(.leading, 44)
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "person.circle.fill").font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.Colors.secondaryText).frame(width: 24)
                Text("角色").font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
                Spacer()
                Text(user.role.displayName).font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.primaryText)
            }
            .padding(.horizontal, Theme.Spacing.md).padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Bound Child Card (Elderly View)

    private func boundChildCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(Theme.Colors.success)
                Text("已绑定的子女")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
            }

            if user.isBound {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.success.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.Colors.success)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.boundUserName ?? "子女")
                            .font(Theme.Typography.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.primaryText)
                    }
                    Spacer()
                }
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.success)
                    Text("已绑定 — 子女会收到您的用药提醒")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.success)
                }
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    Text("尚未绑定子女账号")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    PrimaryButton("去绑定", icon: "link") { showBindingSheet = true }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Bound Elderly Card (Child View)

    private func boundElderlyCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(Theme.Colors.healthBlue)
                Text("监护的老人")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
            }

            if user.isBound {
                HStack(spacing: Theme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.healthBlue.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.Colors.healthBlue)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.boundUserName ?? "老人")
                            .font(Theme.Typography.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.primaryText)
                    }
                    Spacer()
                    Button { sendCare() } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.Colors.danger)
                            Text("问候")
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(Theme.Colors.danger)
                        }
                    }
                }
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    Text("尚未绑定老人账号")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    PrimaryButton("去绑定", icon: "link") { showBindingSheet = true }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Notification Settings

    private var notificationSettingsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundStyle(Theme.Colors.warning)
                Text("通知设置")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
            }

            if !notificationManager.isAuthorized {
                Button {
                    Task { await notificationManager.requestAuthorization() }
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.Colors.warning)
                        Text("点击开启通知权限")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.warning)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.success)
                    Text("通知权限已开启")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.success)
                    Spacer()
                }
            }

            Text("开启后，子女将收到您服药或漏服的提醒通知")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    // MARK: - Notification Records

    private var myNotifications: [NotificationRecord] {
        authStore.notifications(for: authStore.currentUser?.id ?? "")
    }

    private var notificationRecordsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("用药提醒记录")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.primaryText)
                Spacer()
                if authStore.unreadCount > 0 {
                    Text("\(authStore.unreadCount) 条未读")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.Colors.danger)
                        .clipShape(Capsule())
                }
                if myNotifications.count > 5 {
                    Button("查看全部") {
                        // Could navigate to full list view
                    }
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Colors.healthBlue)
                }
            }

            if myNotifications.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.tertiaryText)
                        Text("暂无提醒记录")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    .padding(.vertical, Theme.Spacing.lg)
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(myNotifications.prefix(5)) { record in
                        notificationRecordRow(record)
                        if record.id != myNotifications.prefix(5).last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
        }
    }

    private func notificationRecordRow(_ record: NotificationRecord) -> some View {
        Button {
            authStore.markNotificationRead(record.id)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Circle()
                    .fill(record.type == .taken
                          ? Theme.Colors.success.opacity(0.12)
                          : Theme.Colors.danger.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: record.type == .taken
                              ? "checkmark.circle.fill"
                              : "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(record.type == .taken
                                             ? Theme.Colors.success
                                             : Theme.Colors.danger)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.title)
                        .font(Theme.Typography.subheadline.weight(.medium))
                        .foregroundStyle(record.isRead ? Theme.Colors.secondaryText : Theme.Colors.primaryText)
                    Text(record.body)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    Text(formatDate(record.timestamp))
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                }

                Spacer()

                if !record.isRead {
                    Circle().fill(Theme.Colors.danger).frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("数据管理")
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Colors.primaryText)

            VStack(spacing: 0) {
                Button { performExport(format: .json) } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Theme.Colors.healthBlue)
                        Text("导出为 JSON")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.primaryText)
                        Spacer()
                        Text("\(medicationStore.medications.count) 条记录")
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.md)
                }

                Divider().padding(.leading, 44)

                Button { performExport(format: .csv) } label: {
                    HStack {
                        Image(systemName: "tablecells")
                            .foregroundStyle(Theme.Colors.healthBlue)
                        Text("导出为 CSV")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.primaryText)
                        Spacer()
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
    }

    private func performExport(format: DataExporter.ExportFormat) {
        do {
            let data = try DataExporter.shared.exportMedications(medicationStore.medications, format: format)
            if let fileURL = DataExporter.shared.createShareableFile(data: data, format: format) {
                exportData = fileURL
                exportFileName = fileURL.lastPathComponent
                showExportSheet = true
            }
        } catch {
            exportErrorMessage = error.localizedDescription
            showExportError = true
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if authStore.currentUser?.isBound == true {
                Button { showUnbindAlert = true } label: {
                    HStack {
                        Image(systemName: "link.badge.minus")
                        Text("解除绑定")
                    }
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md)
                    .background(Theme.Colors.danger.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                }
            }

            Button { showLogoutAlert = true } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("退出登录")
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }

            Button { showDeleteAccountAlert = true } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("删除账号")
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Care

    @State private var careSent = false

    private func sendCare() {
        let title = "❤️ 子女问候"
        let body = "「\(authStore.currentUser?.nickname ?? "")」向您问好，记得按时吃药哦！"
        guard let elderlyId = authStore.currentUser?.boundUserId else { return }
        notificationManager.sendLocalNotification(
            title: title, body: body, type: .care,
            medicationName: nil, recipientUserId: elderlyId
        )
        careSent = true
        Theme.Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { careSent = false }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        Theme.DateFormats.shortDateTimeString(from: date)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthStore.shared)
        .environmentObject(MedicationStore())
}
