import Foundation

/// The value-type representation of an authenticated user, produced
/// after a successful Okta sign-in and passed forward through
/// coordinators. Persisted to Keychain (via `KeychainStore`), never
/// to `UserDefaults`.
///
/// The field list is fixed by the auth story:
/// - `userId`         from the ID token's `sub` claim
/// - `displayName`    from the ID token's `name` claim
/// - `email`          from the ID token's `email` claim
/// - `accessToken`    the OAuth2 access token (Bearer)
/// - `authTimestamp`  from the ID token's `auth_time` claim
///                    (seconds since the Unix epoch)
/// - `deviceName`     `UIDevice.current.name` captured at sign-in
///
/// `Codable` so the session can be serialised end-to-end with the
/// Keychain layer; `Equatable` so tests (and future state-diffing
/// code) can compare two sessions for identity.
struct UserSession: Codable, Equatable {
    let userId: String
    let displayName: String
    let email: String
    let accessToken: String
    let authTimestamp: Date
    let deviceName: String
}
