import Foundation

struct Medication: Identifiable, Codable {
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
        Theme.DateFormats.timeString(from: time)
    }
    
    var dateString: String {
        Theme.DateFormats.shortDateString(from: time)
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
        return "预计可用到\(Theme.DateFormats.monthDayString(from: runOutDate))"
    }
    
    var needsRefill: Bool {
        remainingAmount <= doseAmount * 3
    }
}

struct TimelineRecord: Identifiable, Codable {
    let id: String
    let medication: Medication
    let recordDate: Date
    
    var timeString: String {
        Theme.DateFormats.timeString(from: medication.time)
    }
    
    var dateString: String {
        Theme.DateFormats.shortDateTimeString(from: recordDate)
    }
}

enum TimelineGroup: String, CaseIterable {
    case today = "今天"
    case yesterday = "昨天"
    case earlier = "过往服药"
}

enum MedicationSource: String, Codable {
    case manual = "手动添加"
    case scanned = "扫描添加"
    case preset = "系统导入"
}

enum MedicationUnit: String, CaseIterable, Identifiable, Codable {
    case pill = "片"
    case capsule = "粒"
    case sachet = "袋"
    case bottle = "瓶"
    case ml = "毫升"
    
    var id: String { rawValue }
}
