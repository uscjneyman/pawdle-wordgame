import SwiftUI

/// Full-screen overlay that points out key UI features for first-time users.
struct OnboardingOverlayView: View {
    var onDismiss: () -> Void

    @State private var step = 0
    private let totalSteps = 4

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { advance() }

            // Step content
            Group {
                switch step {
                case 0: instructionsCallout
                case 1: profileCallout
                case 2: swipeCallout
                case 3: startGameCallout
                default: EmptyView()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .animation(.easeInOut(duration: 0.25), value: step)

            // Tap to continue
            VStack {
                Spacer()
                Text("Tap anywhere to continue")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 40)
            }
        }
    }

    private func advance() {
        if step < totalSteps - 1 {
            withAnimation { step += 1 }
        } else {
            onDismiss()
        }
    }

    // MARK: - Step 0: Instructions (top-left)

    private var instructionsCallout: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                        .padding(.leading, 8)

                    calloutBubble(
                        text: "Tap here to see\nHow to Play instructions",
                        systemImage: "questionmark.circle"
                    )
                }
                .padding(.top, 52)
                .padding(.leading, 12)
                Spacer()
            }
            Spacer()
        }
    }

    // MARK: - Step 1: Profile (top-right)

    private var profileCallout: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                        .padding(.trailing, 8)

                    calloutBubble(
                        text: "Tap here for your\nProfile & Log Out",
                        systemImage: "person.crop.circle"
                    )
                }
                .padding(.top, 52)
                .padding(.trailing, 12)
            }
            Spacer()
        }
    }

    // MARK: - Step 2: Swipe left

    private var swipeCallout: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)

                    Image(systemName: "arrow.left")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }

                calloutBubble(
                    text: "Swipe left from this screen\nto see Won Words & Community",
                    systemImage: "rectangle.on.rectangle.angled"
                )
            }

            Spacer()
        }
    }

    // MARK: - Step 3: Start Game

    private var startGameCallout: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "arrow.down")
                    .font(.title)
                    .foregroundStyle(Theme.accent)

                calloutBubble(
                    text: "Choose your settings above,\nthen tap Start Game to play!",
                    systemImage: "play.circle.fill"
                )
            }
            .padding(.bottom, 120)
        }
    }

    // MARK: - Shared callout bubble

    private func calloutBubble(text: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(Theme.accent)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.accent.opacity(0.5), lineWidth: 1)
        )
    }
}
