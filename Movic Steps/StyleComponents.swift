//
//  StyleComponents.swift
//  Movic Steps
//
//  Created by Luc Sun on 9/19/25.
//

import SwiftUI

// MARK: - Modern Card Styles
struct GlassmorphismCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

struct NeumorphismCard<Content: View>: View {
    let content: Content
    let isPressed: Bool
    
    init(isPressed: Bool = false, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isPressed = isPressed
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(isPressed ? 0.1 : 0.2), radius: isPressed ? 5 : 15, x: isPressed ? 2 : 8, y: isPressed ? 2 : 8)
                    .shadow(color: .white.opacity(isPressed ? 0.5 : 0.7), radius: isPressed ? 5 : 15, x: isPressed ? -2 : -8, y: isPressed ? -2 : -8)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

struct GradientCard<Content: View>: View {
    let content: Content
    let gradient: LinearGradient
    
    init(gradient: LinearGradient, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.gradient = gradient
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(gradient)
                    .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
            )
    }
}

// MARK: - Animated Progress Ring
struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let colors: [Color]
    @State private var animatedProgress: Double = 0
    
    init(progress: Double, lineWidth: CGFloat = 12, size: CGFloat = 200, colors: [Color] = [.blue, .purple, .pink]) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.colors = colors
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.5), value: animatedProgress)
            
            // Glow effect
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: colors.map { $0.opacity(0.3) },
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth * 1.5, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .blur(radius: 3)
                .animation(.easeInOut(duration: 1.5), value: animatedProgress)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    @State private var isPressed = false
    
    init(icon: String, color: Color = .blue, action: @escaping () -> Void) {
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: color.opacity(0.4), radius: isPressed ? 5 : 15, x: 0, y: isPressed ? 2 : 8)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action if needed
        }
    }
}

// MARK: - Metric Display Card
struct ModernMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    @State private var isVisible = false
    @StateObject private var userSettings = UserSettings.shared
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        func color(for userSettings: UserSettings) -> Color {
            switch self {
            case .up: return .green.adjustedForColorBlindness(userSettings.colorBlindnessType)
            case .down: return .red.adjustedForColorBlindness(userSettings.colorBlindnessType)
            case .stable: return .gray.adjustedForColorBlindness(userSettings.colorBlindnessType)
            }
        }
    }
    
    var body: some View {
        GlassmorphismCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color.adjustedForColorBlindness(userSettings.colorBlindnessType))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(color.adjustedForColorBlindness(userSettings.colorBlindnessType).opacity(0.1))
                        )
                    
                    Spacer()
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.caption)
                            .foregroundColor(trend.color(for: userSettings))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 120) // Fixed height for all cards
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Animated Counter
struct AnimatedCounter: View {
    let value: Int
    let duration: Double
    @State private var displayValue: Int = 0
    
    init(value: Int, duration: Double = 1.0) {
        self.value = value
        self.duration = duration
    }
    
    var body: some View {
        Text("\(displayValue)")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .onAppear {
                animateCounter()
            }
            .onChange(of: value) { _ in
                animateCounter()
            }
    }
    
    private func animateCounter() {
        let steps = max(1, value / 100) // Animate in steps
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Double(i) / Double(steps)
                displayValue = Int(Double(value) * progress)
            }
        }
    }
}

// MARK: - Pulse Animation
struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    let color: Color
    let intensity: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .foregroundColor(color.opacity(isPulsing ? intensity : 0))
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseEffect(color: Color = .blue, intensity: Double = 0.3) -> some View {
        modifier(PulseEffect(color: color, intensity: intensity))
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: -200 + phase * 400)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: phase)
            )
            .clipped()
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Custom Colors
extension Color {
    // Accessibility-aware gradient functions
    static func primaryGradient(for colorBlindnessType: ColorBlindnessType = .none) -> LinearGradient {
        let adjustedBlue = Color.blue.adjustedForColorBlindness(colorBlindnessType)
        let adjustedPurple = Color.purple.adjustedForColorBlindness(colorBlindnessType)
        
        return LinearGradient(
            colors: [adjustedBlue, adjustedPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func successGradient(for colorBlindnessType: ColorBlindnessType = .none) -> LinearGradient {
        let adjustedGreen = Color.green.adjustedForColorBlindness(colorBlindnessType)
        let adjustedMint = Color.mint.adjustedForColorBlindness(colorBlindnessType)
        
        return LinearGradient(
            colors: [adjustedGreen, adjustedMint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func warningGradient(for colorBlindnessType: ColorBlindnessType = .none) -> LinearGradient {
        let adjustedOrange = Color.orange.adjustedForColorBlindness(colorBlindnessType)
        let adjustedYellow = Color.yellow.adjustedForColorBlindness(colorBlindnessType)
        
        return LinearGradient(
            colors: [adjustedOrange, adjustedYellow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func accentGradient(for colorBlindnessType: ColorBlindnessType = .none) -> LinearGradient {
        let adjustedPink = Color.pink.adjustedForColorBlindness(colorBlindnessType)
        let adjustedPurple = Color.purple.adjustedForColorBlindness(colorBlindnessType)
        let adjustedBlue = Color.blue.adjustedForColorBlindness(colorBlindnessType)
        
        return LinearGradient(
            colors: [adjustedPink, adjustedPurple, adjustedBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Backward compatibility - default gradients
    static let primaryGradient = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [.green, .mint],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [.orange, .yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [.pink, .purple, .blue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
