import SwiftUI

// MARK: - Loading Screen

struct LoadingScreen: View {
    @State private var progress: Double = 0.0
    @State private var loadingText = "Initializing..."
    @State private var isAnimating = false
    @ObservedObject private var settings = UserSettings.shared
    
    let loadingSteps = [
        "Initializing...",
        "Loading Health Data...",
        "Setting up Notifications...",
        "Preparing Interface...",
        "Almost Ready...",
        "Done!",
        "Patching you in..."
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                Spacer()
                
                // App Logo
                VStack(spacing: 20) {
                    Group {
                        if let _ = UIImage(named: "Movic-Steps") {
                            Image("Movic-Steps")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                        } else {
                            Image(systemName: "figure.walk.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                    }
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .motionAwareAnimation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    
                    AccessibleText("Movic Steps", style: .largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Loading Section
                VStack(spacing: 30) {
                    // Loading text
                    AccessibleText(loadingText, style: .title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Progress bar
                    VStack(spacing: 15) {
                        HStack {
                            Spacer()
                            AccessibleText("\(Int(progress * 100))%", style: .headline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, UIScreen.main.bounds.width * 0.7 * progress), height: 8)
                                .motionAwareAnimation(.easeOut(duration: 0.3), value: progress)
                        }
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                    }
                    
                    // Loading dots animation
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 8, height: 8)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .motionAwareAnimation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                    value: isAnimating
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Footer
                AccessibleText("Your Health Journey Starts Here", style: .subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startLoadingAnimation()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading Movic Steps app")
        .accessibilityValue("Progress: \(Int(progress * 100)) percent, \(loadingText)")
    }
    
    private func startLoadingAnimation() {
        isAnimating = true
        
        // Simulate loading progress
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            if progress < 1.0 {
                withAnimation(.easeOut(duration: 0.5)) {
                    progress += 0.2
                    
                    // Update loading text based on progress
                    let stepIndex = min(Int(progress * Double(loadingSteps.count)), loadingSteps.count - 1)
                    loadingText = loadingSteps[stepIndex]
                }
            } else {
                loadingText = "Ready!"
                timer.invalidate()
            }
        }
    }
}

// MARK: - Loading State Manager
class LoadingStateManager: ObservableObject {
    @Published var isLoading = true
}

#Preview {
    LoadingScreen()
}
