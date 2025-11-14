//
//  BubbleSpawner.swift
//  FreeFlow
//
//  Core exponential decay notification spawn system
//  Scientific basis: Extinction learning through graduated exposure
//  Week 1 MVP: Fake bubbles only (no real notifications)
//

import Foundation
import Combine
import UIKit

class BubbleSpawner: ObservableObject {
    @Published var activeBubbles: [Bubble] = []

    private var timer: AnyCancellable?
    private var sessionStartTime: Date?
    private let sessionDuration: TimeInterval = 2400.0 // 40 minutes (v1 locked spec)

    // EXPONENTIAL DECAY CONSTANTS
    // Based on extinction learning research: high initial exposure → rapid habituation
    private let startInterval: TimeInterval = 0.2  // 5 bubbles/second (OVERWHELMING)
    private let endInterval: TimeInterval = 120.0  // 1 bubble/2min (PEACEFUL)
    private let decayConstant: Double = 4.0        // Controls curve steepness

    func startSession() {
        sessionStartTime = Date()
        scheduleNextBubble()
    }

    func stopSession() {
        timer?.cancel()
        timer = nil
        activeBubbles.removeAll()
    }

    private func scheduleNextBubble() {
        guard let startTime = sessionStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)

        // Session complete
        if elapsed >= sessionDuration {
            stopSession()
            return
        }

        let interval = calculateSpawnInterval(elapsedSeconds: elapsed)

        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.spawnBubble()
                self?.scheduleNextBubble()
            }
    }

    /// EXPONENTIAL DECAY FORMULA
    /// Maps 0-40min session to bubble spawn intervals
    ///
    /// Visual progression:
    /// 0-5 min:   5 bubbles/sec (overwhelming, aversive)
    /// 5-10 min:  2 bubbles/sec (intense)
    /// 10-20 min: 1 bubble/sec (manageable)
    /// 20-30 min: 1 bubble/30sec (easy)
    /// 30-40 min: 1 bubble/2min (peaceful)
    private func calculateSpawnInterval(elapsedSeconds: Double) -> TimeInterval {
        let t = elapsedSeconds / sessionDuration
        let interval = startInterval + (endInterval - startInterval) * (1 - exp(-decayConstant * t))
        return interval
    }

    private func spawnBubble() {
        let bubble = Bubble(
            id: UUID(),
            x: Double.random(in: 50...UIScreen.main.bounds.width - 50),
            y: UIScreen.main.bounds.height + 50
        )
        activeBubbles.append(bubble)

        // Auto-remove after 5 seconds (bubble floats off screen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.removeBubble(bubble)
        }
    }

    func tapBubble(_ bubble: Bubble) {
        // Week 1 MVP: Just remove bubble and increment counter
        // Future: Decrease depth, show warning, track honesty
        removeBubble(bubble)
    }

    private func removeBubble(_ bubble: Bubble) {
        activeBubbles.removeAll { $0.id == bubble.id }
    }

    func getElapsedTime() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
}
