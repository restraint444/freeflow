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
    @State private var bubbleFragments: [BubbleFragment] = []
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
                            offsetX: notification.offsetX,
                            offsetY: notification.offsetY,
                            onTap: {
                                dismissNotification(notification)
                            }
                        )
                        .scaleEffect(1.0 - (CGFloat(index) * 0.05)) // Slight scale for depth
                        .offset(y: CGFloat(index * 8)) // Minimal offset for stacking
                        .zIndex(Double(activeNotifications.count - index)) // Newest has highest z-index (on top)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.01).combined(with: .opacity)
                            )
                        )
                    }
                }
                .padding(.bottom, 120) // Above flashlight/camera area
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: activeNotifications.count)

            // BUBBLE FRAGMENTS (floating upward after pop)
            ForEach(bubbleFragments) { fragment in
                BubbleFragmentView(fragment: fragment)
            }

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

        // Add notification - single unified animation (iOS style)
        let notification = NotificationItem(isNew: false) // Spawn with final state

        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            activeNotifications.append(notification)
        }

        // Slow floating drift - very tight bounding box so stacked notifications stay close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let driftX = CGFloat.random(in: -10...10) // Tight drift range
            let driftY = CGFloat.random(in: -10...10) // Tight drift range

            withAnimation(.easeInOut(duration: 4.7)) { // Very slow, smooth drift
                if let index = activeNotifications.firstIndex(where: { $0.id == notification.id }) {
                    activeNotifications[index].offsetX = driftX
                    activeNotifications[index].offsetY = driftY
                }
            }
        }

        // Spawn small groups of escaping bubbles gracefully (not individual bubbles)
        let notificationId = notification.id
        let groupSpawnTimes: [Double] = [1.5, 3.0, 4.0] // Graceful timing - 3 groups total

        for spawnTime in groupSpawnTimes {
            DispatchQueue.main.asyncAfter(deadline: .now() + spawnTime) {
                // Only spawn if notification still exists (not dismissed early)
                if self.activeNotifications.contains(where: { $0.id == notificationId }) {
                    // Spawn small cluster of 2-3 bubbles together
                    let clusterSize = Int.random(in: 2...3)
                    for _ in 0..<clusterSize {
                        self.spawnEscapeBubble()
                    }
                }
            }
        }

        // Auto-dismiss after exactly 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if let notification = activeNotifications.first {
                dismissNotification(notification)
            }

            // Only schedule next in normal mode (spam mode handles its own scheduling)
            if !spamMode {
                scheduleNextNotification()
            }
        }
    }

    func spawnEscapeBubble() {
        // Spawn small bubble from notification area that floats upward slowly
        let baseY = UIScreen.main.bounds.height * 0.69

        let fragment = BubbleFragment(
            x: UIScreen.main.bounds.width / 2 + CGFloat.random(in: -160...160), // Much wider spread
            y: baseY + CGFloat.random(in: -50...50), // Much taller spread
            size: CGFloat.random(in: 8...16), // Small escaping bubbles
            offsetX: CGFloat.random(in: -20...20), // Gentle drift
            offsetY: CGFloat.random(in: (-80)...(-50)) // Slow upward float
        )
        bubbleFragments.append(fragment)

        // Remove after floating away (slower than burst fragments)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            bubbleFragments.removeAll { $0.id == fragment.id }
        }
    }

    func dismissNotification(_ notification: NotificationItem) {
        // Controlled bubble burst - feels natural and smooth
        let fragmentCount = 8 // Clean burst with less overlap
        // Position at 69% down the screen (above the notification at ~85%)
        let baseY = UIScreen.main.bounds.height * 0.69

        for i in 0..<fragmentCount {
            // Vary size dramatically - 30% large (20-32), 40% medium (12-20), 30% tiny (6-12)
            let randomValue = Double.random(in: 0...1)
            let size: CGFloat
            if randomValue < 0.3 {
                size = CGFloat.random(in: 20...32) // Large bubbles
            } else if randomValue < 0.7 {
                size = CGFloat.random(in: 12...20) // Medium bubbles
            } else {
                size = CGFloat.random(in: 6...12) // Tiny bubbles
            }

            // Spawn spread - covers ENTIRE notification bubble area (all corners)
            let horizontalSpread = CGFloat.random(in: -180...180) // Full 360px width
            let verticalSpread = CGFloat.random(in: -40...40) // Full 80px height

            // Vary upward velocity - faster rise for smaller bubbles (oxygen thinning)
            let upwardDistance = size < 15 ? CGFloat.random(in: (-140)...(-100)) : CGFloat.random(in: (-80)...(-50))

            // RANDOM drift - reduced to prevent off-screen floating
            let randomDriftX = CGFloat.random(in: -30...30)

            let fragment = BubbleFragment(
                x: UIScreen.main.bounds.width / 2 + horizontalSpread,
                y: baseY + verticalSpread, // Spawn anywhere around the notification bubble
                size: size,
                offsetX: randomDriftX, // Random drift independent of spawn position
                offsetY: upwardDistance
            )

            // Stagger spawn slightly for stream effect (0-0.1 second delay)
            let delay = Double(i) * 0.005
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.bubbleFragments.append(fragment)
            }

            // Auto-remove fragment after animation completes
            let removalDelay = 0.8 + delay
            DispatchQueue.main.asyncAfter(deadline: .now() + removalDelay) {
                bubbleFragments.removeAll { $0.id == fragment.id }
            }
        }

        // Remove notification from stack
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            activeNotifications.removeAll { $0.id == notification.id }
        }

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
    var isNew: Bool
    var offsetX: CGFloat = 0.0 // Slow floating drift
    var offsetY: CGFloat = 0.0 // Slow floating drift

    init(isNew: Bool = true) {
        self.isNew = isNew
    }
}

// MARK: - Bubble Fragment Model
struct BubbleFragment: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let offsetX: CGFloat // Random horizontal drift
    let offsetY: CGFloat // Random upward float distance
}

// MARK: - Lock Screen Notification View
struct LockScreenNotification: View {
    let isNew: Bool
    let offsetX: CGFloat
    let offsetY: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            // Bubble: translucent blue gradient - single final state
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.85, green: 0.95, blue: 1.0).opacity(0.9),
                            Color(red: 0.75, green: 0.9, blue: 1.0).opacity(0.85)
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
                .offset(x: offsetX, y: offsetY) // Slow floating drift
        }
    }
}

// MARK: - Bubble Fragment View (Self-animating)
struct BubbleFragmentView: View {
    let fragment: BubbleFragment
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            // Main bubble with soft 3D gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.9, green: 0.97, blue: 1.0).opacity(0.95), // Lighter center
                            Color(red: 0.8, green: 0.92, blue: 1.0).opacity(0.88), // Mid
                            Color(red: 0.7, green: 0.88, blue: 1.0).opacity(0.82)  // Darker edge
                        ]),
                        center: .init(x: 0.4, y: 0.35), // Off-center highlight for 3D
                        startRadius: 0,
                        endRadius: fragment.size * 0.6
                    )
                )
                .frame(width: fragment.size, height: fragment.size)

            // Inner highlight for glossy 3D effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0)
                        ]),
                        center: .init(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: fragment.size * 0.25
                    )
                )
                .frame(width: fragment.size * 0.5, height: fragment.size * 0.5)
                .offset(x: -fragment.size * 0.15, y: -fragment.size * 0.15)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
        )
        .shadow(color: Color.cyan.opacity(0.4), radius: fragment.size * 0.3) // Glow
        .shadow(color: .black.opacity(0.25), radius: fragment.size * 0.4) // Depth shadow
        .position(x: fragment.x, y: fragment.y)
        .offset(x: xOffset, y: yOffset)
        .opacity(opacity)
        .onAppear {
            // Trigger upward float + fade animation immediately
            withAnimation(.easeOut(duration: 0.8)) {
                yOffset = fragment.offsetY
                xOffset = fragment.offsetX
                opacity = 0
            }
        }
    }
}
