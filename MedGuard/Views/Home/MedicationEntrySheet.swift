import SwiftUI

enum MedicationEntryMode {
    case manual
    case scanned(code: String)
    
    var title: String {
        switch self {
        case .manual:
            return "手动添加"
        case .scanned:
            return "扫描导入"
        }
    }
    
    var source: MedicationSource {
        switch self {
        case .manual:
            return .manual
        case .scanned:
            return .scanned
        }
    }
}

struct MedicationEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var medicationStore: MedicationStore
    
    let entryMode: MedicationEntryMode
    
    @State private var name = ""
    @State private var category = ""
    @State private var doseAmount = "1"
    @State private var remainingAmount = "24"
    @State private var packageCount = "2"
    @State private var amountPerPackage = "12"
    @State private var selectedUnit: MedicationUnit = .pill
    @State private var selectedTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
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
                    TextField("药品名称", text: $name)
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
        }
    }
    
    private func saveMedication() {
        let dose = max(Int(doseAmount) ?? 1, 1)
        let remaining = max(Int(remainingAmount) ?? 0, 0)
        let packages = max(Int(packageCount) ?? 0, 0)
        let perPackage = max(Int(amountPerPackage) ?? 1, 1)
        
        let medication = Medication(
            id: UUID().uuidString,
            name: name,
            category: category.isEmpty ? "未分类" : category,
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
        dismiss()
    }
}

struct ScanImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var medicationStore: MedicationStore
    @State private var showScanner = false
    @State private var scannedCode: String?
    @State private var scannerError: ScannerError?
    @State private var showEntrySheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                Spacer()
                
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.healthBlue)
                
                Text("从药品档案直接扫描导入")
                    .font(Theme.Typography.title3)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("扫完后可直接补全药名、单位和库存")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                PrimaryButton("开始扫描", icon: "camera.fill", style: .primary) {
                    showScanner = true
                }
                .padding(.horizontal, Theme.Spacing.lg)
                
                Spacer()
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.background)
            .navigationTitle("扫描导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                ScannerView(scannedCode: $scannedCode, scannerError: $scannerError)
            }
            .sheet(isPresented: $showEntrySheet, onDismiss: {
                dismiss()
            }) {
                if let scannedCode {
                    MedicationEntrySheet(entryMode: .scanned(code: scannedCode))
                        .environmentObject(medicationStore)
                }
            }
            .onChange(of: scannedCode) { newValue in
                if newValue != nil {
                    showEntrySheet = true
                }
            }
            .alert("无法启动相机", isPresented: scannerErrorBinding) {
                Button("知道了") {
                    scannerError = nil
                }
            } message: {
                Text(scannerError?.message ?? "请稍后重试")
            }
        }
    }
    
    private var scannerErrorBinding: Binding<Bool> {
        Binding(
            get: { scannerError != nil },
            set: { newValue in
                if !newValue {
                    scannerError = nil
                }
            }
        )
    }
}
