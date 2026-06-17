import SwiftUI

struct ScannedDrugResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var medicationStore: MedicationStore
    
    let scannedCode: String
    let onComplete: () -> Void
    
    @State private var lookupResult: DrugLookupService.LookupResult?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showManualEntry = false
    
    // Form fields
    @State private var name = ""
    @State private var category = ""
    @State private var manufacturer = ""
    @State private var specification = ""
    @State private var doseAmount = "1"
    @State private var remainingAmount = "24"
    @State private var packageCount = "2"
    @State private var amountPerPackage = "12"
    @State private var selectedUnit: MedicationUnit = .pill
    @State private var selectedTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    barcodeCard
                    
                    if isLoading {
                        loadingView
                    } else if let result = lookupResult {
                        resultView(result)
                    } else {
                        notFoundView
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("扫描结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .task {
                await lookupDrug()
            }
            .sheet(isPresented: $showManualEntry) {
                NavigationStack {
                    Form {
                        Section("条码信息") {
                            LabeledContent("条码") {
                                Text(scannedCode)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        }
                        
                        Section("药品信息") {
                            TextField("药品名称", text: $name)
                            TextField("分类", text: $category)
                            TextField("生产厂家", text: $manufacturer)
                            TextField("规格", text: $specification)
                        }
                        
                        Section("提醒设置") {
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
                    .navigationTitle("手动添加药品")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("取消") {
                                showManualEntry = false
                            }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("保存") {
                                saveManualEntry()
                            }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .environmentObject(medicationStore)
            }
        }
    }
    
    private var barcodeCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "barcode")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.Colors.healthBlue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("扫描条码")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Colors.secondaryText)
                    Text(scannedCode)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.primaryText)
                }
                
                Spacer()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }
    
    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("正在查询药品信息...")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.xxl)
    }
    
    private func resultView(_ result: DrugLookupService.LookupResult) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Drug info card
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.success.opacity(0.12))
                            .frame(width: 48, height: 48)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.Colors.success)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("药品信息已找到")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.primaryText)
                        Text("数据来源：百度药品条码数据库")
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                infoRow(label: "药品名称", value: result.name)
                infoRow(label: "分类", value: result.category)
                infoRow(label: "生产厂家", value: result.manufacturer)
                infoRow(label: "规格", value: result.specification)
                
                if !result.approvalNumber.isEmpty {
                    infoRow(label: "批准文号", value: result.approvalNumber)
                }
                if !result.dosage.isEmpty {
                    infoRow(label: "用法用量", value: result.dosage)
                }
                if !result.purpose.isEmpty {
                    infoRow(label: "功能主治", value: result.purpose)
                }
                if !result.taboo.isEmpty {
                    infoRow(label: "禁忌", value: result.taboo)
                }
                if let imageURL = result.imageURL, !imageURL.isEmpty {
                    infoRow(label: "药品图片", value: imageURL)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            
            // Quick add button
            PrimaryButton("快速添加", icon: "plus.circle.fill", style: .primary) {
                quickAdd(result)
            }
            
            // Manual entry button
            Button {
                fillFormFromResult(result)
                showManualEntry = true
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                    Text("手动调整后添加")
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.healthBlue)
            }
            .padding(.top, Theme.Spacing.sm)
        }
    }
    
    private var notFoundView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.warning.opacity(0.12))
                        .frame(width: 64, height: 64)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.Colors.warning)
                }
                
                Text("未找到该药品信息")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.primaryText)
                
                Text("该条码可能不在数据库中\n您可以手动输入药品信息")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton("手动添加药品", icon: "square.and.pencil", style: .primary) {
                showManualEntry = true
            }
        }
        .padding(.vertical, Theme.Spacing.xl)
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.secondaryText)
            Spacer()
            Text(value)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func lookupDrug() async {
        do {
            let result = try await DrugLookupService.shared.lookupDrug(barcode: scannedCode)
            await MainActor.run {
                self.lookupResult = result
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func fillFormFromResult(_ result: DrugLookupService.LookupResult) {
        name = result.name
        category = result.category
        manufacturer = result.manufacturer
        specification = result.specification
    }
    
    private func quickAdd(_ result: DrugLookupService.LookupResult) {
        let medication = Medication(
            id: UUID().uuidString,
            name: result.name,
            category: result.category,
            dosage: "1\(selectedUnit.rawValue)",
            time: selectedTime,
            status: .pending,
            doseAmount: 1,
            doseUnit: selectedUnit,
            remainingAmount: 24,
            packageCount: 2,
            amountPerPackage: 12,
            source: .scanned
        )
        
        medicationStore.addMedication(medication)
        Theme.Haptics.success()
        onComplete()
        dismiss()
    }
    
    private func saveManualEntry() {
        let dose = max(Int(doseAmount) ?? 1, 1)
        let remaining = max(Int(remainingAmount) ?? 0, 0)
        let packages = max(Int(packageCount) ?? 0, 0)
        let perPackage = max(Int(amountPerPackage) ?? 1, 1)
        
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
            source: .scanned
        )
        
        medicationStore.addMedication(medication)
        Theme.Haptics.success()
        onComplete()
        dismiss()
    }
}

#Preview {
    ScannedDrugResultView(scannedCode: "6901028001938") {
        print("Completed")
    }
    .environmentObject(MedicationStore())
}
