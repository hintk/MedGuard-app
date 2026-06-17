import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var medicationStore: MedicationStore
    @EnvironmentObject private var authStore: AuthStore
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var pendingConfirmation: Medication?
    @State private var showMissedAlert = false
    @State private var missedMedication: Medication?
    @State private var timer: Timer?

    let isHomeTimeline: Bool
    
    init(isHomeTimeline: Bool = false) {
        self.isHomeTimeline = isHomeTimeline
    }
    
    private var groupedRecords: [(TimelineGroup, [TimelineRecord])] {
        let data = PersistenceController.shared.loadTimelineRecords()
        let records = data.map { $0.toTimelineRecord(medications: medicationStore.medications) }
        return MockData.groupRecordsByDate(records)
    }
    
    private var todayMedications: [Medication] {
        medicationStore.medications.sorted { $0.time < $1.time }
    }

    private var pendingMedications: [Medication] {
        todayMedications.filter { $0.status == .pending }
    }

    private var completedMedications: [Medication] {
        todayMedications.filter { $0.status == .taken || $0.status == .skipped }
    }

    private var nextPendingMedication: Medication? {
        pendingMedications.first
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if isHomeTimeline {
                    DateSubtitleView()
                        .padding(.horizontal, Theme.Spacing.md)
                }

                if isHomeTimeline {
                    HomeReminderCard(
                        nextMedication: nextPendingMedication,
                        onConfirm: { medication in
                            Theme.Haptics.success()
                            medicationStore.updateStatus(for: medication.id, to: .taken)
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.md)
                }

                if isHomeTimeline {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader(
                            title: "待确认",
                            subtitle: pendingMedications.isEmpty ? "所有药物已处理" : "\(pendingMedications.count) 项待处理"
                        )
                        .padding(.horizontal, Theme.Spacing.md)

                        if pendingMedications.isEmpty {
                            EmptyPendingView()
                                .padding(.horizontal, Theme.Spacing.md)
                        } else {
                            LazyVStack(spacing: Theme.Spacing.sm) {
                                ForEach(pendingMedications) { medication in
                                    TimelineMedicationCard(
                                        medication: medication,
                                        onConfirmTaken: {
                                            pendingConfirmation = medication
                                        },
                                        onSkip: {
                                            withAnimation(Theme.Animation.spring) {
                                                medicationStore.updateStatus(for: medication.id, to: .skipped)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                }
                    }

                if isHomeTimeline && !completedMedications.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader(
                            title: "已完成",
                            subtitle: "\(completedMedications.count) 项"
                        )
                        .padding(.horizontal, Theme.Spacing.md)

                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(completedMedications) { medication in
                                TimelineMedicationCard(
                                    medication: medication,
                                    onConfirmTaken: {},
                                    onSkip: {}
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    SectionHeader(
                        title: isHomeTimeline ? "服药记录" : "时间线记录",
                        subtitle: isHomeTimeline ? "今天、昨天和更早的完成情况" : "按时间分组查看服药记录"
                    )
                    .padding(.horizontal, Theme.Spacing.md)

                    ForEach(groupedRecords, id: \.0.rawValue) { group, records in
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            Text(group.rawValue)
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.iosGray)
                                .padding(.horizontal, Theme.Spacing.xs)

                            ForEach(records) { record in
                                TimelineRow(record: record, group: group)
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
        .navigationTitle(isHomeTimeline ? "首页" : "时间线")
        .onAppear {
            startMissedCheck()
        }
        .onDisappear {
            stopMissedCheck()
        }
        .sheet(item: $pendingConfirmation) { medication in
            ConfirmTakenSheet(
                medication: medication,
                onConfirm: {
                    confirmPendingMedication()
                },
                onCancel: {
                    pendingConfirmation = nil
                }
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func confirmPendingMedication() {
        guard let pendingConfirmation else { return }
        let med = pendingConfirmation
        withAnimation(Theme.Animation.spring) {
            medicationStore.updateStatus(for: pendingConfirmation.id, to: .taken)
        }
        self.pendingConfirmation = nil
        notifyChildTaken(medication: med)
    }

    private func startMissedCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [self] _ in
            Task { @MainActor in
                self.checkMissedMedications()
            }
        }
        checkMissedMedications()
    }

    private func stopMissedCheck() {
        timer?.invalidate()
        timer = nil
    }

    private func checkMissedMedications() {
        let now = Date()
        for medication in medicationStore.medications {
            if medication.status == .pending {
                let missedTime = medication.time.addingTimeInterval(1800)
                if now > missedTime {
                    notifyChildMissed(medication: medication)
                }
            }
        }
    }

    private func notifyChildTaken(medication: Medication) {
        guard let user = authStore.currentUser, user.role == .elderly, user.isBound,
              let childId = user.boundUserId else { return }
        let title = "✅ 已服药提醒"
        let body = "「\(user.nickname)」已按时服用了「\(medication.name)」"
        notificationManager.sendLocalNotification(
            title: title, body: body, type: .taken,
            medicationName: medication.name, recipientUserId: childId
        )
    }

    func notifyChildMissed(medication: Medication) {
        guard let user = authStore.currentUser, user.role == .elderly, user.isBound,
              let childId = user.boundUserId else { return }
        let title = "⚠️ 漏服提醒"
        let body = "「\(user.nickname)」还没有服用「\(medication.name)」，记得提醒他！"
        notificationManager.sendLocalNotification(
            title: title, body: body, type: .missed,
            medicationName: medication.name, recipientUserId: childId
        )
    }
}

private struct ConfirmTakenSheet: View {
    let medication: Medication
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.success)
            
            VStack(spacing: Theme.Spacing.sm) {
                Text("确认已服药")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("\(medication.name)（\(medication.dosage)）")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: Theme.Spacing.md) {
                Button("取消") {
                    onCancel()
                }
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                
                Button {
                    Theme.Haptics.success()
                    onConfirm()
                } label: {
                    Text("确认服药")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.Colors.success)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
    }
}

private struct DateSubtitleView: View {
    private var dateString: String {
        Theme.DateFormats.monthDayWeekdayString(from: Date())
    }

    var body: some View {
        Text(dateString)
            .font(Theme.Typography.subheadline)
            .foregroundColor(Theme.Colors.iosGray)
    }
}

private struct EmptyPendingView: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.Colors.success)

            Text("今日药物已全部处理完毕")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.iosGray)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
        .cardShadow(Theme.Shadow.subtle)
    }
}

private struct HomeReminderCard: View {
    let nextMedication: Medication?
    let onConfirm: (Medication) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.Colors.healthBlue)
                .frame(width: 6)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("下一次提醒")
                    .font(Theme.Typography.caption1)
                    .foregroundColor(Theme.Colors.iosGray)

                if let nextMedication {
                    HStack(alignment: .bottom, spacing: Theme.Spacing.lg) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(nextMedication.timeString)
                                .font(Theme.Typography.timeDisplay)
                                .foregroundColor(Theme.Colors.primaryText)

                            Text(nextMedication.name)
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                        }

                        Spacer()

                        Button {
                            onConfirm(nextMedication)
                        } label: {
                            Text("确认服用")
                                .font(Theme.Typography.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Theme.Colors.healthBlue)
                                .clipShape(Capsule())
                                .shadow(color: Theme.Colors.healthBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityLabel("确认服用 \(nextMedication.name)")
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.Colors.success)

                            Text("今天的药物都已处理")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                        }

                        Spacer()
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
        .cardShadow(Theme.Shadow.card)
    }
}

private struct TimelineMedicationCard: View {
    let medication: Medication
    let onConfirmTaken: () -> Void
    let onSkip: () -> Void

    @State private var showSkipConfirmation = false

    private var statusBadgeColor: Color {
        switch medication.status {
        case .taken:  return Theme.Colors.success
        case .pending: return Theme.Colors.healthBlue
        case .skipped: return Theme.Colors.iosGray
        }
    }

    private var statusBadgeBackground: Color {
        switch medication.status {
        case .taken:  return Theme.Colors.success.opacity(0.12)
        case .pending: return Theme.Colors.healthBlue.opacity(0.12)
        case .skipped: return Theme.Colors.iosGray.opacity(0.12)
        }
    }

    private var statusLabel: String {
        switch medication.status {
        case .taken:  return "已确认"
        case .pending: return "待确认"
        case .skipped: return "已跳过"
        }
    }

    private var iconBackground: Color {
        switch medication.status {
        case .taken:  return Theme.Colors.success.opacity(0.15)
        case .pending: return Theme.Colors.healthBlue.opacity(0.15)
        case .skipped: return Theme.Colors.iosGray.opacity(0.15)
        }
    }

    private var iconSymbol: String {
        switch medication.status {
        case .taken:  return "checkmark.circle.fill"
        case .pending: return "alarm.fill"
        case .skipped: return "forward.fill"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            // Icon with tinted background
            Image(systemName: iconSymbol)
                .font(.system(size: 22))
                .foregroundStyle(statusBadgeColor)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))

            // Info
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(medication.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)

                Text("\(medication.timeString) · \(medication.dosage)")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)

                // Status capsule tag
                Text(statusLabel)
                    .font(Theme.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(statusBadgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusBadgeBackground)
                    .clipShape(Capsule())
            }

            Spacer()

            // Action buttons
            if medication.status == .pending {
                VStack(spacing: Theme.Spacing.sm) {
                    CompactActionButton(
                        title: "确认",
                        icon: "checkmark",
                        color: .white,
                        bgColor: Theme.Colors.healthBlue
                    ) {
                        onConfirmTaken()
                        Theme.Haptics.success()
                    }
                    .accessibilityLabel("确认服药 \(medication.name)")

                    CompactActionButton(
                        title: "跳过",
                        icon: "forward",
                        color: Theme.Colors.iosGray,
                        bgColor: Theme.Colors.iosGray.opacity(0.12)
                    ) {
                        showSkipConfirmation = true
                    }
                    .accessibilityLabel("跳过服药 \(medication.name)")
                }
            } else {
                Image(systemName: medication.status == .taken ? "checkmark.circle.fill" : "forward.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(medication.status == .taken ? Theme.Colors.success : Theme.Colors.iosGray)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
        .cardShadow(Theme.Shadow.card)
        .accessibilityLabel("\(medication.name), \(medication.timeString), \(medication.dosage), \(statusLabel)")
        .alert("确认跳过", isPresented: $showSkipConfirmation) {
            Button("取消", role: .cancel) {}
            Button("跳过", role: .destructive) {
                onSkip()
                Theme.Haptics.light()
            }
        } message: {
            Text("确定要跳过「\(medication.name)」吗？")
        }
    }
}

private struct CompactActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let bgColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(Theme.Typography.caption1)
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(bgColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct TimelineRow: View {
    let record: TimelineRecord
    let group: TimelineGroup

    private var statusColor: Color {
        switch record.medication.status {
        case .taken:  return Theme.Colors.success
        case .pending: return Theme.Colors.healthBlue
        case .skipped: return Theme.Colors.iosGray
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            // Timeline connector
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Theme.Colors.iosGray.opacity(0.25))
                    .frame(width: 1.5, height: 48)
            }
            .frame(width: 20)

            // Info
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(record.medication.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)

                Text(group == .earlier ? record.dateString : record.timeString)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.secondaryText)
            }

            Spacer()

            // Status pill
            HStack(spacing: 4) {
                Image(systemName: record.medication.status.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(record.medication.status == .taken ? "已确认" : "已跳过")
                    .font(Theme.Typography.caption1)
                    .fontWeight(.medium)
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.10))
            .clipShape(Capsule())
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
        .cardShadow(Theme.Shadow.subtle)
    }
}

#Preview {
    NavigationStack {
        TimelineView(isHomeTimeline: true)
    }
    .environmentObject(MedicationStore())
}
