import Foundation

/// Dynamically computes drug interaction risks from the user's actual medication list.
/// Uses category-based and name-based interaction rules.
final class RiskEngine {
    static let shared = RiskEngine()

    private init() {}

    // MARK: - Interaction Rules

    private struct Rule {
        enum Target {
            case name(String)
            case category(String)
        }

        let drugA: Target
        let drugB: Target
        let level: RiskLevel
        let description: String
        let recommendation: String
    }

    private let rules: [Rule] = [
        // ── High Risk ──────────────────────────────────
        Rule(
            drugA: .name("阿司匹林"), drugB: .name("布洛芬"),
            level: .high,
            description: "布洛芬会竞争性抑制阿司匹林的心血管保护作用，同时显著增加胃肠道出血风险。",
            recommendation: "两药服用应间隔至少30分钟，建议咨询医生调整用药方案"
        ),
        Rule(
            drugA: .name("阿司匹林"), drugB: .name("华法林"),
            level: .high,
            description: "两药联用可能显著增加出血风险，导致凝血功能异常、胃肠道出血等严重不良反应。",
            recommendation: "建议立即咨询医生或药师，必要时调整抗凝方案"
        ),
        Rule(
            drugA: .category("心脑血管"), drugB: .category("镇痛消炎"),
            level: .high,
            description: "NSAIDs类镇痛药可能削弱降压药和抗血小板药的疗效，并增加心血管事件和肾损伤风险。",
            recommendation: "如需止痛，建议在医生指导下选择对心血管影响较小的药物"
        ),
        Rule(
            drugA: .category("镇痛消炎"), drugB: .category("镇痛消炎"),
            level: .high,
            description: "同时使用两种及以上NSAIDs镇痛药，消化道出血和肾损伤风险大幅上升。",
            recommendation: "请避免叠加使用多种止痛药，单一药物足量即可"
        ),

        // ── Medium Risk ────────────────────────────────
        Rule(
            drugA: .category("降糖药"), drugB: .category("镇痛消炎"),
            level: .medium,
            description: "NSAIDs类药物可能影响肾功能，糖尿病患者使用不当可能加重肾负担。",
            recommendation: "需监测肾功能指标，必要时调整降糖或镇痛方案"
        ),
        Rule(
            drugA: .category("心脑血管"), drugB: .category("抗生素"),
            level: .medium,
            description: "部分抗生素（如氟喹诺酮类）可能影响血压和心率，与心血管药物联用需留意。",
            recommendation: "服药期间密切监测血压和心率变化"
        ),
        Rule(
            drugA: .category("安神助眠"), drugB: .category("抗过敏"),
            level: .medium,
            description: "镇静催眠药与第一代抗组胺药同服可能加重嗜睡、注意力下降等中枢抑制作用。",
            recommendation: "服药后避免驾车和高危活动，建议错开服用时间"
        ),
        Rule(
            drugA: .category("降糖药"), drugB: .category("心脑血管"),
            level: .medium,
            description: "部分降压药（如噻嗪类利尿剂）可能影响血糖水平，需注意血糖波动。",
            recommendation: "建议定期监测血糖，与医生确认是否需要调整降糖方案"
        ),
        Rule(
            drugA: .category("心脑血管"), drugB: .category("感冒药"),
            level: .medium,
            description: "复方感冒药中常含伪麻黄碱等成分，可能升高血压、增加心率。",
            recommendation: "高血压患者应选择不含伪麻黄碱的感冒药，服药期间监测血压"
        ),

        // ── Low Risk (Informational) ───────────────────
        Rule(
            drugA: .name("维生素D3"), drugB: .name("钙片"),
            level: .low,
            description: "维生素D3有助于钙吸收，适量补充可增强骨密度。",
            recommendation: "建议随餐服用以提高吸收率，按推荐剂量服用即可"
        ),
        Rule(
            drugA: .category("维生素矿物质"), drugB: .category("维生素矿物质"),
            level: .low,
            description: "多种维生素/矿物质联用一般安全，但应避免重复补充同一种成分导致过量。",
            recommendation: "注意检查各产品成分表，防止某种维生素或矿物质超量"
        ),
        Rule(
            drugA: .category("心脑血管"), drugB: .name("阿托伐他汀"),
            level: .low,
            description: "服用他汀类药物期间大量饮用葡萄柚汁可能增加血药浓度，增加肌肉疼痛风险。",
            recommendation: "服药期间建议避免大量饮用葡萄柚汁"
        )
    ]

    // MARK: - Evaluation

    /// Given the user's current medications, return a list of applicable risks.
    func evaluate(medications: [Medication]) -> [RiskInfo] {
        guard medications.count >= 2 else { return [] }

        // Skip medications with empty names (not yet filled in)
        let active = medications.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard active.count >= 2 else { return [] }

        var results: [RiskInfo] = []

        for i in 0..<(active.count - 1) {
            for j in (i + 1)..<active.count {
                let medA = active[i]
                let medB = active[j]

                for rule in rules {
                    guard matches(medication: medA, target: rule.drugA),
                          matches(medication: medB, target: rule.drugB) else { continue }

                    // Avoid duplicate risks for the same drug pair
                    let pairKey = Set([medA.id, medB.id, rule.description])
                    let isDuplicate = results.contains { existing in
                        Set([existing.id]) == pairKey
                    }
                    guard !isDuplicate else { continue }

                    results.append(RiskInfo(
                        id: UUID().uuidString,
                        level: rule.level,
                        medications: [medA.name, medB.name],
                        description: rule.description,
                        recommendation: rule.recommendation
                    ))
                }
            }
        }

        // Sort: high → medium → low
        results.sort { a, b in
            let order: [RiskLevel] = [.high, .medium, .low]
            return (order.firstIndex(of: a.level) ?? 99) < (order.firstIndex(of: b.level) ?? 99)
        }

        return results
    }

    private func matches(medication: Medication, target: Rule.Target) -> Bool {
        switch target {
        case .name(let name):
            return medication.name.localizedCaseInsensitiveContains(name)
        case .category(let category):
            return medication.category == category
        }
    }
}
