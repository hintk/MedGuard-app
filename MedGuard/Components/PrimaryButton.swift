import SwiftUI

struct PrimaryButton: View {
    enum Style {
        case primary
        case secondary
    }
    
    private let title: String
    private let icon: String?
    private let style: Style
    private let action: () -> Void
    
    init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(Theme.Typography.headline)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
        }
        .buttonStyle(.plain)
    }
    
    private var foregroundColor: Color {
        style == .primary ? .white : Theme.Colors.healthBlue
    }
    
    private var background: some ShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(Theme.Colors.healthBlue)
        case .secondary:
            return AnyShapeStyle(Theme.Colors.cardBackground)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton("开始扫描", icon: "camera.fill") {}
        PrimaryButton("手动添加", icon: "square.and.pencil", style: .secondary) {}
    }
    .padding()
}
