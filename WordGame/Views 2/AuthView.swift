import SwiftUI

struct AuthView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case signIn = "Log In"
        case signUp = "Sign Up"

        var id: String { rawValue }
    }

    @Binding var isPresented: Bool
    @EnvironmentObject private var authStore: AuthStore

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAccountCreatedNotice = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 18) {
                    Text("Welcome to Paw-dle")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.accent)

                    Text("Log in or create an account to save progress.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Picker("Auth Mode", selection: $mode) {
                        ForEach(Mode.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Theme.tileEmpty)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        SecureField("Password", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Theme.tileEmpty)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        if mode == .signUp {
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Theme.tileEmpty)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    if let errorMessage = authStore.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if showAccountCreatedNotice {
                        Label("Account created", systemImage: "checkmark.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        submit()
                    } label: {
                        HStack(spacing: 8) {
                            if authStore.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(mode.rawValue)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.accent)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authStore.isLoading)

                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if authStore.isAuthenticated {
                        Button("Done") {
                            isPresented = false
                        }
                        .foregroundStyle(Theme.accent)
                    }
                }
            }
            .interactiveDismissDisabled(!authStore.isAuthenticated)
            .onChange(of: mode) { _, _ in
                showAccountCreatedNotice = false
            }
        }
    }

    private func submit() {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            authStore.errorMessage = "Please enter a valid email address."
            return
        }

        guard password.count >= 6 else {
            authStore.errorMessage = "Password must be at least 6 characters."
            return
        }

        if mode == .signUp {
            guard password == confirmPassword else {
                authStore.errorMessage = "Passwords do not match."
                return
            }
        }

        Task {
            switch mode {
            case .signIn:
                if await authStore.signIn(email: normalizedEmail, password: password) {
                    isPresented = false
                }
            case .signUp:
                if await authStore.signUp(email: normalizedEmail, password: password) {
                    showAccountCreatedNotice = true
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    isPresented = false
                }
            }
        }
    }
}
