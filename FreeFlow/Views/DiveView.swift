//
//  DiveView.swift
//  FreeFlow
//
//  The core underwater dive experience
//  Week 1 MVP: Black screen + bubbles + depth meter
//

import SwiftUI

struct DiveView: View {
    @StateObject private var spawner = BubbleSpawner()
    @State private var currentDepth: Float = 0.0
    @State private var maxDepthReached: Float = 0.0
    @State private var bubblesTapped: Int = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var sessionCompleted: Bool = false
    @State private var sessionDuration: TimeInterval = 0

    // DEPTH PENALTY SYSTEM
    private let depthPenalty: Float = 5.0  // meters lost per tap
    private let maxDepth: Float = 40.0     // 40-minute session = 40 meters (v1 locked spec)
    private let sessionTargetDuration: TimeInterval = 2400.0 // 40 minutes (v1 locked spec)

    var body: some View {
        ZStack {
            if sessionCompleted {
                // COMPLETION SCREEN
                CompletionView(
                    maxDepth: maxDepthReached,
                    bubblesTapped: bubblesTapped,
                    sessionDuration: sessionDuration
                )
            } else {
                // ACTIVE DIVE SESSION
                ZStack {
                    // PURE BLACK SCREEN (v1 locked spec)
                    Color.black
                        .ignoresSafeArea()

                    // DEPTH METER (top-right, where battery icon usually is)
                    VStack {
                        HStack {
                            Spacer()
                            Text(String(format: "%.0fm ↓", currentDepth))
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.trailing, 20)
                                .padding(.top, 10)
                        }
                        Spacer()
                    }

                    // BUBBLES (momentarily light up the screen)
                    ForEach(spawner.activeBubbles) { bubble in
                        BubbleView(bubble: bubble)
                            .position(x: bubble.x, y: bubble.y)
                            .onTapGesture {
                                handleBubbleTap(bubble)
                            }
                    }

                    // TIME/DEPTH TRACKING (invisible, just updates depth meter)
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        Color.clear
                            .onAppear {
                                updateDepth()
                            }
                    }
                }
                .offset(x: shakeOffset)
            }
        }
        .onAppear {
            spawner.startSession()
        }
        .onDisappear {
            spawner.stopSession()
        }
    }

    private func updateDepth() {
        let elapsed = spawner.getElapsedTime()
        sessionDuration = elapsed

        // Check if session is complete
        if elapsed >= sessionTargetDuration && !sessionCompleted {
            sessionCompleted = true
            spawner.stopSession()
            return
        }

        // Natural descent: 1m per minute (25 min session = 25m depth)
        let naturalDepth = Float(elapsed / 60.0)

        // Depth increases naturally but is clamped by penalties
        // Only increase if natural depth > current (accounts for taps surfacing you)
        if naturalDepth > currentDepth {
            currentDepth = min(naturalDepth, maxDepth)
        }

        // Track max depth reached
        if currentDepth > maxDepthReached {
            maxDepthReached = currentDepth
        }
    }

    private func handleBubbleTap(_ bubble: Bubble) {
        spawner.tapBubble(bubble)
        bubblesTapped += 1

        // DEPTH PENALTY: -5m per tap
        currentDepth = max(0, currentDepth - depthPenalty)

        // Visual feedback: screen shake
        withAnimation(.easeInOut(duration: 0.1)) {
            shakeOffset = -10
        }
        withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
            shakeOffset = 10
        }
        withAnimation(.easeInOut(duration: 0.1).delay(0.2)) {
            shakeOffset = 0
        }
    }

}

struct BubbleView: View {
    let bubble: Bubble

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.6),
                        Color.cyan.opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 5,
                    endRadius: 30
                )
            )
            .frame(width: 60, height: 60)
            .shadow(color: .cyan.opacity(0.5), radius: 20)
            // Bubble lights up the screen (glow effect)
    }
}

struct CompletionView: View {
    let maxDepth: Float
    let bubblesTapped: Int
    let sessionDuration: TimeInterval

    var body: some View {
        ZStack {
            // Background color based on achievement
            completionColor()
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // COMPLETION TIER
                VStack(spacing: 10) {
                    Text(completionTier())
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(tierMessage())
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // STATS
                VStack(spacing: 20) {
                    StatRow(label: "Max Depth", value: String(format: "%.0fm", maxDepth), color: .cyan)
                    StatRow(label: "Time in Flow", value: flowTime(), color: .blue)
                    StatRow(label: "Bubbles Tapped", value: "\(bubblesTapped)", color: bubblesTapped == 0 ? .green : .orange)
                    StatRow(label: "Real Time", value: formatTime(sessionDuration), color: .white.opacity(0.6))
                }
                .padding(.horizontal, 40)

                Spacer()

                // COMPLETION MESSAGE
                Text("Session Complete")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
    }

    private func completionTier() -> String {
        switch maxDepth {
        case 0..<10:
            return "Surface"
        case 10..<20:
            return "Shallow"
        case 20..<25:
            return "Deep"
        case 25...:
            return "The Abyss"
        default:
            return "Surface"
        }
    }

    private func tierMessage() -> String {
        switch maxDepth {
        case 0..<10:
            return "You stayed near the surface.\nNext time, dive deeper."
        case 10..<20:
            return "Good dive.\nThe deep awaits."
        case 20..<25:
            return "Impressive depth control.\nAlmost to the abyss."
        case 25...:
            return "Perfect dive.\nYou reached the abyss."
        default:
            return ""
        }
    }

    private func completionColor() -> Color {
        // Background color reflects achievement
        switch maxDepth {
        case 0..<10:
            return Color(red: 0.25, green: 0.88, blue: 0.82) // Turquoise (surface)
        case 10..<20:
            return Color(red: 0, green: 0.28, blue: 0.67) // Deep blue
        case 20..<25:
            return Color(red: 0, green: 0, blue: 0.5) // Navy
        case 25...:
            return Color.black // Abyss
        default:
            return Color.black
        }
    }

    private func flowTime() -> String {
        // Flow time = depth multiplier × real time
        // Deeper you go, more "flow time" you accumulated
        let multiplier = maxDepth / 25.0 // 0-1 range
        let flowSeconds = sessionDuration * Double(multiplier)
        return formatTime(flowSeconds)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}
