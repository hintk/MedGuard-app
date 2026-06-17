import Foundation
import UIKit

final class DataExporter {
    static let shared = DataExporter()
    
    private init() {}
    
    enum ExportFormat {
        case json
        case csv
        
        var mimeType: String {
            switch self {
            case .json: return "application/json"
            case .csv: return "text/csv"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }
    
    enum ExportError: LocalizedError {
        case noData
        case encodingFailed
        
        var errorDescription: String? {
            switch self {
            case .noData:
                return "没有可导出的数据"
            case .encodingFailed:
                return "数据编码失败"
            }
        }
    }
    
    func exportMedications(_ medications: [Medication], format: ExportFormat) throws -> Data {
        guard !medications.isEmpty else {
            throw ExportError.noData
        }
        
        switch format {
        case .json:
            return try exportToJSON(medications)
        case .csv:
            return try exportToCSV(medications)
        }
    }
    
    private func exportToJSON(_ medications: [Medication]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(medications)
    }
    
    private func exportToCSV(_ medications: [Medication]) throws -> Data {
        var csv = "ID,药品名称,分类,剂量,提醒时间,状态,剩余数量,盒数,每盒数量,来源\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        for med in medications {
            let row = [
                med.id,
                escapeCSV(med.name),
                escapeCSV(med.category),
                escapeCSV(med.dosage),
                dateFormatter.string(from: med.time),
                med.status.rawValue,
                String(med.remainingAmount),
                String(med.packageCount),
                String(med.amountPerPackage),
                med.source.rawValue
            ].joined(separator: ",")
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    func generateExportFileName(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        switch format {
        case .json:
            return "MedGuard_药品备份_\(timestamp).json"
        case .csv:
            return "MedGuard_药品备份_\(timestamp).csv"
        }
    }
    
    func createShareableFile(data: Data, format: ExportFormat) -> URL? {
        let fileName = generateExportFileName(format: format)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
}
