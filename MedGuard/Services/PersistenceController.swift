import Foundation

final class PersistenceController {
    static let shared = PersistenceController()

    private let medicationsKey = "medications_data"
    private let userKey = "user_data"

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {}

    // MARK: - Medications

    func saveMedications(_ medications: [Medication]) {
        guard let data = try? encoder.encode(medications) else { return }
        UserDefaults.standard.set(data, forKey: medicationsKey)
    }

    func loadMedications() -> [Medication] {
        guard let data = UserDefaults.standard.data(forKey: medicationsKey),
              let medications = try? decoder.decode([Medication].self, from: data) else {
            return []
        }
        return medications
    }

    // MARK: - Timeline Records

    private let timelineKey = "timeline_records"

    func saveTimelineRecords(_ records: [TimelineRecordData]) {
        guard let data = try? encoder.encode(records) else { return }
        UserDefaults.standard.set(data, forKey: timelineKey)
    }

    func loadTimelineRecords() -> [TimelineRecordData] {
        guard let data = UserDefaults.standard.data(forKey: timelineKey),
              let records = try? decoder.decode([TimelineRecordData].self, from: data) else {
            return []
        }
        return records
    }

    // MARK: - Clear All

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: medicationsKey)
        UserDefaults.standard.removeObject(forKey: timelineKey)
    }
}

// MARK: - Timeline Record Data (Codable version for persistence)

struct TimelineRecordData: Codable, Identifiable {
    let id: String
    let medicationId: String
    let medicationName: String
    let medicationCategory: String
    let medicationDosage: String
    let medicationSource: String
    let medicationTime: Date
    let recordDate: Date
    let wasTaken: Bool
    let wasSkipped: Bool

    var derivedStatus: MedicationStatus {
        if wasTaken { return .taken }
        if wasSkipped { return .skipped }
        return .pending
    }

    init(from record: TimelineRecord) {
        self.id = record.id
        self.medicationId = record.medication.id
        self.medicationName = record.medication.name
        self.medicationCategory = record.medication.category
        self.medicationDosage = record.medication.dosage
        self.medicationSource = record.medication.source.rawValue
        self.medicationTime = record.medication.time
        self.recordDate = record.recordDate
        self.wasTaken = record.medication.status == .taken
        self.wasSkipped = record.medication.status == .skipped
    }

    init(
        id: String = UUID().uuidString,
        medicationId: String,
        medicationName: String,
        medicationCategory: String,
        medicationDosage: String,
        medicationSource: String,
        medicationTime: Date,
        recordDate: Date = Date(),
        wasTaken: Bool,
        wasSkipped: Bool
    ) {
        self.id = id
        self.medicationId = medicationId
        self.medicationName = medicationName
        self.medicationCategory = medicationCategory
        self.medicationDosage = medicationDosage
        self.medicationSource = medicationSource
        self.medicationTime = medicationTime
        self.recordDate = recordDate
        self.wasTaken = wasTaken
        self.wasSkipped = wasSkipped
    }

    func toTimelineRecord(medications: [Medication]) -> TimelineRecord {
        let medication: Medication
        if let existing = medications.first(where: { $0.id == medicationId }) {
            medication = existing
        } else {
            medication = Medication(
                id: medicationId,
                name: medicationName,
                category: medicationCategory,
                dosage: medicationDosage,
                time: medicationTime,
                status: derivedStatus,
                doseAmount: 0,
                doseUnit: .pill,
                remainingAmount: 0,
                packageCount: 0,
                amountPerPackage: 0,
                source: MedicationSource(rawValue: medicationSource) ?? .preset
            )
        }
        return TimelineRecord(id: id, medication: medication, recordDate: recordDate)
    }
}
