import SwiftUI

struct MedicationArchiveView: View {
    @EnvironmentObject private var medicationStore: MedicationStore
    @State private var showManualAdd = false
    @State private var showScanImport = false
    
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
                            
                            PrimaryButton("扫描导入", icon: "barcode.viewfinder", style: .primary) {
                                showScanImport = true
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(Array(medicationStore.medications.enumerated()), id: \.element.id) { index, medication in
                                MedicationCard(
                                    medication: medication,
                                    onDelete: {
                                        withAnimation(Theme.Animation.spring) {
                                            medicationStore.removeMedication(at: IndexSet(integer: index))
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    
                    Spacer()
                        .frame(height: Theme.Spacing.xxl)
                }
                .padding(.top, Theme.Spacing.md)
            }
            .background(Theme.Colors.background)
            .navigationTitle("档案")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.Colors.background.opacity(0.9), for: .navigationBar)
            .sheet(isPresented: $showManualAdd) {
                MedicationEntrySheet(entryMode: .manual)
                    .environmentObject(medicationStore)
            }
            .sheet(isPresented: $showScanImport) {
                ScanImportSheet()
                    .environmentObject(medicationStore)
            }
        }
    }
}

#Preview {
    MedicationArchiveView()
        .environmentObject(MedicationStore())
}
