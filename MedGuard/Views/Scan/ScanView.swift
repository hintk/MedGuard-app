import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var medicationStore: MedicationStore
    @State private var showCamera = false
    @State private var showManualAdd = false
    @State private var capturedImageData: Data?
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Theme.Colors.healthBlue.opacity(0.10))
                            .frame(width: 120, height: 120)
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48, design: .rounded))
                            .foregroundStyle(Theme.Colors.healthBlue)
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        Text("拍照识别药品")
                            .font(Theme.Typography.title2)
                            .foregroundStyle(Theme.Colors.primaryText)
                        Text("拍下药盒照片，AI 自动识别药品信息")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                    }

                    PrimaryButton("拍照识别", icon: "camera.fill", style: .primary) {
                        showCamera = true
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    PrimaryButton("手动输入", icon: "square.and.pencil", style: .secondary) {
                        showManualAdd = true
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    Spacer()

                    Text("支持国产药品和进口药品包装盒识别")
                        .font(Theme.Typography.footnote)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("扫描")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showManualAdd) {
                MedicationEntrySheet(entryMode: .manual)
                    .environmentObject(medicationStore)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(capturedImageData: $capturedImageData)
            }
            .onChange(of: capturedImageData) { newValue in
                showResult = newValue != nil
            }
            .sheet(isPresented: $showResult) {
                if let data = capturedImageData {
                    AIDrugResultView(
                        imageData: data,
                        onSave: { medication in
                            medicationStore.addMedication(medication)
                            capturedImageData = nil
                            showResult = false
                        },
                        onDismiss: {
                            capturedImageData = nil
                            showResult = false
                        }
                    )
                    .environmentObject(medicationStore)
                }
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.7) {
                parent.capturedImageData = data
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - AI Recognition Result View (4-Step Flow)

struct AIDrugResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var medicationStore: MedicationStore

    let imageData: Data
    let onSave: (Medication) -> Void
    let onDismiss: () -> Void

    @State private var recognitionResult: DoubaoService.DrugRecognitionResult?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var rawResponse = ""
    @State private var showRawResponse = false
    @State private var currentStep = 0
    let totalSteps = 4

    @State private var name = ""
    @State private var category = ""
    @State private var manufacturer = ""
    @State private var specification = ""
    @State private var doseAmount = ""
    @State private var remainingAmount = ""
    @State private var packageCount = ""
    @State private var amountPerPackage = ""
    @State private var selectedUnit: MedicationUnit = .pill
    @State private var selectedTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()

    // Animation states
    @State private var showCheckmark = false
    @State private var flyAnimation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if recognitionResult != nil || errorMessage != nil {
                    progressBar
                    if flyAnimation {
                        flyEffectView
                    } else {
                        TabView(selection: $currentStep) {
                            step1AIResult.tag(0)
                            step2Confirm.tag(1)
                            step3Reminder.tag(2)
                            step4Inventory.tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .background(Theme.Colors.background)
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { onDismiss() }
                }
            }
            .task { await doRecognition() }
        }
    }

    private var stepTitle: String {
        ["识别结果", "确认信息", "提醒设置", "库存设置"][currentStep]
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Theme.Colors.healthBlue : Theme.Colors.tertiaryBg)
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            Text("\(currentStep + 1)/\(totalSteps)")
                .font(Theme.Typography.caption1).foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, 4)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.md) {
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable().scaledToFit().frame(maxHeight: 180).clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            Spacer()
            ProgressView().scaleEffect(1.5)
            Text("AI 正在识别药品信息...")
                .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Recognition

    private func doRecognition() async {
        do {
            let (result, raw) = try await DoubaoService.shared.recognizeDrug(imageData: imageData)
            await MainActor.run {
                rawResponse = raw; recognitionResult = result
                name = result.name; category = result.category
                manufacturer = result.manufacturer; specification = result.specification
                isLoading = false
            }
        } catch {
            await MainActor.run {
                rawResponse = "=== 错误响应 ===\n\(error.localizedDescription)"
                errorMessage = error.localizedDescription; isLoading = false
            }
        }
    }

    // MARK: - Step 1: AI Result

    private var step1AIResult: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                if let image = UIImage(data: imageData) {
                    Image(uiImage: image).resizable().scaledToFit()
                        .frame(maxHeight: 160).clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                }
                if let result = recognitionResult {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20)).foregroundStyle(Theme.Colors.success)
                            Text("AI 识别结果").font(Theme.Typography.headline)
                            Spacer()
                        }
                        Divider()
                        stepRow("药品名称", value: $name)
                        stepRow("分类", value: $category)
                        stepRow("厂商", value: $manufacturer)
                        stepRow("规格", value: $specification)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))

                    rawResponseToggle
                }
                if errorMessage != nil {
                    errorCard
                }

                stepButtons(nextLabel: "确认,下一步", onNext: { currentStep = 1 },
                           skipLabel: "跳过,手动填写", onSkip: { onDismiss() })
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.md)
        }
    }

    // MARK: - Step 2: Confirm + Animation

    private var step2Confirm: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: showCheckmark ? "checkmark.circle.fill" : "doc.text.magnifyingglass")
                    .font(.system(size: 64))
                    .foregroundStyle(showCheckmark ? Theme.Colors.success : Theme.Colors.healthBlue)
                    .scaleEffect(showCheckmark ? 1.2 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.5), value: showCheckmark)

                VStack(spacing: Theme.Spacing.xs) {
                    Text(showCheckmark ? "信息已确认 ✓" : "确认药品信息")
                        .font(Theme.Typography.title2).foregroundStyle(Theme.Colors.primaryText)
                    Text(showCheckmark ? "正在保存到药品档案..." : "药品名称、分类、厂商、规格已由 AI 识别")
                        .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                if !showCheckmark {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        confirmRow("名称", value: name)
                        confirmRow("分类", value: category)
                        confirmRow("规格", value: specification)
                    }
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                    .padding(.horizontal, Theme.Spacing.xl)
                }
            }

            Spacer()

            if showCheckmark {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Theme.Colors.success)
            }

            stepButtons(
                nextLabel: "✓ 确认", onNext: { animateAndGo() },
                skipLabel: "跳过", onSkip: { currentStep = 2 }
            )
        }
        .padding(Theme.Spacing.md)
    }

    private func animateAndGo() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { showCheckmark = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.3)) { flyAnimation = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flyAnimation = false
                showCheckmark = false
                currentStep = 2
            }
        }
    }

    private var flyEffectView: some View {
        VStack(spacing: Theme.Spacing.md) {
            Spacer()
            Text("✓")
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(Theme.Colors.success)
                .scaleEffect(1.5)
                .opacity(0)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale(scale: 0.1).combined(with: .opacity))
    }

    // MARK: - Step 3: Reminder

    private var step3Reminder: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48)).foregroundStyle(Theme.Colors.healthBlue)
                Text("设置提醒").font(Theme.Typography.title2)
            }

            VStack(spacing: Theme.Spacing.md) {
                HStack {
                    Text("计量单位").font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
                    Spacer()
                    Picker("", selection: $selectedUnit) {
                        ForEach(MedicationUnit.allCases) { unit in Text(unit.rawValue).tag(unit) }
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))

                HStack {
                    Text("提醒时间").font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
                    Spacer()
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            stepButtons(nextLabel: "下一步", onNext: { currentStep = 3 },
                       skipLabel: "跳过", onSkip: { currentStep = 3 })
        }
        .padding(Theme.Spacing.md)
    }

    // MARK: - Step 4: Inventory

    private var step4Inventory: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 48)).foregroundStyle(Theme.Colors.healthBlue)
                Text("库存设置").font(Theme.Typography.title2)
                Text("填写实际数量，留空则默认为 0")
                    .font(Theme.Typography.caption1).foregroundStyle(Theme.Colors.secondaryText)
            }

            VStack(spacing: Theme.Spacing.sm) {
                HStack {
                    Text("每次用量").font(Theme.Typography.subheadline); Spacer()
                    TextField("填写", text: $doseAmount).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 100)
                }
                Divider()
                HStack {
                    Text("当前剩余").font(Theme.Typography.subheadline); Spacer()
                    TextField("填写", text: $remainingAmount).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 100)
                }
                Divider()
                HStack {
                    Text("盒数").font(Theme.Typography.subheadline); Spacer()
                    TextField("填写", text: $packageCount).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 100)
                }
                Divider()
                HStack {
                    Text("每盒数量").font(Theme.Typography.subheadline); Spacer()
                    TextField("填写", text: $amountPerPackage).keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 100)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()

            PrimaryButton("添加到药品档案 ✓", icon: "plus.circle.fill") { saveMedication() }
                .padding(.horizontal, Theme.Spacing.lg)
            Button("跳过") { saveMedication() }
                .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
        }
        .padding(Theme.Spacing.md)
    }

    // MARK: - Shared Components

    private func stepButtons(nextLabel: String, onNext: @escaping () -> Void, skipLabel: String, onSkip: @escaping () -> Void) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            PrimaryButton(nextLabel, icon: "arrow.right") { onNext() }
                .padding(.horizontal, Theme.Spacing.lg)
            Button(skipLabel) { onSkip() }
                .font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
        }
    }

    private func stepRow(_ label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label).font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
            Spacer()
            TextField("", text: value).multilineTextAlignment(.trailing)
                .font(Theme.Typography.subheadline.weight(.medium))
        }
    }

    private func confirmRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(Theme.Typography.subheadline).foregroundStyle(Theme.Colors.secondaryText)
            Spacer()
            Text(value).font(Theme.Typography.subheadline.weight(.semibold)).foregroundStyle(Theme.Colors.primaryText)
        }
    }

    private var rawResponseToggle: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Button { withAnimation { showRawResponse.toggle() } } label: {
                HStack {
                    Image(systemName: showRawResponse ? "chevron.down" : "chevron.right").font(.system(size: 12))
                    Text("查看豆包原始返回").font(Theme.Typography.subheadline)
                    Spacer()
                }.foregroundStyle(Theme.Colors.healthBlue)
            }
            if showRawResponse && !rawResponse.isEmpty {
                Text(rawResponse).font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Theme.Colors.tertiaryText).textSelection(.enabled)
                    .padding(Theme.Spacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.tertiaryBg).clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            }
        }
        .padding(Theme.Spacing.sm).background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
    }

    private var errorCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24)).foregroundStyle(Theme.Colors.danger)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("❌ 识别失败").font(Theme.Typography.headline)
                        Text("请检查网络或重试").font(Theme.Typography.caption1).foregroundStyle(Theme.Colors.secondaryText)
                    }
                    Spacer()
                }
                Divider()
                Text(errorMessage ?? "未知错误")
                    .font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.danger)
                    .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    .padding(Theme.Spacing.sm).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.danger.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            }
            .padding(Theme.Spacing.md).background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))

            HStack(spacing: Theme.Spacing.md) {
                PrimaryButton("重试", icon: "arrow.clockwise") {
                    isLoading = true; errorMessage = nil; rawResponse = ""
                    Task { await doRecognition() }
                }
                PrimaryButton("手动填写", icon: "square.and.pencil", style: .secondary) { onDismiss() }
            }
        }
    }

    private func saveMedication() {
        let dose = max(Int(doseAmount) ?? 0, 0)
        let remaining = max(Int(remainingAmount) ?? 0, 0)
        let packages = max(Int(packageCount) ?? 0, 0)
        let perPackage = max(Int(amountPerPackage) ?? 0, 0)
        let medication = Medication(
            id: UUID().uuidString,
            name: name,
            category: (category == "未知" || category.isEmpty) ? Theme.Strings.uncategorized : category,
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
        onSave(medication)
        dismiss()
    }
}

#Preview {
    ScanView().environmentObject(MedicationStore())
}
