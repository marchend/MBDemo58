import Foundation
import Security

/// Thin wrapper over the Security framework's `SecItem*` C API for
/// saving/reading/deleting the three Okta tokens the app holds:
/// access, ID, and refresh.
///
/// Design notes:
/// - Uses `kSecClassGenericPassword`, the right item class for
///   opaque per-app secrets (vs. internet passwords or certificates).
/// - `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so the
///   tokens are readable from background launches after the first
///   unlock since boot, but never sync to iCloud Keychain and never
///   restore to a different device from an encrypted backup. Refresh
///   tokens are device-bound for a reason \u2014 do not weaken this.
/// - `save` is delete-then-add so repeated logins overwrite the
///   stored token cleanly without `errSecDuplicateItem`.
/// - Tests inject a unique `service` per test run to avoid bleed-over
///   between test cases (the Keychain persists across simulator
///   processes).
struct KeychainStore {

    /// The three token slots this app holds. The raw value is used
    /// as the Keychain item's `account` attribute, which together
    /// with the `service` uniquely identifies an item.
    enum Key: String {
        case accessToken
        case idToken
        case refreshToken
    }

    /// Errors raised by the keychain operations. Wraps the raw
    /// `OSStatus` so tests / logs can see exactly what `SecItem*`
    /// returned.
    enum KeychainError: Error, Equatable {
        case unexpectedStatus(OSStatus)
        case dataEncodingFailed
        case dataDecodingFailed
    }

    /// The Keychain `service` attribute. Defaults to a fixed
    /// per-app identifier in production; tests pass a unique
    /// service string so concurrent / repeated test runs don't
    /// collide on the shared simulator keychain.
    let service: String

    init(service: String = "com.acmebank.okta") {
        self.service = service
    }

    /// Save `value` for `key`, overwriting any existing entry.
    ///
    /// Implemented as delete-then-add so repeated logins (or token
    /// refreshes) update the stored value without surfacing
    /// `errSecDuplicateItem`.
    func save(_ value: String, for key: Key) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.dataEncodingFailed
        }

        // Best-effort delete \u2014 ignore "not found" (`errSecItemNotFound`).
        let deleteQuery: [String: Any] = baseQuery(for: key)
        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            throw KeychainError.unexpectedStatus(deleteStatus)
        }

        var addQuery = baseQuery(for: key)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }

    /// Read the value for `key`, or `nil` if no such item exists.
    func read(_ key: Key) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data else {
                throw KeychainError.dataDecodingFailed
            }
            guard let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.dataDecodingFailed
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    /// Delete the stored value for `key`. A no-op (success) if the
    /// item does not exist, so callers can call this unconditionally
    /// at sign-out without first checking.
    func delete(_ key: Key) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    // MARK: - Helpers

    private func baseQuery(for key: Key) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
    }
}
