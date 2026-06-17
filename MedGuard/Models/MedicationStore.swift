import Foundation
import SwiftUI

@MainActor
final class MedicationStore: ObservableObject {
    @Published var medications: [Medication]
    
    init(medications: [Medication]? = nil) {
        let savedMedications = PersistenceController.shared.loadMedications()
        self.medications = medications ?? savedMedications

        // Listen for MARK_TAKEN notification action from push notification
        NotificationCenter.default.addObserver(
            forName: .markMedicationTaken,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let medicationId = notification.userInfo?["medicationId"] as? String else { return }
            Task { @MainActor in
                self.updateStatus(for: medicationId, to: .taken)
            }
        }
    }
    
    private func save() {
        PersistenceController.shared.saveMedications(medications)
    }
    
    var takenCount: Int {
        medications.filter { $0.status == .taken }.count
    }
    
    var totalCount: Int {
        medications.count
    }
    
    func updateStatus(for medicationID: String, to newStatus: MedicationStatus) {
        guard let index = medications.firstIndex(where: { $0.id == medicationID }) else { return }
        let oldStatus = medications[index].status
        medications[index].status = newStatus
        save()

        if oldStatus != .taken && newStatus == .taken {
            deductInventory(at: index)
        } else if oldStatus == .taken && newStatus != .taken {
            restoreInventory(at: index)
        }

        // Persist timeline record
        if newStatus == .taken || newStatus == .skipped {
            let med = medications[index]
            let record = TimelineRecordData(
                medicationId: med.id,
                medicationName: med.name,
                medicationCategory: med.category,
                medicationDosage: med.dosage,
                medicationSource: med.source.rawValue,
                medicationTime: med.time,
                recordDate: Date(),
                wasTaken: newStatus == .taken,
                wasSkipped: newStatus == .skipped
            )
            var records = PersistenceController.shared.loadTimelineRecords()
            // Replace duplicate for same medication on the same day
            let today = Calendar.current.startOfDay(for: Date())
            records.removeAll {
                $0.medicationId == record.medicationId &&
                Calendar.current.isDate($0.recordDate, inSameDayAs: today)
            }
            records.insert(record, at: 0)
            PersistenceController.shared.saveTimelineRecords(records)
        }
    }
    
    func addMedication(_ medication: Medication) {
        medications.insert(medication, at: 0)
        save()
        scheduleReminder(for: medication)
    }
    
    func updateMedication(_ medication: Medication) {
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[index] = medication
        save()
        NotificationManager.shared.cancelMedicationReminder(medicationId: medication.id)
        scheduleReminder(for: medication)
    }
    
    func removeMedication(at offsets: IndexSet) {
        for index in offsets {
            let medicationId = medications[index].id
            NotificationManager.shared.cancelMedicationReminder(medicationId: medicationId)
        }
        medications.remove(atOffsets: offsets)
        save()
    }
    
    func removeMedication(byId id: String) {
        guard let index = medications.firstIndex(where: { $0.id == id }) else { return }
        NotificationManager.shared.cancelMedicationReminder(medicationId: id)
        medications.remove(at: index)
        save()
    }
    
    func addScannedMedication(scannedCode: String, doseUnit: MedicationUnit = .pill) {
        let newMedication = Medication(
            id: UUID().uuidString,
            name: "新扫描药品",
            category: "待确认",
            dosage: "1\(doseUnit.rawValue)",
            time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date(),
            status: .pending,
            doseAmount: 1,
            doseUnit: doseUnit,
            remainingAmount: 24,
            packageCount: 2,
            amountPerPackage: 12,
            source: .scanned
        )
        addMedication(newMedication)
    }
    
    private func deductInventory(at index: Int) {
        let usedAmount = medications[index].doseAmount
        medications[index].remainingAmount = max(medications[index].remainingAmount - usedAmount, 0)
        recalculatePackages(at: index)
        save()
    }
    
    private func restoreInventory(at index: Int) {
        let restoredAmount = medications[index].doseAmount
        medications[index].remainingAmount += restoredAmount
        recalculatePackages(at: index)
        save()
    }
    
    private func recalculatePackages(at index: Int) {
        let perPackage = max(medications[index].amountPerPackage, 1)
        let amount = medications[index].remainingAmount
        medications[index].packageCount = amount == 0 ? 0 : Int(ceil(Double(amount) / Double(perPackage)))
    }
    
    private func scheduleReminder(for medication: Medication) {
        guard medication.status == .pending else { return }
        NotificationManager.shared.scheduleMedicationReminder(
            medicationName: medication.name,
            time: medication.time,
            medicationId: medication.id
        )
    }
}
