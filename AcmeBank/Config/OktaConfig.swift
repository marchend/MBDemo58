import Foundation

/// Typed view over the Okta tenant configuration that the
/// "Inject Okta configuration" build phase writes into the app's
/// `Info.plist` from build-machine environment variables.
///
/// There is intentionally no committed config file (no `Okta.plist`,
/// no `.env`, no xcconfig with real values). The build-machine env
/// vars `OKTA_ISSUER`, `OKTA_CLIENT_ID`, `OKTA_REDIRECT_URI`, and
/// `OKTA_SCOPES` are the single source of truth — see the
/// "Okta build configuration" section of `README.md`.
///
/// `fromBundle()` traps with `fatalError` if any value is missing,
/// empty, or malformed so misconfiguration fails LOUD at app launch
/// rather than silently at the first auth call. Tests use the
/// throwing `validated(infoDictionary:)` factory to exercise both
/// the happy path and every error path hermetically.
struct OktaConfig: Equatable {
    let issuer: URL
    let clientID: String
    let redirectURI: URL
    let scopes: [String]

    /// Info.plist keys seeded in `project.yml` and overwritten by the
    /// "Inject Okta configuration" pre-build script.
    enum Key {
        static let issuer = "OktaIssuer"
        static let clientID = "OktaClientID"
        static let redirectURI = "OktaRedirectURI"
        static let scopes = "OktaScopes"
    }

    /// Validation errors raised by `validated(infoDictionary:)`.
    enum ConfigError: Error, Equatable {
        case missingKey(String)
        case emptyValue(String)
        case malformedURL(key: String, value: String)
        case noScopes
    }

    /// Read from the app's main bundle. Call once at app launch.
    /// Traps with `fatalError` on any validation error.
    static func fromBundle() -> OktaConfig {
        from(infoDictionary: Bundle.main.infoDictionary ?? [:])
    }

    /// Trapping factory used by `fromBundle()`. Tests should prefer
    /// `validated(infoDictionary:)` so a misconfiguration doesn't
    /// crash the test runner.
    static func from(infoDictionary: [String: Any]) -> OktaConfig {
        do {
            return try validated(infoDictionary: infoDictionary)
        } catch {
            fatalError("OktaConfig: \(error). Ensure the build-machine env vars are set — see README 'Okta build configuration'.")
        }
    }

    /// Throwing factory: same validation as `from(infoDictionary:)`
    /// but surfaces errors instead of trapping, so unit tests can
    /// exercise every failure path without crashing.
    static func validated(infoDictionary: [String: Any]) throws -> OktaConfig {
        let issuerString = try requireNonEmptyString(infoDictionary, key: Key.issuer)
        let clientID = try requireNonEmptyString(infoDictionary, key: Key.clientID)
        let redirectURIString = try requireNonEmptyString(infoDictionary, key: Key.redirectURI)
        let scopesString = try requireNonEmptyString(infoDictionary, key: Key.scopes)

        guard let issuer = URL(string: issuerString), issuer.scheme != nil else {
            throw ConfigError.malformedURL(key: Key.issuer, value: issuerString)
        }
        guard let redirectURI = URL(string: redirectURIString), redirectURI.scheme != nil else {
            throw ConfigError.malformedURL(key: Key.redirectURI, value: redirectURIString)
        }

        let scopes = scopesString
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)

        guard !scopes.isEmpty else {
            throw ConfigError.noScopes
        }

        return OktaConfig(
            issuer: issuer,
            clientID: clientID,
            redirectURI: redirectURI,
            scopes: scopes
        )
    }

    private static func requireNonEmptyString(
        _ dict: [String: Any],
        key: String
    ) throws -> String {
        guard let raw = dict[key] as? String else {
            throw ConfigError.missingKey(key)
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ConfigError.emptyValue(key)
        }
        return trimmed
    }
}
