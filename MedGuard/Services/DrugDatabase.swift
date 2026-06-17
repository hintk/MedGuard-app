import Foundation

struct DrugInfo: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let genericName: String
    let category: String
    let specifications: [String]
    let manufacturer: String
    let barcode: String?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        genericName: String = "",
        category: String = "常用药",
        specifications: [String] = ["10mg"],
        manufacturer: String = "",
        barcode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.genericName = genericName.isEmpty ? name : genericName
        self.category = category
        self.specifications = specifications
        self.manufacturer = manufacturer
        self.barcode = barcode
    }
}

final class DrugDatabase {
    static let shared = DrugDatabase()
    
    private var drugs: [DrugInfo] = []
    private var barcodeIndex: [String: DrugInfo] = [:]
    
    private init() {
        loadBuiltInDatabase()
        buildBarcodeIndex()
    }
    
    private func loadBuiltInDatabase() {
        drugs = [
            // 心脑血管类
            DrugInfo(
                name: "阿司匹林肠溶片",
                genericName: "乙酰水杨酸",
                category: "心脑血管",
                specifications: ["25mg", "50mg", "100mg"],
                manufacturer: "拜耳医药"
            ),
            DrugInfo(
                name: "硝苯地平控释片",
                genericName: "硝苯地平",
                category: "心脑血管",
                specifications: ["30mg"],
                manufacturer: "拜耳医药"
            ),
            DrugInfo(
                name: "阿托伐他汀钙片",
                genericName: "阿托伐他汀",
                category: "心脑血管",
                specifications: ["10mg", "20mg", "40mg"],
                manufacturer: "辉瑞"
            ),
            DrugInfo(
                name: "氯吡格雷片",
                genericName: "硫酸氢氯吡格雷",
                category: "心脑血管",
                specifications: ["25mg", "75mg"],
                manufacturer: "赛诺菲"
            ),
            DrugInfo(
                name: "美托洛尔片",
                genericName: "酒石酸美托洛尔",
                category: "心脑血管",
                specifications: ["25mg", "50mg", "100mg"],
                manufacturer: "阿斯利康"
            ),
            DrugInfo(
                name: "缬沙坦胶囊",
                genericName: "缬沙坦",
                category: "心脑血管",
                specifications: ["80mg", "160mg"],
                manufacturer: "诺华"
            ),
            
            // 降糖类
            DrugInfo(
                name: "二甲双胍片",
                genericName: "盐酸二甲双胍",
                category: "降糖药",
                specifications: ["0.25g", "0.5g"],
                manufacturer: "中美施贵宝"
            ),
            DrugInfo(
                name: "格列齐特缓释片",
                genericName: "格列齐特",
                category: "降糖药",
                specifications: ["30mg", "60mg"],
                manufacturer: "施维雅"
            ),
            DrugInfo(
                name: "阿卡波糖片",
                genericName: "阿卡波糖",
                category: "降糖药",
                specifications: ["50mg"],
                manufacturer: "拜耳医药"
            ),
            
            // 消化系统
            DrugInfo(
                name: "奥美拉唑肠溶胶囊",
                genericName: "奥美拉唑",
                category: "消化系统",
                specifications: ["20mg"],
                manufacturer: "阿斯利康"
            ),
            DrugInfo(
                name: "铝碳酸镁片",
                genericName: "铝碳酸镁",
                category: "消化系统",
                specifications: ["0.5g"],
                manufacturer: "拜耳医药"
            ),
            DrugInfo(
                name: "蒙脱石散",
                genericName: "蒙脱石",
                category: "消化系统",
                specifications: ["3g"],
                manufacturer: "博福-益普生"
            ),
            
            // 感冒止咳
            DrugInfo(
                name: "复方氨酚烷胺片",
                genericName: "",
                category: "感冒药",
                specifications: ["12片", "24片"],
                manufacturer: "海南快克"
            ),
            DrugInfo(
                name: "连花清瘟胶囊",
                genericName: "",
                category: "感冒药",
                specifications: ["24粒", "36粒"],
                manufacturer: "以岭药业"
            ),
            DrugInfo(
                name: "急支糖浆",
                genericName: "",
                category: "止咳药",
                specifications: ["100ml", "150ml", "200ml"],
                manufacturer: "太极集团"
            ),
            DrugInfo(
                name: "氨溴索口服溶液",
                genericName: "盐酸氨溴索",
                category: "止咳药",
                specifications: ["100ml"],
                manufacturer: "勃林格殷格翰"
            ),
            
            // 维生素矿物质
            DrugInfo(
                name: "钙尔奇D片",
                genericName: "碳酸钙+维生素D3",
                category: "维生素矿物质",
                specifications: ["600mg×60片"],
                manufacturer: "辉瑞"
            ),
            DrugInfo(
                name: "善存多维元素片",
                genericName: "",
                category: "维生素矿物质",
                specifications: ["30片", "60片", "100片"],
                manufacturer: "辉瑞"
            ),
            DrugInfo(
                name: "复合维生素B片",
                genericName: "",
                category: "维生素矿物质",
                specifications: ["100片"],
                manufacturer: "华中药业"
            ),
            
            // 镇痛消炎
            DrugInfo(
                name: "布洛芬缓释胶囊",
                genericName: "布洛芬",
                category: "镇痛消炎",
                specifications: ["0.3g", "0.4g"],
                manufacturer: "中美史克"
            ),
            DrugInfo(
                name: "对乙酰氨基酚片",
                genericName: "扑热息痛",
                category: "镇痛消炎",
                specifications: ["0.5g"],
                manufacturer: "中美史克"
            ),
            
            // 抗过敏
            DrugInfo(
                name: "氯雷他定片",
                genericName: "氯雷他定",
                category: "抗过敏",
                specifications: ["10mg"],
                manufacturer: "拜耳医药"
            ),
            DrugInfo(
                name: "盐酸西替利嗪片",
                genericName: "盐酸西替利嗪",
                category: "抗过敏",
                specifications: ["10mg"],
                manufacturer: "UCB"
            ),
            
            // 安神助眠
            DrugInfo(
                name: "安神补脑液",
                genericName: "",
                category: "安神助眠",
                specifications: ["10ml×10支", "10ml×20支"],
                manufacturer: "济民可信"
            ),
            DrugInfo(
                name: "褪黑素片",
                genericName: "褪黑素",
                category: "安神助眠",
                specifications: ["3mg"],
                manufacturer: "自然之宝"
            )
        ]
    }
    
    private func buildBarcodeIndex() {
        for drug in drugs {
            if let barcode = drug.barcode {
                barcodeIndex[barcode] = drug
            }
        }
    }
    
    func registerBarcode(_ barcode: String, for drug: DrugInfo) {
        var updatedDrug = drug
        updatedDrug = DrugInfo(
            id: drug.id,
            name: drug.name,
            genericName: drug.genericName,
            category: drug.category,
            specifications: drug.specifications,
            manufacturer: drug.manufacturer,
            barcode: barcode
        )
        barcodeIndex[barcode] = updatedDrug
    }
    
    func lookupByBarcode(_ barcode: String) -> DrugInfo? {
        return barcodeIndex[barcode]
    }
    
    func search(_ query: String) -> [DrugInfo] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        return drugs.filter { drug in
            drug.name.lowercased().contains(lowercasedQuery) ||
            drug.genericName.lowercased().contains(lowercasedQuery) ||
            drug.category.lowercased().contains(lowercasedQuery)
        }
    }
    
    func searchByName(_ name: String) -> [DrugInfo] {
        guard !name.isEmpty else { return [] }
        
        let lowercasedName = name.lowercased()
        return drugs.filter { drug in
            drug.name.lowercased().contains(lowercasedName) ||
            drug.genericName.lowercased().contains(lowercasedName)
        }
    }
    
    var allCategories: [String] {
        Array(Set(drugs.map { $0.category })).sorted()
    }
    
    func drugsByCategory(_ category: String) -> [DrugInfo] {
        drugs.filter { $0.category == category }
    }
}
