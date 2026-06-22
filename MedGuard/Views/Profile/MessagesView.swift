import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var authStore: AuthStore
    @State private var showClearConfirm = false
    @State private var showEmptyAlert = false

    private var myMessages: [NotificationRecord] {
        guard let userId = authStore.currentUser?.id else { return [] }
        return authStore.notifications(for: userId)
    }

    var body: some View {
        Group {
            if myMessages.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "暂无消息",
                    message: "服药提醒、问候和回复都会显示在这里",
                    style: .info
                )
            } else {
                messageList
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("消息")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    if myMessages.isEmpty {
                        showEmptyAlert = true
                    } else {
                        showClearConfirm = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("清空")
                    }
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(myMessages.isEmpty ? Theme.Colors.tertiaryText : Theme.Colors.danger)
                }
                .disabled(myMessages.isEmpty)
            }
        }
        .alert("确认清空所有消息？", isPresented: $showClearConfirm) {
            Button("清空", role: .destructive) { authStore.clearAllForCurrentUser() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将删除您收件箱中的所有消息和自己发出的回复,此操作不可撤销。")
        }
        .alert("暂无消息可清空", isPresented: $showEmptyAlert) {
            Button("确定", role: .cancel) {}
        }
        .onAppear { markAllVisibleAsRead() }
    }

    // MARK: - List

    private var messageList: some View {
        List {
            ForEach(myMessages) { record in
                MessageRow(
                    record: record,
                    isOutgoing: record.senderUserId == authStore.currentUser?.id,
                    onTap: { authStore.markNotificationRead(record.id) }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        authStore.deleteNotification(id: record.id)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func markAllVisibleAsRead() {
        for record in myMessages where !record.isRead {
            authStore.markNotificationRead(record.id)
        }
    }
}

// MARK: - Row

private struct MessageRow: View {
    let record: NotificationRecord
    let isOutgoing: Bool
    let onTap: () -> Void

    var body: some View {
        Group {
            if record.kind == .reply {
                replyBubble
            } else {
                systemRow
            }
        }
    }

    // 系统消息(服药提醒 / 问候) —— 左对齐,沿用 Profile 风格
    private var systemRow: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                iconBadge
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(record.title)
                            .font(Theme.Typography.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Colors.primaryText)
                        Spacer()
                        if !record.isRead {
                            Circle()
                                .fill(Theme.Colors.danger)
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text(record.body)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Theme.DateFormats.shortDateTimeString(from: record.timestamp))
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(Theme.Colors.tertiaryText)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }

    // 回复消息(老人发出的表情) —— 右对齐气泡
    private var replyBubble: some View {
        HStack(alignment: .bottom) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.replyEmoji?.emoji ?? "💬")
                        .font(.system(size: 22))
                    Text(record.replyEmoji?.displayText ?? record.body)
                        .font(Theme.Typography.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Colors.healthBlue)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large, style: .continuous))

                Text(isOutgoing
                     ? "已发送给子女 · \(Theme.DateFormats.shortDateTimeString(from: record.timestamp))"
                     : Theme.DateFormats.shortDateTimeString(from: record.timestamp))
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.tertiaryText)
            }
        }
    }

    private var iconBadge: some View {
        let (icon, color): (String, Color) = {
            switch record.type {
            case .taken:  return ("checkmark.circle.fill", Theme.Colors.success)
            case .missed: return ("exclamationmark.circle.fill", Theme.Colors.danger)
            case .care:   return ("heart.fill", Theme.Colors.danger)
            case .unwell: return ("exclamationmark.triangle.fill", Theme.Colors.warning)
            case .reply:  return ("bubble.left.fill", Theme.Colors.healthBlue)
            }
        }()
        return ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    NavigationStack {
        MessagesView()
            .environmentObject(AuthStore.shared)
    }
}
