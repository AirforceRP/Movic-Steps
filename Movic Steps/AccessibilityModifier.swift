import SwiftUI

// MARK: - Environment Keys for Accessibility
struct ColorBlindnessTypeKey: EnvironmentKey {
    static let defaultValue: ColorBlindnessType = .none
}

struct MotionReducedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var colorBlindnessType: ColorBlindnessType {
        get { self[ColorBlindnessTypeKey.self] }
        set { self[ColorBlindnessTypeKey.self] = newValue }
    }
    
    var motionReduced: Bool {
        get { self[MotionReducedKey.self] }
        set { self[MotionReducedKey.self] = newValue }
    }
}

// MARK: - Accessibility View Modifier
struct AccessibilityModifier: ViewModifier {
    @ObservedObject private var settings = UserSettings.shared
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(dynamicTypeSize)
            .preferredColorScheme(preferredColorScheme)
            .environment(\.colorBlindnessType, settings.colorBlindnessType)
            .environment(\.motionReduced, settings.enableReduceMotion)
            // Removed global scaleEffect to prevent entire app from zooming
            .fontWeight(settings.enableBoldText ? .bold : .regular)
            .animation(settings.enableReduceMotion ? .none : .easeInOut(duration: 0.3), value: settings.textSize)
            .animation(settings.enableReduceMotion ? .none : .easeInOut(duration: 0.3), value: settings.enableHighContrast)
            .animation(settings.enableReduceMotion ? .none : .easeInOut(duration: 0.3), value: settings.appTheme)
            .animation(settings.enableReduceMotion ? .none : .easeInOut(duration: 0.3), value: settings.enableBoldText)
    }
    
    private var dynamicTypeSize: DynamicTypeSize {
        if settings.enableLargeText {
            switch settings.textSize {
            case .small:
                return .large
            case .medium:
                return .xLarge
            case .large:
                return .xxLarge
            case .extraLarge:
                return .xxxLarge
            }
        } else {
            switch settings.textSize {
            case .small:
                return .medium
            case .medium:
                return .large
            case .large:
                return .xLarge
            case .extraLarge:
                return .xxLarge
            }
        }
    }
    
    private var preferredColorScheme: ColorScheme? {
        if settings.enableHighContrast {
            return .dark
        }
        
        switch settings.appTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Color Accessibility Extension
extension Color {
    func adjustedForColorBlindness(_ type: ColorBlindnessType) -> Color {
        switch type {
        case .none:
            return self
        case .protanopia:
            return self.protanopiaAdjusted()
        case .deuteranopia:
            return self.deuteranopiaAdjusted()
        case .tritanopia:
            return self.tritanopiaAdjusted()
        }
    }
    
    private func protanopiaAdjusted() -> Color {
        // Protanopia: Red-blind, adjust red colors to be more distinguishable
        switch self {
        case .red:
            return Color.orange
        case .green:
            return Color.cyan
        case .blue:
            return Color.blue
        case .purple:
            return Color.indigo
        case .pink:
            return Color.orange
        default:
            return self
        }
    }
    
    private func deuteranopiaAdjusted() -> Color {
        // Deuteranopia: Green-blind, adjust green colors
        switch self {
        case .green:
            return Color.cyan
        case .red:
            return Color.orange
        case .yellow:
            return Color.orange
        case .purple:
            return Color.indigo
        default:
            return self
        }
    }
    
    private func tritanopiaAdjusted() -> Color {
        // Tritanopia: Blue-blind, adjust blue colors
        switch self {
        case .blue:
            return Color.teal
        case .purple:
            return Color.pink
        case .cyan:
            return Color.green
        case .indigo:
            return Color.purple
        case .yellow:
            return Color.orange
        default:
            return self
        }
    }
}

// MARK: - Accessible Text View
struct AccessibleText: View {
    let text: String
    let style: Font.TextStyle
    @ObservedObject private var settings = UserSettings.shared
    
    init(_ text: String, style: Font.TextStyle = .body) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(.system(style, design: .default, weight: settings.enableBoldText ? .bold : .regular))
            // Removed scaleEffect - now using dynamicTypeSize for text scaling
            .minimumScaleFactor(0.8)
            .lineLimit(settings.enableLargeText ? nil : 3)
            .accessibilityLabel(text)
            .accessibilityAddTraits(settings.enableVoiceOver ? .isHeader : [])
    }
}

// MARK: - Accessible Button
struct AccessibleButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    @ObservedObject private var settings = UserSettings.shared
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            // Add haptic feedback if enabled
            if settings.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            action()
        }) {
            content
                // Removed scaleEffect - now using dynamicTypeSize for text scaling
                .animation(settings.enableReduceMotion ? .none : .easeInOut(duration: 0.2), value: settings.textSize)
        }
        .buttonStyle(AccessibleButtonStyle())
    }
}

struct AccessibleButtonStyle: ButtonStyle {
    @ObservedObject private var settings = UserSettings.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !settings.enableReduceMotion ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(settings.enableReduceMotion ? .none : .easeInOut(duration: 0.1), value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessible Card
struct AccessibleCard<Content: View>: View {
    let content: Content
    @ObservedObject private var settings = UserSettings.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
                .shadow(
                    color: settings.enableHighContrast ? .clear : .black.opacity(0.1),
                    radius: settings.enableReduceMotion ? 0 : 5,
                    x: 0,
                    y: settings.enableReduceMotion ? 0 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    cardBorderColor,
                    lineWidth: settings.enableHighContrast ? 2 : 0
                )
        )
    }
    
    private var cardBackgroundColor: Color {
        if settings.enableHighContrast {
            return Color(.systemBackground).opacity(0.95)
        } else {
            return Color(.secondarySystemBackground)
        }
    }
    
    private var cardBorderColor: Color {
        if settings.enableHighContrast {
            return Color.primary.opacity(0.6)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Motion-Aware Animation
struct MotionAwareAnimation {
    @ObservedObject private static var settings = UserSettings.shared
    
    static func easeInOut(duration: Double = 0.3) -> Animation? {
        settings.enableReduceMotion ? .none : .easeInOut(duration: duration)
    }
    
    static func spring(response: Double = 0.5, dampingFraction: Double = 0.8) -> Animation? {
        settings.enableReduceMotion ? .none : .spring(response: response, dampingFraction: dampingFraction)
    }
    
    static func linear(duration: Double = 1.0) -> Animation? {
        settings.enableReduceMotion ? .none : .linear(duration: duration)
    }
}

// MARK: - Accessible Color View
struct AccessibleColorView<Content: View>: View {
    let content: Content
    let color: Color
    let isBackground: Bool
    @Environment(\.colorBlindnessType) private var colorBlindnessType
    
    var body: some View {
        if isBackground {
            content.background(color.adjustedForColorBlindness(colorBlindnessType))
        } else {
            content.foregroundColor(color.adjustedForColorBlindness(colorBlindnessType))
        }
    }
}

// MARK: - Motion Aware Animation View
struct MotionAwareAnimationView<Content: View, V: Equatable>: View {
    let content: Content
    let animation: Animation?
    let value: V
    @Environment(\.motionReduced) private var motionReduced
    
    var body: some View {
        content.animation(motionReduced ? .none : animation, value: value)
    }
}

// MARK: - View Extensions
extension View {
    func accessibilityEnhanced() -> some View {
        self.modifier(AccessibilityModifier())
    }
    
    func accessibleBackground(_ color: Color = Color(.systemBackground)) -> some View {
        AccessibleColorView(content: self, color: color, isBackground: true)
    }
    
    func accessibleForegroundColor(_ color: Color) -> some View {
        AccessibleColorView(content: self, color: color, isBackground: false)
    }
    
    func motionAwareAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        MotionAwareAnimationView(content: self, animation: animation, value: value)
    }
    
    func accessibleTapGesture(perform action: @escaping () -> Void) -> some View {
        let settings = UserSettings.shared
        return self.onTapGesture {
            if settings.enableHapticFeedback {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            action()
        }
    }
}

// MARK: - Accessible Progress Ring
struct AccessibleProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGSize
    @ObservedObject private var settings = UserSettings.shared
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGSize = CGSize(width: 100, height: 100)) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    backgroundStrokeColor,
                    lineWidth: lineWidth
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressStrokeColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(MotionAwareAnimation.easeInOut(duration: 1.0), value: progress)
        }
        .frame(width: size.width, height: size.height)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
    
    private var backgroundStrokeColor: Color {
        if settings.enableHighContrast {
            return Color.primary.opacity(0.3)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var progressStrokeColor: Color {
        let baseColor = Color.blue.adjustedForColorBlindness(settings.colorBlindnessType)
        if settings.enableHighContrast {
            return baseColor
        } else {
            return baseColor
        }
    }
}
