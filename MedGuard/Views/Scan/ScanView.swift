import SwiftUI
import AVFoundation
import AVFoundation

struct ScanView: View {
    @EnvironmentObject private var medicationStore: MedicationStore
    @State private var showScanner = false
    @State private var showManualAdd = false
    @State private var scannedCode: String?
    @State private var showScanResult = false
    @State private var scannerError: ScannerError?

    // For macOS simulator testing
    #if targetEnvironment(simulator)
    @State private var showSimulatorScan = false
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()

                    // Scan frame with corner accents
                    ScanFrame()
                        .padding(.bottom, Theme.Spacing.lg)

                    #if targetEnvironment(simulator)
                    // macOS simulator: use simulated scan for testing
                    PrimaryButton("模拟扫描（测试用）", icon: "cpu", style: .primary) {
                        simulateScan()
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    PrimaryButton("手动添加药品", icon: "plus.circle.fill", style: .secondary) {
                        showManualAdd = true
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    #else
                    PrimaryButton("扫描药盒", icon: "camera.fill", style: .primary) {
                        showScanner = true
                    }
                    .padding(.horizontal, Theme.Spacing.xl)

                    PrimaryButton("手动添加药品", icon: "plus.circle.fill", style: .secondary) {
                        showManualAdd = true
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    #endif

                    if let scannedCode {
                        ScanResultBanner(scannedCode: scannedCode) {
                            showScanResult = true
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }

                    Spacer()

                    VStack(spacing: Theme.Spacing.xs) {
                        Text("扫完可直接加入档案，不用重复录入")
                            .font(Theme.Typography.footnote)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text("导入时可选择片、粒、袋等计量单位")
                            .font(Theme.Typography.footnote)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
            .navigationTitle("扫描")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showManualAdd) {
                MedicationEntrySheet(entryMode: .manual)
                    .environmentObject(medicationStore)
            }
            .sheet(isPresented: $showScanner) {
                ScannerView(scannedCode: $scannedCode, scannerError: $scannerError)
            }
            .sheet(isPresented: $showScanResult) {
                if let scannedCode {
                    MedicationEntrySheet(entryMode: .scanned(code: scannedCode))
                        .environmentObject(medicationStore)
                }
            }
            .alert("无法启动相机", isPresented: scannerErrorBinding) {
                Button("知道了") { scannerError = nil }
            } message: {
                Text(scannerError?.message ?? "请稍后重试")
            }
        }
    }

    private var scannerErrorBinding: Binding<Bool> {
        Binding(
            get: { scannerError != nil },
            set: { if !$0 { scannerError = nil } }
        )
    }

    #if targetEnvironment(simulator)
    private func simulateScan() {
        // Generate a fake drug barcode for testing on macOS simulator
        let fakeCodes = [
            "6901028001938",  // Common format: Chinese drug barcode
            "9780201379624",  // ISBN-style
            "MED123456789ABC"  // Custom format
        ]
        let randomCode = fakeCodes.randomElement() ?? fakeCodes[0]
        scannedCode = randomCode
        showScanResult = true
        Theme.Haptics.success()
    }
    #endif
}

// MARK: - Scan Frame

struct ScanFrame: View {
    var body: some View {
        ZStack {
            // Corner accents
            VStack {
                HStack {
                    CornerAccent()
                    Spacer()
                    CornerAccent()
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    CornerAccent()
                        .rotationEffect(.degrees(-90))
                    Spacer()
                    CornerAccent()
                        .rotationEffect(.degrees(180))
                }
            }
            .frame(width: 260, height: 260)

            // Center icon
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 64, design: .rounded))
                .foregroundStyle(Theme.Colors.healthBlue.opacity(0.4))
        }
    }
}

struct CornerAccent: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Theme.Colors.healthBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .frame(width: 20, height: 20)
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.healthBlue)
                    .frame(width: 32)

                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scan Result Banner

struct ScanResultBanner: View {
    let scannedCode: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, design: .rounded))
                    .foregroundColor(Theme.Colors.success)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("已识别药盒编码")
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.Colors.primaryText)
                    Text(scannedCode)
                        .font(Theme.Typography.caption1)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
            .cardShadow(Theme.Shadow.card)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scanner View

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedCode: String?
    @Binding var scannerError: ScannerError?
    @State private var didFinishScanning = false

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraScannerRepresentable { result in
                guard !didFinishScanning else { return }
                didFinishScanning = true
                scannedCode = result
                dismiss()
            } onFailure: { error in
                scannerError = error
                dismiss()
            }
            .ignoresSafeArea()

            // Frosted glass overlay
            VStack(spacing: Theme.Spacing.lg) {
                Text("将条形码或二维码放入框内")
                    .font(Theme.Typography.headline)
                    .foregroundColor(.white)
                    .padding(.top, Theme.Spacing.xxl)

                Spacer()

                ScannerOverlayFrame()
                    .frame(width: 260, height: 260)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("取消")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .background(
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Scanner Overlay Frame

struct ScannerOverlayFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.extraLarge)
                .stroke(Color.white.opacity(0.35), lineWidth: 2)

            VStack {
                HStack {
                    CameraCornerAccent()
                    Spacer()
                    CameraCornerAccent()
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                HStack {
                    CameraCornerAccent()
                        .rotationEffect(.degrees(-90))
                    Spacer()
                    CameraCornerAccent()
                        .rotationEffect(.degrees(180))
                }
            }
            .padding(Theme.Spacing.sm)
        }
    }
}

struct CameraCornerAccent: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 24))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(Theme.Colors.healthBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        .frame(width: 24, height: 24)
    }
}

// MARK: - Camera Scanner Representable

struct CameraScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onFailure: (ScannerError) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onFailure: onFailure)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    final class Coordinator: NSObject, ScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private let onFailure: (ScannerError) -> Void
        private var hasCompleted = false

        init(onScan: @escaping (String) -> Void, onFailure: @escaping (ScannerError) -> Void) {
            self.onScan = onScan
            self.onFailure = onFailure
        }

        func scannerViewController(_ controller: ScannerViewController, didScan code: String) {
            guard !hasCompleted else { return }
            hasCompleted = true
            Theme.Haptics.success()
            onScan(code)
        }

        func scannerViewController(_ controller: ScannerViewController, didFailWith error: ScannerError) {
            guard !hasCompleted else { return }
            hasCompleted = true
            onFailure(error)
        }
    }
}

// MARK: - Scanner View Controller Delegate

protocol ScannerViewControllerDelegate: AnyObject {
    func scannerViewController(_ controller: ScannerViewController, didScan code: String)
    func scannerViewController(_ controller: ScannerViewController, didFailWith error: ScannerError)
}

// MARK: - Scanner View Controller

final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didReportResult = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted { self.setupCaptureSession() }
                    else { self.reportFailure(.permissionDenied) }
                }
            }
        case .denied, .restricted:
            reportFailure(.permissionDenied)
        @unknown default:
            reportFailure(.unavailable)
        }
    }

    private func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            reportFailure(.unavailable)
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)

            guard captureSession.canAddInput(videoInput) else {
                reportFailure(.configurationFailed)
                return
            }
            captureSession.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(metadataOutput) else {
                reportFailure(.configurationFailed)
                return
            }
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .qr, .code128, .code39, .code93, .upce, .pdf417]

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
        } catch {
            reportFailure(.configurationFailed)
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didReportResult,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = metadataObject.stringValue else { return }
        didReportResult = true
        delegate?.scannerViewController(self, didScan: code)
    }

    private func reportFailure(_ error: ScannerError) {
        guard !didReportResult else { return }
        didReportResult = true
        delegate?.scannerViewController(self, didFailWith: error)
    }
}

// MARK: - Scanner Error

enum ScannerError: Error {
    case permissionDenied
    case unavailable
    case configurationFailed

    var message: String {
        switch self {
        case .permissionDenied:    return "请在系统设置中允许相机权限后再试。"
        case .unavailable:         return "当前设备无法使用相机扫描。"
        case .configurationFailed: return "扫描器初始化失败，请稍后重试。"
        }
    }
}
