//
//  Bubble.swift
//  FreeFlow
//
//  Represents a single notification bubble in the underwater environment
//

import Foundation

struct Bubble: Identifiable {
    let id: UUID
    var x: Double  // Horizontal position
    var y: Double  // Vertical position (starts at bottom, floats up)

    var createdAt: Date = Date()
}
