//
//  DiveView.swift
//  FreeFlow
//
//  Lock screen notification demo - stacking bubbles
//

import SwiftUI

struct DiveView: View {
    // NOTIFICATION SYSTEM - Lock screen style with stacking
    @State private var activeNotifications: [NotificationItem] = []
    @State private var screenLit: Bool = false

    // SESSION STATE
    @State private var sessionActive: Bool = true

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

            // LOCK SCREEN NOTIFICATIONS - Bottom area, stacked
            VStack {
                Spacer()

                // Stack notifications from bottom up
                ForEach(Array(activeNotifications.enumerated()), id: \.element.id) { index, notification in
                    LockScreenNotification(
                        onTap: {
                            dismissNotification(notification)
                        }
                    )
                    .offset(y: CGFloat(-index * 10)) // Stack offset
                    .zIndex(Double(activeNotifications.count - index))
                    .transition(.scale.combined(with: .opacity))
                }
                .padding(.bottom, 120) // Above flashlight/camera area
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: activeNotifications.count)
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
        // Fixed 3 second interval for testing
        notificationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if sessionActive {
                spawnNotification()
            }
        }
    }

    func spawnNotification() {
        // Light up screen
        screenLit = true

        // Add notification to stack
        let notification = NotificationItem()
        activeNotifications.append(notification)

        // Auto-dismiss after exactly 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            dismissNotification(notification)

            // Schedule next notification
            scheduleNextNotification()
        }
    }

    func dismissNotification(_ notification: NotificationItem) {
        activeNotifications.removeAll { $0.id == notification.id }

        // Turn off screen light if no notifications
        if activeNotifications.isEmpty {
            screenLit = false
        }
    }

    func stopSession() {
        notificationTimer?.invalidate()
    }
}

// MARK: - Notification Model
struct NotificationItem: Identifiable {
    let id = UUID()
    let createdAt = Date()
}

// MARK: - Lock Screen Notification View
struct LockScreenNotification: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            // Lock screen notification style - pure white rounded rect
            Rectangle()
                .fill(Color.white)
                .frame(height: 80)
                .frame(maxWidth: 360)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.3), radius: 10)
        }
    }
}
