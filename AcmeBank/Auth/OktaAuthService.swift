import Foundation
import UIKit
import OktaDirectAuth

// MARK: - Public protocol seam

/// Protocol that the rest of the app depends on for sign-in.
///
/// `LoginViewModel` holds an `OktaAuthenticating`, not a concrete
/// `OktaAuthService`, so unit tests can supply a stub without ever
/// touching the OktaDirectAuth SDK or the network.
protocol OktaAuthenticating {
    func signIn(
        username: String,
        password: String,
        keepSignedIn: Bool
    ) async throws -> UserSession
}

// MARK: - Errors

/// Errors surfaced from `OktaAuthService.signIn`.
///
/// The mapping is intentionally COARSE: per AC the login screen shows
/// a single fixed error message regardless of cause, so we only need
/// enough granularity for tests / future logging. The cases are:
/// - `.invalidCredentials` for any Okta-reported credential rejection
///   (wrong password, locked account, MFA required without a factor).
/// - `.network` for connectivity / transport failures.
/// - `.unknown(String)` as a catch-all that preserves a description
///   of the underlying error for diagnostics. `String` (not `Error`)
///   is used so the enum stays `Equatable` for tests.
enum OktaAuthError: Error, Equatable {
    case invalidCredentials
    case network
    case unknown(String)
}

// MARK: - Internal seam: the direct-auth flow

/// Value-type result of a successful direct-auth round trip.
///
/// Owned by this layer (not an SDK type) so the test seam never
/// requires constructing an SDK `Token`. The real implementation
/// extracts these three fields from the SDK's `Token`; tests just
/// return a hand-built `OktaTokenResult`.
struct OktaTokenResult: Equatable {
    let accessToken: String
    let idToken: String
    let refreshToken: String?
}

/// The thin seam tests stub. The default production implementation
/// (`LiveDirectAuthFlow`) wraps `DirectAuthenticationFlow` from the
/// OktaDirectAuth SDK. Tests inject a fake that returns a canned
/// result (or throws) without ever hitting the network.
protocol DirectAuthFlowPerforming {
    func authenticate(
        username: String,
        password: String
    ) async throws -> OktaTokenResult
}

/// Production implementation of the direct-auth seam.
///
/// Builds a `DirectAuthenticationFlow` from the configured issuer /
/// clientID / scopes and runs the primary username+password factor.
/// Any error thrown by the SDK is propagated as-is; the caller
/// (`OktaAuthService`) is responsible for mapping it to `OktaAuthError`.
struct LiveDirectAuthFlow: DirectAuthFlowPerforming {
    let config: OktaConfig

    func authenticate(
        username: String,
        password: String
    ) async throws -> OktaTokenResult {
        // `DirectAuthenticationFlow` (okta-mobile-swift v2) takes the
        // scopes as a single space-separated string, not an array.
        let flow = DirectAuthenticationFlow(
            issuerURL: config.issuer,
            clientId: config.clientID,
            scope: config.scopes.joined(separator: " ")
        )

        // `start(_:with:)` accepts a `PrimaryFactor` value directly;
        // `.password(_)` IS the primary factor case, so no outer
        // `.primary(...)` wrapper is needed (and the enum has no such
        // case).
        let status = try await flow.start(
            username,
            with: .password(password)
        )

        switch status {
        case .success(let token):
            return OktaTokenResult(
                accessToken: token.accessToken,
                idToken: token.idToken?.rawValue ?? "",
                refreshToken: token.refreshToken
            )
        default:
            // Any non-success status (MFA challenge, continuation, etc.)
            // is treated as a credential rejection for this PR \u2014
            // multi-factor flows are out of scope.
            throw OktaAuthError.invalidCredentials
        }
    }
}

// MARK: - OktaAuthService

/// Concrete `OktaAuthenticating` implementation that drives the
/// `OktaDirectAuth` primary username+password flow, then persists
/// the resulting tokens to Keychain and returns a `UserSession`.
///
/// Composition:
/// - `OktaConfig` provides issuer / clientID / scopes (set at launch
///   via the Info.plist build-phase injection).
/// - `KeychainStore` is the only persistence sink for tokens \u2014 nothing
///   ever lands in `UserDefaults`.
/// - `DirectAuthFlowPerforming` is the test seam; production wires
///   `LiveDirectAuthFlow`, tests wire a fake.
final class OktaAuthService: OktaAuthenticating {

    private let flow: DirectAuthFlowPerforming
    private let keychain: KeychainStore
    private let deviceName: () -> String

    /// Production initialiser. Wires the live SDK-backed flow.
    convenience init(config: OktaConfig, keychain: KeychainStore = KeychainStore()) {
        self.init(
            flow: LiveDirectAuthFlow(config: config),
            keychain: keychain,
            deviceName: { UIDevice.current.name }
        )
    }

    /// Designated initialiser. Tests use this to inject a stub flow
    /// and a deterministic device name.
    init(
        flow: DirectAuthFlowPerforming,
        keychain: KeychainStore,
        deviceName: @escaping () -> String = { UIDevice.current.name }
    ) {
        self.flow = flow
        self.keychain = keychain
        self.deviceName = deviceName
    }

    // MARK: - OktaAuthenticating

    func signIn(
        username: String,
        password: String,
        keepSignedIn: Bool
    ) async throws -> UserSession {
        let tokens: OktaTokenResult
        do {
            tokens = try await flow.authenticate(
                username: username,
                password: password
            )
        } catch {
            throw Self.map(error)
        }

        let claims = try IDTokenDecoder.decode(idToken: tokens.idToken)

        // Persist tokens. Refresh token is gated on `keepSignedIn`
        // per AC: ticking the box opts in to a longer-lived session.
        try keychain.save(tokens.accessToken, for: .accessToken)
        try keychain.save(tokens.idToken, for: .idToken)
        if keepSignedIn, let refresh = tokens.refreshToken, !refresh.isEmpty {
            try keychain.save(refresh, for: .refreshToken)
        } else {
            // Make sure a previous "keep me signed in" session doesn't
            // leak a refresh token into a subsequent unticked sign-in.
            try keychain.delete(.refreshToken)
        }

        return UserSession(
            userId: claims.sub,
            displayName: claims.name,
            email: claims.email,
            accessToken: tokens.accessToken,
            authTimestamp: claims.authTime,
            deviceName: deviceName()
        )
    }

    // MARK: - Error mapping

    /// Map any error thrown by the direct-auth seam (typically an
    /// `OktaDirectAuth` SDK error, but also `OktaAuthError` from the
    /// live wrapper's non-success status branch) into a typed
    /// `OktaAuthError`. The mapping is intentionally coarse \u2014 the
    /// UI shows a single error message regardless of cause.
    static func map(_ error: Error) -> OktaAuthError {
        if let typed = error as? OktaAuthError {
            return typed
        }
        let nsError = error as NSError
        // URLSession transport failures land in NSURLErrorDomain.
        if nsError.domain == NSURLErrorDomain {
            return .network
        }
        // Treat anything else as a credential rejection by default.
        // The UI maps every failure to the same message, so this
        // coarse default is safe.
        return .invalidCredentials
    }
}
