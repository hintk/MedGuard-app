import Foundation

struct Medication: Identifiable {
    let id: String
    var name: String
    var category: String
    var dosage: String
    var time: Date
    var status: MedicationStatus
    var doseAmount: Int
    var doseUnit: MedicationUnit
    var remainingAmount: Int
    var packageCount: Int
    var amountPerPackage: Int
    var source: MedicationSource
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: time)
    }
    
    var inventorySummary: String {
        "当前还剩\(remainingAmount)\(doseUnit.rawValue)｜\(packageCount)盒"
    }
    
    var projectedRunOutDateText: String {
        guard doseAmount > 0 else { return "用量待确认" }
        let daysLeft = max(remainingAmount / doseAmount, 0)
        guard let runOutDate = Calendar.current.date(byAdding: .day, value: daysLeft, to: Date()) else {
            return "预计日期待计算"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return "预计可用到\(formatter.string(from: runOutDate))"
    }
    
    var needsRefill: Bool {
        remainingAmount <= doseAmount * 3
    }
}

struct TimelineRecord: Identifiable {
    let id: String
    let medication: Medication
    let recordDate: Date
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: medication.time)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: recordDate)
    }
}

enum TimelineGroup: String, CaseIterable {
    case today = "今天"
    case yesterday = "昨天"
    case earlier = "过往服药"
}

enum MedicationSource: String {
    case manual = "手动添加"
    case scanned = "扫描添加"
    case preset = "系统导入"
}

enum MedicationUnit: String, CaseIterable, Identifiable {
    case pill = "片"
    case capsule = "粒"
    case sachet = "袋"
    case bottle = "瓶"
    case ml = "毫升"
    
    var id: String { rawValue }
}
