import SwiftUI

struct MedicationArchiveView: View {
    @EnvironmentObject private var medicationStore: MedicationStore
    @State private var showManualAdd = false
    @State private var showScanCamera = false
    @State private var scanImageData: Data?
    @State private var showScanResult = false
    @State private var editingMedication: Medication?
    @State private var medicationToDelete: Medication?
    @State private var deleteIndex: Int?
    @State private var searchText = ""
    @State private var selectedCategory: String?
    
    private var categories: [String] {
        Array(Set(medicationStore.medications.map { $0.category })).sorted()
    }
    
    private var filteredMedications: [Medication] {
        var result = medicationStore.medications
        
        if !searchText.isEmpty {
            result = result.filter { medication in
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        return result.sorted { $0.time < $1.time }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        SectionHeader(
                            title: "药品档案",
                            subtitle: "管理药物资料、库存和提醒时间"
                        )
                        .padding(.horizontal, Theme.Spacing.md)
                        
                        HStack(spacing: Theme.Spacing.sm) {
                            PrimaryButton("手动添加", icon: "square.and.pencil", style: .secondary) {
                                showManualAdd = true
                            }
                            
                            PrimaryButton("拍照导入", icon: "camera.viewfinder", style: .primary) {
                                showScanCamera = true
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        
                        if !categories.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    FilterChip(title: "全部", isSelected: selectedCategory == nil) {
                                        selectedCategory = nil
                                    }
                                    
                                    ForEach(categories, id: \.self) { category in
                                        FilterChip(title: category, isSelected: selectedCategory == category) {
                                            selectedCategory = selectedCategory == category ? nil : category
                                        }
                                    }
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                            }
                        }
                        
                        if filteredMedications.isEmpty {
                            if medicationStore.medications.isEmpty {
                                EmptyStateView(
                                    icon: "pills",
                                    title: "暂无药品档案",
                                    message: "添加药品后即可在此管理",
                                    style: .info
                                )
                                .padding(.horizontal, Theme.Spacing.md)
                            } else {
                                EmptyStateView(
                                    icon: "magnifyingglass",
                                    title: "未找到匹配的药品",
                                    message: "尝试调整搜索条件",
                                    style: .info
                                )
                                .padding(.horizontal, Theme.Spacing.md)
                            }
                        } else {
                            LazyVStack(spacing: Theme.Spacing.sm) {
                                ForEach(filteredMedications) { medication in
                                    MedicationCard(
                                        medication: medication,
                                        onDelete: {
                                            if let idx = medicationStore.medications.firstIndex(where: { $0.id == medication.id }) {
                                                medicationToDelete = medication
                                                deleteIndex = idx
                                            }
                                        },
                                        onEdit: {
                                            editingMedication = medication
                                        }
                                    )
                                    .accessibilityLabel("\(medication.name), \(medication.category), \(medication.dosage)")
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                    }
                    
                    Spacer()
                        .frame(height: Theme.Spacing.xxl)
                }
                .padding(.top, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("档案")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "搜索药品名称或分类")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !medicationStore.medications.isEmpty {
                        Text("\(filteredMedications.count) 项")
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.Colors.background.opacity(0.9), for: .navigationBar)
            .sheet(isPresented: $showManualAdd) {
                MedicationEntrySheet(entryMode: .manual)
                    .environmentObject(medicationStore)
            }
            .fullScreenCover(isPresented: $showScanCamera) {
                CameraView(capturedImageData: $scanImageData)
                    .ignoresSafeArea()
            }
            .onChange(of: scanImageData) { newValue in
                showScanResult = newValue != nil
            }
            .sheet(isPresented: $showScanResult) {
                if let data = scanImageData {
                    AIDrugResultView(
                        imageData: data,
                        onSave: { medication in
                            medicationStore.addMedication(medication)
                            scanImageData = nil
                            showScanResult = false
                        },
                        onDismiss: {
                            scanImageData = nil
                            showScanResult = false
                        }
                    )
                    .environmentObject(medicationStore)
                }
            }
            .sheet(item: $editingMedication) { medication in
                MedicationEntrySheet(entryMode: .edit(medication: medication))
                    .environmentObject(medicationStore)
            }
            .alert("确认删除", isPresented: deleteAlertBinding) {
                Button("取消", role: .cancel) {
                    medicationToDelete = nil
                    deleteIndex = nil
                }
                Button("删除", role: .destructive) {
                    if let idx = deleteIndex {
                        withAnimation(Theme.Animation.spring) {
                            medicationStore.removeMedication(at: IndexSet(integer: idx))
                        }
                    }
                    medicationToDelete = nil
                    deleteIndex = nil
                }
            } message: {
                if let med = medicationToDelete {
                    Text("确定要删除「\(med.name)」吗？\n该操作无法撤销。")
                }
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { medicationToDelete != nil },
            set: { if !$0 { medicationToDelete = nil; deleteIndex = nil } }
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.caption1)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Theme.Colors.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.Colors.healthBlue : Theme.Colors.cardBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MedicationArchiveView()
        .environmentObject(MedicationStore())
}
