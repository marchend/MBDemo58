import SwiftUI

/// Root login screen.
///
/// Owns the `LoginViewModel` and composes all login sub-components.
/// The `onSignIn` closure is the sole integration surface — it receives
/// `(username, password, keepSignedIn)` when the user taps "Sign in".
/// Real auth handling is wired by the caller and deferred to a future PR.
struct LoginView: View {

    // MARK: - Properties

    /// Called when the user taps "Sign in" with valid credentials entered.
    var onSignIn: (String, String, Bool) -> Void

    // MARK: - Private State

    @StateObject private var viewModel = LoginViewModel()
    @State private var showHelp = false
    @State private var showOpenAccount = false

    /// Required so the environment object is propagated down to
    /// `ThemeToggleButton` which reads it via `@EnvironmentObject`.
    @EnvironmentObject var appTheme: AppTheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            OktaHeaderView()

            ScrollView {
                VStack(spacing: 20) {
                    logoTitleBlock
                    usernameField
                    passwordField
                    ErrorBannerView(message: viewModel.errorMessage)
                    checkboxHelpRow
                    signInButton
                    openAccountRow
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }

            OktaFooterView()
        }
        .background(Color(.systemBackground))
        .overlay(alignment: .topTrailing) {
            ThemeToggleButton()
        }
    }

    // MARK: - Subviews

    /// Logo + title block.
    private var logoTitleBlock: some View {
        VStack(spacing: 12) {
            HexagonLogoView()
            Text("Acme Bank")
                .font(.title)
                .bold()
            Text("Sign in to your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// Username input field.
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Username")
                .font(.subheadline.bold())
            TextField("name@acmebank.com", text: $viewModel.username)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.username)
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .accessibilityLabel("Username")
        }
    }

    /// Password input field with show/hide toggle.
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password")
                .font(.subheadline.bold())
            ZStack {
                if viewModel.isPasswordVisible {
                    TextField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                }
            }
            .padding(12)
            .padding(.trailing, 44) // make room for the eye button
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 1)
            )
            .overlay(alignment: .trailing) {
                Button {
                    viewModel.isPasswordVisible.toggle()
                } label: {
                    Image(systemName: viewModel.isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 12)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(viewModel.isPasswordVisible ? "Hide password" : "Show password")
            }
        }
    }

    /// "Keep me signed in" toggle + "Need help?" button row.
    private var checkboxHelpRow: some View {
        HStack {
            Toggle(isOn: $viewModel.keepSignedIn) {
                Text("Keep me signed in")
                    .font(.subheadline)
            }
            .toggleStyle(.checkmark)
            .frame(minHeight: 44)

            Spacer()

            Button("Need help?") {
                showHelp = true
            }
            .font(.subheadline.bold())
            .frame(minHeight: 44)
            .sheet(isPresented: $showHelp) {
                HelpSheetView()
            }
        }
    }

    /// Primary "Sign in" button.
    private var signInButton: some View {
        Button {
            viewModel.signIn(onSignIn: onSignIn)
        } label: {
            Text("Sign in")
                .font(.headline)
                // WCAG-AA: white-on-navyPrimary is legible in both modes
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .background(viewModel.isSignInEnabled ? Color.navyPrimary : Color.gray)
        .cornerRadius(10)
        .disabled(!viewModel.isSignInEnabled)
        .accessibilityLabel("Sign in")
        .accessibilityHint(
            viewModel.isSignInEnabled
                ? ""
                : "Enter your username and password to enable"
        )
    }

    /// "Don't have an account? Open one" row.
    private var openAccountRow: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("Open one") {
                showOpenAccount = true
            }
            .font(.subheadline.bold())
        }
        .frame(minHeight: 44)
        .sheet(isPresented: $showOpenAccount) {
            OpenAccountStubView()
        }
    }
}

// MARK: - CheckmarkToggleStyle

/// A checkbox-style `ToggleStyle` used for the "Keep me signed in" toggle.
private struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? Color.navyPrimary : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckmarkToggleStyle {
    static var checkmark: CheckmarkToggleStyle { CheckmarkToggleStyle() }
}

// MARK: - Preview

#Preview {
    LoginView(onSignIn: { _, _, _ in })
        .environmentObject(AppTheme())
}
