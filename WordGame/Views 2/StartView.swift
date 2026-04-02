import SwiftUI

struct StartView: View {
    @StateObject private var viewModel = GameViewModel()
    @EnvironmentObject var wonWordsStore: WonWordsStore
    @EnvironmentObject var pawPointsStore: PawPointsStore
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var syncStatusStore: SyncStatusStore
    @AppStorage("didCompleteTutorial") private var didCompleteTutorial = false
    @State private var showInstructions = false
    @State private var showProfile = false
    @State private var showOnboardingOverlay = false
    @State private var showTutorial = false
    @State private var showAuth = false
    @State private var didRunLaunchFlow = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                TopNavBar(
                    onInstructions: { showInstructions = true },
                    onProfile: { showProfile = true }
                )

                // Title
                VStack(spacing: 6) {
                    Text("Paw-dle")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)

                    Text("Solve the riddle, guess the word")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("\u{1F43E}")
                        Text("\(pawPointsStore.balance)")
                            .fontWeight(.bold)
                    }
                    .font(.callout)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Theme.accent.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }

                Spacer()

                // Settings
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.headline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(WordCategory.allCases, id: \.self) { cat in
                                    Button {
                                        viewModel.category = cat
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(cat.emoji)
                                                .font(.title2)
                                            Text(cat.displayName)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                        }
                                        .frame(width: 64, height: 60)
                                        .background(
                                            viewModel.category == cat
                                                ? Theme.accent.opacity(0.15)
                                                : Theme.tileEmpty
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(viewModel.category == cat ? Theme.accent : .clear, lineWidth: 2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Word Length")
                            .font(.headline)
                        Picker("Word Length", selection: $viewModel.wordLength) {
                            ForEach(4...8, id: \.self) { n in
                                Text("\(n) letters").tag(n)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty")
                            .font(.headline)
                        Picker("Difficulty", selection: $viewModel.difficulty) {
                            Text("Easy").tag(1)
                            Text("Medium").tag(2)
                            Text("Hard").tag(3)
                        }
                        .pickerStyle(.segmented)

                        if viewModel.difficulty >= 3 {
                            Text("Hard: tougher words, no paw reveals")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Start Game button
                VStack(spacing: 12) {
                    Button {
                        if authStore.isAuthenticated {
                            viewModel.startNewGame()
                        } else {
                            showAuth = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text("Start Game")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(viewModel.isLoading || !authStore.isAuthenticated)
                }
                .padding(.horizontal, 32)

                if !authStore.isAuthenticated {
                    Button("Log In or Sign Up") {
                        showAuth = true
                    }
                    .font(.callout.bold())
                    .foregroundStyle(Theme.accent)
                }

                // Swipe hint
                HStack(spacing: 4) {
                    Text("Swipe left for Won Words & Community")
                        .font(.caption2)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                // Error
                if let error = viewModel.errorMessage {
                    VStack(spacing: 4) {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)

                        Button("Retry") { viewModel.startNewGame() }
                            .font(.caption.bold())
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.horizontal)
                }

            }

            // On-screen tutorial overlay for new users
            if showOnboardingOverlay {
                OnboardingOverlayView {
                    withAnimation {
                        showOnboardingOverlay = false
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInstructions) {
            HowToPlayView()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
        .fullScreenCover(isPresented: $showTutorial) {
            HowToPlayView(isRequired: true) {
                didCompleteTutorial = true
                showTutorial = false
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView(isPresented: $showAuth)
        }
        .navigationDestination(isPresented: $viewModel.isGameActive) {
            GameView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.pawPointsStore = pawPointsStore
            viewModel.wonWordsStore = wonWordsStore
            guard !didRunLaunchFlow else { return }
            didRunLaunchFlow = true
            if !didCompleteTutorial {
                showTutorial = true
            } else if !authStore.isAuthenticated {
                showAuth = true
            }
        }
        .onChange(of: showTutorial) { _, showing in
            // Tutorial just dismissed — show auth if needed
            if !showing && didCompleteTutorial && !authStore.isAuthenticated {
                showAuth = true
            }
        }
        // When auth succeeds: dismiss sheet, show onboarding overlay.
        .onChange(of: authStore.isAuthenticated) { _, isAuthed in
            if isAuthed {
                showAuth = false
                withAnimation { showOnboardingOverlay = true }
            }
        }
    }
}
