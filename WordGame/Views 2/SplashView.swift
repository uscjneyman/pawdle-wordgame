import SwiftUI

struct SplashView: View {
    @State private var pawWave = false
    @State private var mascotFloat = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.background, Theme.accent.opacity(0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.accent.opacity(0.16))
                        .frame(width: 150, height: 150)

                    Text("🐶")
                        .font(.system(size: 86))
                        .offset(y: mascotFloat ? -4 : 4)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: mascotFloat
                        )

                    Text("🐾")
                        .font(.system(size: 40))
                        .rotationEffect(.degrees(pawWave ? 24 : -10), anchor: .bottomLeading)
                        .offset(x: 18, y: -14)
                        .animation(
                            .easeInOut(duration: 0.35).repeatForever(autoreverses: true),
                            value: pawWave
                        )
                }

                Text("Paw-dle")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Text("A riddle game with paws")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .onAppear {
            pawWave = true
            mascotFloat = true
        }
    }
}
