import SwiftUI

enum MedicationEntryMode {
    case manual
    case scanned(code: String)
    case edit(medication: Medication)
    
    var title: String {
        switch self {
        case .manual:
            return "手动添加"
        case .scanned:
            return "扫描导入"
        case .edit:
            return "编辑药品"
        }
    }
    
    var source: MedicationSource {
        switch self {
        case .manual:
            return .manual
        case .scanned:
            return .scanned
        case .edit(let medication):
            return medication.source
        }
    }
    
    var isEditing: Bool {
        if case .edit = self { return true }
        return false
    }
}

struct MedicationEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var medicationStore: MedicationStore
    
    let entryMode: MedicationEntryMode
    
    @State private var name = ""
    @State private var category = ""
    @State private var doseAmount = ""
    @State private var remainingAmount = ""
    @State private var packageCount = ""
    @State private var amountPerPackage = ""
    @State private var selectedUnit: MedicationUnit = .pill
    @State private var selectedTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var originalMedicationId: String?
    @State private var showDrugSearch = false
    
    init(entryMode: MedicationEntryMode) {
        self.entryMode = entryMode
        if case let .edit(medication) = entryMode {
            _name = State(initialValue: medication.name)
            _category = State(initialValue: medication.category)
            _doseAmount = State(initialValue: String(medication.doseAmount))
            _remainingAmount = State(initialValue: String(medication.remainingAmount))
            _packageCount = State(initialValue: String(medication.packageCount))
            _amountPerPackage = State(initialValue: String(medication.amountPerPackage))
            _selectedUnit = State(initialValue: medication.doseUnit)
            _selectedTime = State(initialValue: medication.time)
            _originalMedicationId = State(initialValue: medication.id)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if case let .scanned(code) = entryMode {
                    Section("扫描信息") {
                        LabeledContent("条码") {
                            Text(code)
                                .foregroundColor(Theme.Colors.secondaryText)
                        }
                    }
                }
                
                Section("药品信息") {
                    HStack {
                        TextField("药品名称", text: $name)
                        
                        Button {
                            showDrugSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Theme.Colors.healthBlue)
                        }
                    }
                    
                    TextField("分类", text: $category)
                    Picker("计量单位", selection: $selectedUnit) {
                        ForEach(MedicationUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    DatePicker("提醒时间", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section("库存设置") {
                    TextField("每次数量", text: $doseAmount)
                        .keyboardType(.numberPad)
                    TextField("当前剩余数量", text: $remainingAmount)
                        .keyboardType(.numberPad)
                    TextField("当前盒数", text: $packageCount)
                        .keyboardType(.numberPad)
                    TextField("每盒数量", text: $amountPerPackage)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(entryMode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        saveMedication()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showDrugSearch) {
                DrugSearchSheet { drug in
                    name = drug.name
                    category = drug.category
                }
            }
        }
    }
    
    private func saveMedication() {
        let dose = max(Int(doseAmount) ?? 0, 0)
        let remaining = max(Int(remainingAmount) ?? 0, 0)
        let packages = max(Int(packageCount) ?? 0, 0)
        let perPackage = max(Int(amountPerPackage) ?? 0, 0)
        
        if case let .edit(originalMedication) = entryMode {
            var updatedMedication = originalMedication
            updatedMedication.name = name
            updatedMedication.category = category.isEmpty ? Theme.Strings.uncategorized : category
            updatedMedication.dosage = "\(dose)\(selectedUnit.rawValue)"
            updatedMedication.time = selectedTime
            updatedMedication.doseAmount = dose
            updatedMedication.doseUnit = selectedUnit
            updatedMedication.remainingAmount = remaining
            updatedMedication.packageCount = packages
            updatedMedication.amountPerPackage = perPackage
            
            medicationStore.updateMedication(updatedMedication)
        } else {
            let medication = Medication(
                id: UUID().uuidString,
                name: name,
                category: category.isEmpty ? Theme.Strings.uncategorized : category,
                dosage: "\(dose)\(selectedUnit.rawValue)",
                time: selectedTime,
                status: .pending,
                doseAmount: dose,
                doseUnit: selectedUnit,
                remainingAmount: remaining,
                packageCount: packages,
                amountPerPackage: perPackage,
                source: entryMode.source
            )
            
            medicationStore.addMedication(medication)
        }
        
        dismiss()
    }
}

