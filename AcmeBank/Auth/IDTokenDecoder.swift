import Foundation

/// Typed claims extracted from an Okta ID token.
///
/// Only the four claims the rest of the app needs are surfaced
/// (`sub`, `name`, `email`, `auth_time`). Additional claims in the
/// payload are ignored, not rejected, so Okta is free to add new
/// fields without breaking the decoder.
struct IDTokenClaims: Equatable {
    let sub: String
    let name: String
    let email: String
    /// `auth_time` from the ID token, as seconds since the Unix epoch.
    let authTime: Date
}

/// Decodes an Okta ID token (a JWT) into a typed `IDTokenClaims`
/// value.
///
/// The decoder does NOT verify the JWT signature: the token reaches
/// the app via HTTPS straight from Okta's `/token` endpoint, so the
/// transport already authenticates the issuer for our purposes.
/// Signature verification (JWKS fetch, `kid` lookup, RS256 verify)
/// is out of scope for this PR and will land later if/when we ever
/// accept an ID token from an untrusted carrier.
///
/// The decoder is intentionally type-only (no stored state) so it
/// is trivially testable and thread-safe.
enum IDTokenDecoder {

    /// Errors raised by `decode(idToken:)`.
    enum DecodeError: Error, Equatable {
        /// The token did not have the `header.payload.signature` shape.
        case malformedToken
        /// The payload segment was not valid base64url-encoded data.
        case malformedPayload
        /// The payload decoded but was not a JSON object.
        case payloadNotJSONObject
        /// A required claim was missing from the payload.
        case missingClaim(String)
        /// A required claim was present but the wrong type.
        case claimWrongType(String)
    }

    /// Decode `idToken` into typed claims.
    ///
    /// Splits on `.`, base64url-decodes the middle segment, parses it
    /// as a JSON object, and plucks the required claims. The token's
    /// header and signature segments are ignored.
    static func decode(idToken: String) throws -> IDTokenClaims {
        let segments = idToken.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3 else {
            throw DecodeError.malformedToken
        }

        let payloadSegment = String(segments[1])
        guard let payloadData = base64URLDecode(payloadSegment) else {
            throw DecodeError.malformedPayload
        }

        let jsonObject = try JSONSerialization.jsonObject(with: payloadData, options: [])
        guard let payload = jsonObject as? [String: Any] else {
            throw DecodeError.payloadNotJSONObject
        }

        let sub = try requireString(payload, key: "sub")
        let name = try requireString(payload, key: "name")
        let email = try requireString(payload, key: "email")
        let authTimeSeconds = try requireNumber(payload, key: "auth_time")

        return IDTokenClaims(
            sub: sub,
            name: name,
            email: email,
            authTime: Date(timeIntervalSince1970: authTimeSeconds)
        )
    }

    // MARK: - Helpers

    /// Decode a base64url segment to `Data`, handling the missing
    /// `=` padding and the `-`/`_` substitutions that JWTs use.
    private static func base64URLDecode(_ input: String) -> Data? {
        var s = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        // Pad to a multiple of 4 with `=`.
        let remainder = s.count % 4
        if remainder > 0 {
            s.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: s)
    }

    private static func requireString(_ dict: [String: Any], key: String) throws -> String {
        guard let raw = dict[key] else {
            throw DecodeError.missingClaim(key)
        }
        guard let value = raw as? String else {
            throw DecodeError.claimWrongType(key)
        }
        return value
    }

    private static func requireNumber(_ dict: [String: Any], key: String) throws -> TimeInterval {
        guard let raw = dict[key] else {
            throw DecodeError.missingClaim(key)
        }
        // `auth_time` is spec'd as a JSON number of seconds since the
        // epoch. Accept any numeric encoding JSONSerialization produces.
        if let n = raw as? NSNumber {
            return n.doubleValue
        }
        throw DecodeError.claimWrongType(key)
    }
}
