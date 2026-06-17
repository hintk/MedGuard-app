import Foundation

// MARK: - Baidu API Barcode Response

struct BaiduBarcodeResponse: Codable {
    let code: String?
    let message: String?
    let data: BaiduBarcodeData?
}

struct BaiduBarcodeData: Codable {
    let name: String?          // 药品名称
    let spec: String?          // 规格
    let manuName: String?      // 生产厂家
    let approval: String?      // 批准文号
    let dosage: String?        // 用法用量
    let purpose: String?       // 功能主治
    let basis: String?         // 主要成分
    let taboo: String?         // 禁忌
    let character: String?     // 性状
    let consideration: String? // 注意事项
    let validity: String?      // 有效期
    let img: String?           // 图片URL
}

// MARK: - Drug Lookup Service

final class DrugLookupService {
    static let shared = DrugLookupService()

    // MARK: - API Configuration
    // 百度API市场 — 药品条码查询（贵州诚数科技）
    // 订购页面: https://apis.baidu.com/store/detail/062791cf-4629-45b3-aaf0-2c86a701a33c
    private struct APIConfig {
        static let appId = "7854789"
        static let apiKey = "VZUvnMCRo4QugP1skMpkdQHM"
        static let secretKey = "GistA5QLWfhhBH0xEFgMGTDqHyKl5Yvm"
        static let baseURL = "https://yptxmcx.api.bdymkt.com/brugs_code/query"
    }

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        self.session = URLSession(configuration: config)
    }

    enum LookupError: LocalizedError {
        case invalidBarcode
        case networkError(Error)
        case parsingError
        case notFound
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidBarcode:
                return "无效的条形码格式"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .parsingError:
                return "数据解析失败"
            case .notFound:
                return "未找到该药品信息"
            case .apiError(let message):
                return "API 错误: \(message)"
            }
        }
    }

    struct LookupResult {
        let name: String
        let category: String
        let manufacturer: String
        let specification: String
        let approvalNumber: String
        let dosage: String
        let purpose: String
        let taboo: String
        let imageURL: String?

        func toDrugInfo() -> DrugInfo {
            DrugInfo(
                name: name,
                genericName: "",
                category: category,
                specifications: [specification],
                manufacturer: manufacturer
            )
        }
    }

    func lookupDrug(barcode: String) async throws -> LookupResult {
        guard !barcode.isEmpty else {
            throw LookupError.invalidBarcode
        }

        // Check local database first
        if let localDrug = DrugDatabase.shared.lookupByBarcode(barcode) {
            return LookupResult(
                name: localDrug.name,
                category: localDrug.category,
                manufacturer: localDrug.manufacturer,
                specification: localDrug.specifications.first ?? "",
                approvalNumber: "",
                dosage: "",
                purpose: "",
                taboo: "",
                imageURL: nil
            )
        }

        // Query Baidu API
        guard var urlComponents = URLComponents(string: APIConfig.baseURL) else {
            throw LookupError.invalidBarcode
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "code", value: barcode)
        ]

        guard let url = urlComponents.url else {
            throw LookupError.invalidBarcode
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.httpMethod = "GET"
            request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.setValue("AppCode/\(APIConfig.apiKey)", forHTTPHeaderField: "X-Bce-Signature")

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw LookupError.networkError(NSError(domain: "Invalid response", code: -1))
            }

            if httpResponse.statusCode != 200 {
                // Try to parse error message
                if let errorBody = try? JSONDecoder().decode(BaiduBarcodeResponse.self, from: data),
                   let msg = errorBody.message {
                    throw LookupError.apiError("\(msg) (HTTP \(httpResponse.statusCode))")
                }
                throw LookupError.apiError("HTTP \(httpResponse.statusCode)")
            }

            let apiResponse = try JSONDecoder().decode(BaiduBarcodeResponse.self, from: data)

            guard let drugData = apiResponse.data,
                  let drugName = drugData.name,
                  !drugName.isEmpty else {
                // Try to parse error code
                if let code = apiResponse.code, code != "0000" {
                    throw LookupError.apiError(apiResponse.message ?? "查询失败 code=\(code)")
                }
                throw LookupError.notFound
            }

            let result = LookupResult(
                name: drugName,
                category: inferCategory(from: drugName),
                manufacturer: drugData.manuName ?? "未知厂商",
                specification: drugData.spec ?? "未知规格",
                approvalNumber: drugData.approval ?? "",
                dosage: drugData.dosage ?? "",
                purpose: drugData.purpose ?? "",
                taboo: drugData.taboo ?? "",
                imageURL: drugData.img
            )

            // Cache the result locally
            let drugInfo = DrugInfo(
                name: result.name,
                genericName: drugData.basis ?? "",
                category: result.category,
                specifications: [result.specification],
                manufacturer: result.manufacturer,
                barcode: barcode
            )
            DrugDatabase.shared.registerBarcode(barcode, for: drugInfo)

            return result

        } catch let error as LookupError {
            throw error
        } catch is DecodingError {
            throw LookupError.parsingError
        } catch {
            throw LookupError.networkError(error)
        }
    }

    private func inferCategory(from name: String) -> String {
        let nameLower = name.lowercased()

        let categoryKeywords: [(String, [String])] = [
            ("心脑血管", ["阿司匹林", "硝苯地平", "他汀", "硝酸", "氯吡格雷", "美托洛尔", "缬沙坦", "氨氯地平", "卡托普利", "厄贝沙坦", "辛伐他汀", "瑞舒伐他汀", "普萘洛尔", "地尔硫"]),
            ("降糖药", ["二甲双胍", "格列", "阿卡波糖", "胰岛素", "瑞格列奈", "吡格列酮", "达格列净", "西格列汀", "利拉鲁肽"]),
            ("消化系统", ["奥美拉唑", "泮托拉唑", "雷贝拉唑", "铝碳酸镁", "蒙脱石", "多潘立酮", "莫沙必利"]),
            ("感冒药", ["感冒", "复方氨酚", "连花清瘟", "氨酚"]),
            ("止咳药", ["氨溴索", "右美沙芬", "川贝", "枇杷", "甘草", "急支"]),
            ("抗生素", ["阿莫西林", "头孢", "左氧氟沙星", "罗红霉素", "阿奇霉素", "青霉素", "克拉霉素", "四环素", "诺氟沙星"]),
            ("维生素矿物质", ["维生素", "钙", "善存", "叶酸", "铁", "锌", "硒", "鱼油"]),
            ("镇痛消炎", ["布洛芬", "对乙酰氨基酚", "双氯芬酸", "塞来昔布", "芬必得", "扶他林"]),
            ("抗过敏", ["氯雷他定", "西替利嗪", "扑尔敏", "氯苯那敏", "孟鲁司特"]),
            ("安神助眠", ["安神", "褪黑素", "艾司唑仑", "佐匹克隆", "地西泮"])
        ]

        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if nameLower.contains(keyword) {
                    return category
                }
            }
        }

        return "常用药"
    }
}
