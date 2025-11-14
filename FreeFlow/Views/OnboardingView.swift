//
//  OnboardingView.swift
//  FreeFlow
//
//  Week 1 MVP: Simple start button
//  Future: 5-screen onboarding (Annoying → Confusing → Magical)
//

import SwiftUI

struct OnboardingView: View {
    let onStartDive: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Text("FreeFlow")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)

                Text("Allergy shot for your attention")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.cyan.opacity(0.7))

                Spacer()

                VStack(spacing: 20) {
                    Text("Week 1 MVP")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.cyan.opacity(0.5))

                    Text("40-minute dive")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan.opacity(0.8))

                    Text("0m → 40m depth")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan.opacity(0.8))

                    Text("Exponential decay bubble spawn")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan.opacity(0.8))
                }

                Spacer()

                Button(action: onStartDive) {
                    Text("Start Dive")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.cyan)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}
