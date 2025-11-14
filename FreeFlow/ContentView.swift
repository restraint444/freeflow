//
//  ContentView.swift
//  FreeFlow
//
//  Root navigation view
//

import SwiftUI

struct ContentView: View {
    @State private var showOnboarding = true
    @State private var isDiving = false

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(onStartDive: {
                    showOnboarding = false
                    isDiving = true
                })
            } else if isDiving {
                DiveView()
            }
        }
    }
}

#Preview {
    ContentView()
}
