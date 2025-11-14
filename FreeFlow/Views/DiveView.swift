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
    let spamMode: Bool // Testing mode: 5 notifications/sec

    // TIMER
    @State private var notificationTimer: Timer? = nil
    @State private var spamBurstCount: Int = 0

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

            // LOCK SCREEN NOTIFICATIONS - Stacked exactly like iOS
            VStack {
                Spacer()

                ZStack {
                    // Stack all notifications - newest appears on top (in front)
                    ForEach(Array(activeNotifications.enumerated().reversed()), id: \.element.id) { index, notification in
                        LockScreenNotification(
                            isNew: notification.isNew,
                            onTap: {
                                dismissNotification(notification)
                            }
                        )
                        .scaleEffect(1.0 - (CGFloat(index) * 0.05)) // Slight scale for depth
                        .offset(y: CGFloat(index * 8)) // Minimal offset for stacking
                        .zIndex(Double(activeNotifications.count - index)) // Newest has highest z-index (on top)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 120) // Above flashlight/camera area
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: activeNotifications.count)

            // FLASHLIGHT & CAMERA BUTTON PLACEHOLDERS (bottom corners)
            VStack {
                Spacer()

                HStack {
                    // Flashlight (left)
                    Image(systemName: "flashlight.off.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 40)

                    Spacer()

                    // Camera (right)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.trailing, 40)
                }
                .padding(.bottom, 40)
            }
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
        if spamMode {
            // SPAM MODE: 5 notifications in 1 second, then 7 second delay
            if spamBurstCount < 5 {
                // Burst: 0.2 second intervals (5 in 1 second)
                notificationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                    if sessionActive {
                        spawnNotification()
                        spamBurstCount += 1
                        scheduleNextNotification()
                    }
                }
            } else {
                // Delay: 7 seconds before next burst
                notificationTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: false) { _ in
                    if sessionActive {
                        spamBurstCount = 0
                        scheduleNextNotification()
                    }
                }
            }
        } else {
            // NORMAL MODE: 3 second interval
            notificationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                if sessionActive {
                    spawnNotification()
                }
            }
        }
    }

    func spawnNotification() {
        // Light up screen
        screenLit = true

        // Add notification to stack (starts grey)
        var notification = NotificationItem()
        activeNotifications.append(notification)

        // Animate grey to white after 0.3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let index = activeNotifications.firstIndex(where: { $0.id == notification.id }) {
                activeNotifications[index].isNew = false
            }
        }

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
    var isNew: Bool = true // For grey-to-white animation
}

// MARK: - Lock Screen Notification View
struct LockScreenNotification: View {
    let isNew: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            // Bubble effect: light blue tinge, semi-transparent, gradient
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            isNew ? Color.gray.opacity(0.75) : Color(red: 0.85, green: 0.95, blue: 1.0).opacity(0.9),
                            isNew ? Color.gray.opacity(0.65) : Color(red: 0.75, green: 0.9, blue: 1.0).opacity(0.85)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 80)
                .frame(maxWidth: 360)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.cyan.opacity(0.3), radius: 8)
                .shadow(color: .black.opacity(0.2), radius: 15)
                .animation(.easeInOut(duration: 0.3), value: isNew)
        }
    }
}
