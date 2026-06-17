import Foundation
import SwiftUI

enum MedicationStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "提醒"
    case taken   = "确认"
    case skipped = "跳过"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .pending: return Theme.Colors.warning
        case .taken:   return Theme.Colors.success
        case .skipped: return Theme.Colors.secondaryText
        }
    }

    var icon: String {
        switch self {
        case .pending: return "alarm.fill"
        case .taken:   return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        }
    }
}

enum SafetyStatus {
    case safe
    case warning
    case danger

    var title: String {
        switch self {
        case .safe:    return "今日状态良好"
        case .warning: return "需要留意"
        case .danger:  return "请尽快处理"
        }
    }

    var message: String {
        switch self {
        case .safe:    return "大部分药物已按时处理"
        case .warning: return "还有部分药物等待处理"
        case .danger:  return "今日待处理药物较多"
        }
    }

    var color: Color {
        switch self {
        case .safe:    return Theme.Colors.success
        case .warning: return Theme.Colors.warning
        case .danger:  return Theme.Colors.danger
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct RiskInfo: Identifiable {
    let id: String
    let level: RiskLevel
    let medications: [String]
    let description: String
    let recommendation: String
}

enum RiskLevel: String, CaseIterable, Identifiable {
    case high   = "高风险"
    case medium = "中风险"
    case low    = "低风险"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .high:   return Theme.Colors.highRisk
        case .medium: return Theme.Colors.mediumRisk
        case .low:    return Theme.Colors.lowRisk
        }
    }

    func bgColor(for colorScheme: ColorScheme) -> Color {
        Theme.adaptiveRiskBackground(for: colorScheme, risk: self)
    }

    var icon: String {
        switch self {
        case .high:   return "exclamationmark.shield.fill"
        case .medium: return "bolt.fill"
        case .low:    return "checkmark.shield.fill"
        }
    }
}
