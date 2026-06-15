import Foundation
import SwiftUI

@MainActor
final class MedicationStore: ObservableObject {
    @Published var medications: [Medication]
    
    init(medications: [Medication] = MockData.medications) {
        self.medications = medications
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
        
        if oldStatus != .taken && newStatus == .taken {
            deductInventory(at: index)
        } else if oldStatus == .taken && newStatus != .taken {
            restoreInventory(at: index)
        }
    }
    
    func addMedication(_ medication: Medication) {
        medications.insert(medication, at: 0)
    }
    
    func removeMedication(at offsets: IndexSet) {
        medications.remove(atOffsets: offsets)
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
    }
    
    private func restoreInventory(at index: Int) {
        let restoredAmount = medications[index].doseAmount
        medications[index].remainingAmount += restoredAmount
        recalculatePackages(at: index)
    }
    
    private func recalculatePackages(at index: Int) {
        let perPackage = max(medications[index].amountPerPackage, 1)
        let amount = medications[index].remainingAmount
        medications[index].packageCount = amount == 0 ? 0 : Int(ceil(Double(amount) / Double(perPackage)))
    }
}
