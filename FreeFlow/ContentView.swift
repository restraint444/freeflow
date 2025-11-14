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
    @State private var spamMode = false

    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(
                    onStartDive: {
                        showOnboarding = false
                        isDiving = true
                        spamMode = false
                    },
                    onStartSpam: {
                        showOnboarding = false
                        isDiving = true
                        spamMode = true
                    }
                )
            } else if isDiving {
                DiveView(spamMode: spamMode)
            }
        }
    }
}

#Preview {
    ContentView()
}
