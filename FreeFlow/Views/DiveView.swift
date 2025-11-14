//
//  DiveView.swift
//  FreeFlow - Hungary's Deep Dive Game
//
//  Pure black screen, 25m descent, clam collection
//

import SwiftUI

struct DiveView: View {
    // NOTIFICATION SYSTEM
    @State private var showNotification: Bool = false
    @State private var screenLit: Bool = false

    // SESSION STATE
    @State private var sessionActive: Bool = true
    @State private var isPaused: Bool = false

    // TIMER
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

            // NOTIFICATION BANNER - SLIDES DOWN FROM TOP EXACTLY LIKE iOS
            VStack(spacing: 0) {
                if showNotification {
                    NotificationBanner(
                        onTap: {
                            handleNotificationTap()
                        }
                    )
                    .transition(.move(edge: .top))
                }

                Spacer()
            }
            .ignoresSafeArea()
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showNotification)
        }
        .onAppear {
            startNotificationDemo()
        }
        .onDisappear {
            stopSession()
        }
    }

    // MARK: - Notification Logic

    func startNotificationDemo() {
        sessionActive = true
        scheduleNextNotification()
    }

    func scheduleNextNotification() {
        // Fixed 3 second interval for testing animation
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if !isPaused && sessionActive {
                spawnNotification()
            }
        }
    }

    func spawnNotification() {
        // Light up screen
        screenLit = true

        // Show banner with smooth iOS animation
        showNotification = true

        // Auto-dismiss after exactly 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            dismissNotification()

            // Schedule next notification
            scheduleNextNotification()
        }
    }

    func handleNotificationTap() {
        dismissNotification()
    }

    func dismissNotification() {
        showNotification = false
        screenLit = false
    }

    func stopSession() {
        notificationTimer?.invalidate()
    }
}

// MARK: - Notification Banner View
struct NotificationBanner: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            // Empty banner - pure white, positioned right below status bar
            Rectangle()
                .fill(Color.white)
                .frame(height: 90)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.3), radius: 15)
                .padding(.horizontal, 8)
                .padding(.top, 54)
        }
    }
}
