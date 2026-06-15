import Foundation

struct MockData {
    
    static let medications: [Medication] = [
        Medication(
            id: "1",
            name: "阿司匹林",
            category: "心血管",
            dosage: "1片",
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            status: .taken,
            doseAmount: 1,
            doseUnit: .pill,
            remainingAmount: 36,
            packageCount: 3,
            amountPerPackage: 12,
            source: .preset
        ),
        Medication(
            id: "2",
            name: "二甲双胍",
            category: "糖尿病",
            dosage: "2片",
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            status: .taken,
            doseAmount: 2,
            doseUnit: .pill,
            remainingAmount: 48,
            packageCount: 3,
            amountPerPackage: 16,
            source: .preset
        ),
        Medication(
            id: "3",
            name: "缬沙坦",
            category: "高血压",
            dosage: "1片",
            time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
            status: .taken,
            doseAmount: 1,
            doseUnit: .pill,
            remainingAmount: 18,
            packageCount: 2,
            amountPerPackage: 9,
            source: .preset
        ),
        Medication(
            id: "4",
            name: "阿托伐他汀",
            category: "降血脂",
            dosage: "1片",
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!,
            status: .pending,
            doseAmount: 1,
            doseUnit: .pill,
            remainingAmount: 28,
            packageCount: 2,
            amountPerPackage: 14,
            source: .preset
        ),
        Medication(
            id: "5",
            name: "维生素D3",
            category: "营养补充",
            dosage: "1粒",
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!,
            status: .pending,
            doseAmount: 1,
            doseUnit: .capsule,
            remainingAmount: 6,
            packageCount: 3,
            amountPerPackage: 2,
            source: .preset
        ),
        Medication(
            id: "6",
            name: "钙片",
            category: "营养补充",
            dosage: "1片",
            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!,
            status: .pending,
            doseAmount: 1,
            doseUnit: .pill,
            remainingAmount: 24,
            packageCount: 2,
            amountPerPackage: 12,
            source: .preset
        )
    ]
    
    static let riskInfos: [RiskInfo] = [
        RiskInfo(
            id: "1",
            level: .high,
            medications: ["阿司匹林", "华法林"],
            description: "两药联用可能显著增加出血风险，导致凝血功能异常、胃肠道出血等严重不良反应。",
            recommendation: "建议立即咨询医生或药师调整用药方案"
        ),
        RiskInfo(
            id: "2",
            level: .high,
            medications: ["布洛芬", "阿司匹林"],
            description: "布洛芬会竞争性抑制阿司匹林的心血管保护作用，同时增加胃肠道出血风险。",
            recommendation: "两药服用应间隔至少30分钟"
        ),
        RiskInfo(
            id: "3",
            level: .medium,
            medications: ["布洛芬", "ACE抑制剂"],
            description: "NSAIDs类药物可能降低ACE抑制剂降压效果，并影响肾功能。",
            recommendation: "需密切监测血压和肾功能指标"
        ),
        RiskInfo(
            id: "4",
            level: .medium,
            medications: ["二甲双胍", "碘造影剂"],
            description: "使用含碘造影剂进行检查前需停用二甲双胍，以防造影剂肾病。",
            recommendation: "检查前48小时停药，检查后48小时根据肾功能恢复用药"
        ),
        RiskInfo(
            id: "5",
            level: .low,
            medications: ["维生素D3", "钙片"],
            description: "适量补充可增强骨密度，建议随餐服用以提高吸收率。",
            recommendation: "日常保健推荐剂量，无需过度担心"
        ),
        RiskInfo(
            id: "6",
            level: .low,
            medications: ["阿托伐他汀", "葡萄柚汁"],
            description: "葡萄柚汁可能增加他汀类药物的血药浓度，增加肌肉疼痛风险。",
            recommendation: "服用他汀期间建议避免大量饮用葡萄柚汁"
        )
    ]
    
    static func generateTimelineRecords(from medications: [Medication]) -> [TimelineRecord] {
        var records: [TimelineRecord] = []
        
        for med in medications {
            records.append(TimelineRecord(
                id: UUID().uuidString,
                medication: med,
                recordDate: med.time
            ))
        }
        
        let yesterday = Calendar.current.date(byAdding: DateComponents(day: -1), to: Date())!
        records.append(contentsOf: [
            TimelineRecord(
                id: UUID().uuidString,
                medication: Medication(
                    id: "y1",
                    name: "阿司匹林",
                    category: "心血管",
                    dosage: "1片",
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday)!,
                    status: .taken,
                    doseAmount: 1,
                    doseUnit: .pill,
                    remainingAmount: 37,
                    packageCount: 4,
                    amountPerPackage: 10,
                    source: .preset
                ),
                recordDate: Calendar.current.date(bySettingHour: 8, minute: 5, second: 0, of: yesterday)!
            ),
            TimelineRecord(
                id: UUID().uuidString,
                medication: Medication(
                    id: "y2",
                    name: "二甲双胍",
                    category: "糖尿病",
                    dosage: "2片",
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday)!,
                    status: .taken,
                    doseAmount: 2,
                    doseUnit: .pill,
                    remainingAmount: 50,
                    packageCount: 4,
                    amountPerPackage: 13,
                    source: .preset
                ),
                recordDate: Calendar.current.date(bySettingHour: 8, minute: 10, second: 0, of: yesterday)!
            ),
            TimelineRecord(
                id: UUID().uuidString,
                medication: Medication(
                    id: "y3",
                    name: "缬沙坦",
                    category: "高血压",
                    dosage: "1片",
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday)!,
                    status: .taken,
                    doseAmount: 1,
                    doseUnit: .pill,
                    remainingAmount: 19,
                    packageCount: 2,
                    amountPerPackage: 10,
                    source: .preset
                ),
                recordDate: Calendar.current.date(bySettingHour: 8, minute: 8, second: 0, of: yesterday)!
            ),
            TimelineRecord(
                id: UUID().uuidString,
                medication: Medication(
                    id: "y4",
                    name: "阿托伐他汀",
                    category: "降血脂",
                    dosage: "1片",
                    time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: yesterday)!,
                    status: .taken,
                    doseAmount: 1,
                    doseUnit: .pill,
                    remainingAmount: 29,
                    packageCount: 3,
                    amountPerPackage: 10,
                    source: .preset
                ),
                recordDate: Calendar.current.date(bySettingHour: 20, minute: 3, second: 0, of: yesterday)!
            )
        ])
        
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        records.append(contentsOf: [
            TimelineRecord(
                id: UUID().uuidString,
                medication: Medication(
                    id: "e1",
                    name: "阿司匹林",
                    category: "心血管",
                    dosage: "1片",
                    time: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: threeDaysAgo)!,
                    status: .taken,
                    doseAmount: 1,
                    doseUnit: .pill,
                    remainingAmount: 39,
                    packageCount: 4,
                    amountPerPackage: 10,
                    source: .preset
                ),
                recordDate: Calendar.current.date(bySettingHour: 8, minute: 15, second: 0, of: threeDaysAgo)!
            ),
            TimelineRecord(
                id: UUID().uuidString,
                medication: Medication(
                    id: "e2",
                    name: "布洛芬",
                    category: "止痛",
                    dosage: "1片",
                    time: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: threeDaysAgo)!,
                    status: .skipped,
                    doseAmount: 1,
                    doseUnit: .pill,
                    remainingAmount: 8,
                    packageCount: 1,
                    amountPerPackage: 8,
                    source: .preset
                ),
                recordDate: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: threeDaysAgo)!
            )
        ])
        
        return records.sorted { $0.recordDate > $1.recordDate }
    }
    
    static func groupRecordsByDate(_ records: [TimelineRecord]) -> [(TimelineGroup, [TimelineRecord])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(bySetting: .day, value: calendar.component(.day, from: today) - 1, of: today)!
        
        return TimelineGroup.allCases.compactMap { group -> (TimelineGroup, [TimelineRecord])? in
            let filtered: [TimelineRecord]
            
            switch group {
            case .today:
                filtered = records.filter { calendar.isDate($0.recordDate, inSameDayAs: today) }
            case .yesterday:
                filtered = records.filter { calendar.isDate($0.recordDate, inSameDayAs: yesterday) }
            case .earlier:
                filtered = records.filter {
                    !calendar.isDate($0.recordDate, inSameDayAs: today) &&
                    !calendar.isDate($0.recordDate, inSameDayAs: yesterday)
                }
            }
            
            return filtered.isEmpty ? nil : (group, filtered)
        }
    }
}
