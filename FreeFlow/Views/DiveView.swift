//
//  DiveView.swift
//  FreeFlow - Hungary's Deep Dive Game
//
//  Pure black screen, 25m descent, clam collection
//

import SwiftUI

struct DiveView: View {
    // GAME STATE
    @State private var depthRemaining: Int = 25  // 25m → 0m
    @State private var bubblesRemaining: Int = 5  // 5 lives
    @State private var clamsCollected: Int = 0
    @State private var timeInFlow: TimeInterval = 0
    @State private var bubblesIgnored: Int = 0

    // NOTIFICATION SYSTEM
    @State private var showNotification: Bool = false
    @State private var notificationText: String = ""
    @State private var screenLit: Bool = false

    // SESSION STATE
    @State private var sessionActive: Bool = true
    @State private var isPaused: Bool = false
    @State private var sessionComplete: Bool = false

    // HUNGARY MASCOT (disabled for now)
    // @State private var hungaryMessage: String = ""
    // @State private var showHungary: Bool = false

    // TIMERS
    @State private var gameTimer: Timer? = nil
    @State private var notificationTimer: Timer? = nil

    var body: some View {
        ZStack {
            // PURE BLACK BACKGROUND
            Color.black
                .ignoresSafeArea()

            // SCREEN LIGHTING (only when notification appears)
            if screenLit {
                Color.white
                    .opacity(0.03)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: screenLit)
            }

            // GAME COMPLETE SCREEN
            if sessionComplete {
                CompletionView(
                    timeInFlow: timeInFlow,
                    bubblesIgnored: bubblesIgnored,
                    clamsCollected: clamsCollected,
                    depthReached: 25 - depthRemaining
                )
            } else {
                // ACTIVE DIVE SESSION
                VStack {
                    // TOP HUD
                    HStack {
                        // LEFT: Bubbles Remaining
                        HStack(spacing: 4) {
                            ForEach(0..<bubblesRemaining, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                            }
                            ForEach(0..<(5 - bubblesRemaining), id: \.self) { _ in
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding(.leading, 20)

                        Spacer()

                        // RIGHT: Depth Remaining
                        Text("\(depthRemaining)m")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.trailing, 20)
                    }
                    .padding(.top, 10)

                    Spacer()

                    // PAUSE BUTTON (camera icon aesthetic)
                    if !isPaused {
                        Button(action: pauseSession) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.3))
                                .padding()
                        }
                        .padding(.bottom, 40)
                    } else {
                        VStack(spacing: 20) {
                            Text("PAUSED")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Button(action: resumeSession) {
                                Text("Resume Dive")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                            }

                            Text("Exit will reset progress")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.bottom, 40)
                    }
                }

                // NOTIFICATION BANNER (slides down from top)
                if showNotification {
                    VStack {
                        NotificationBanner(
                            text: notificationText,
                            onTap: {
                                handleNotificationTap()
                            }
                        )
                        .padding(.top, 50)

                        Spacer()
                    }
                    .transition(.move(edge: .top))
                    .animation(.easeOut(duration: 0.3), value: showNotification)
                }
            }
        }
        .onAppear {
            startDiveSession()
        }
        .onDisappear {
            stopSession()
        }
    }

    // MARK: - Game Logic

    func startDiveSession() {
        sessionActive = true

        // Main game timer (1 meter per second descent)
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !isPaused && sessionActive {
                timeInFlow += 1

                // Descend 1 meter per second
                if depthRemaining > 0 {
                    depthRemaining -= 1
                }

                // Session complete when reaching 0m
                if depthRemaining == 0 {
                    completeSession()
                }
            }
        }

        // Notification spawner (random intervals)
        scheduleNextNotification()
    }

    func scheduleNextNotification() {
        let randomDelay = Double.random(in: 3...8)  // Random 3-8 seconds

        notificationTimer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) { _ in
            if !isPaused && sessionActive && !sessionComplete {
                spawnNotification()
            }
        }
    }

    func spawnNotification() {
        // Light up screen
        screenLit = true

        // Show banner
        notificationText = generateFakeNotificationText()
        showNotification = true

        // Auto-dismiss after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            dismissNotification()

            // Schedule next notification
            scheduleNextNotification()
        }
    }

    func generateFakeNotificationText() -> String {
        let templates = [
            "Instagram: Someone liked your photo",
            "Messages: Hey, are you free?",
            "Twitter: New notification",
            "Reddit: Trending in your feed",
            "Discord: 3 new messages"
        ]
        return templates.randomElement() ?? "Notification"
    }

    func handleNotificationTap() {
        // Lose one bubble
        if bubblesRemaining > 0 {
            bubblesRemaining -= 1
        }

        // Check if game over (all bubbles used)
        if bubblesRemaining == 0 {
            completeSession()
        }

        dismissNotification()
    }

    func dismissNotification() {
        showNotification = false
        screenLit = false
        bubblesIgnored += 1  // Count as ignored if auto-dismissed
    }

    func pauseSession() {
        isPaused = true
        gameTimer?.invalidate()
        notificationTimer?.invalidate()
    }

    func resumeSession() {
        isPaused = false
        startDiveSession()
    }

    func completeSession() {
        sessionActive = false
        sessionComplete = true
        gameTimer?.invalidate()
        notificationTimer?.invalidate()
    }

    func stopSession() {
        gameTimer?.invalidate()
        notificationTimer?.invalidate()
    }
}

// MARK: - Notification Banner View
struct NotificationBanner: View {
    let text: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "app.fill")
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)

                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.9))
                    .shadow(color: .white.opacity(0.3), radius: 10)
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Completion Screen
struct CompletionView: View {
    let timeInFlow: TimeInterval
    let bubblesIgnored: Int
    let clamsCollected: Int
    let depthReached: Int

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("DIVE COMPLETE")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                VStack(spacing: 20) {
                    StatRow(label: "Time in Flow", value: formatTime(timeInFlow))
                    StatRow(label: "Bubbles Ignored", value: "\(bubblesIgnored)")
                    StatRow(label: "Clams Collected", value: "\(clamsCollected)")
                    StatRow(label: "Depth Reached", value: "\(depthReached)m")
                }
                .padding(.horizontal, 40)
            }
        }
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}
