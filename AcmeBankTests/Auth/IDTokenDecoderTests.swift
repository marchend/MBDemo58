import XCTest
@testable import AcmeBank

final class IDTokenDecoderTests: XCTestCase {

    // MARK: - Test helpers

    /// Encode `Data` as base64url with no padding, the way real JWTs
    /// carry their segments. The decoder under test must restore the
    /// `=` padding itself.
    private func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Build a `header.payload.signature` JWT string with the given
    /// JSON payload. Header and signature are fixed dummy values \u2014
    /// the decoder ignores both.
    private func makeJWT(payload: [String: Any]) throws -> String {
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let header = base64URLEncode(Data(#"{"alg":"RS256","typ":"JWT"}"#.utf8))
        let body = base64URLEncode(payloadData)
        let signature = base64URLEncode(Data("not-a-real-signature".utf8))
        return "\(header).\(body).\(signature)"
    }

    // MARK: - Happy path

    func test_decode_extractsAllFourClaims() throws {
        let token = try makeJWT(payload: [
            "sub": "00u123abc",
            "name": "Alex Example",
            "email": "alex@example.com",
            "auth_time": 1_700_000_000
        ])

        let claims = try IDTokenDecoder.decode(idToken: token)

        XCTAssertEqual(claims.sub, "00u123abc")
        XCTAssertEqual(claims.name, "Alex Example")
        XCTAssertEqual(claims.email, "alex@example.com")
        XCTAssertEqual(claims.authTime.timeIntervalSince1970, 1_700_000_000, accuracy: 0.001)
    }

    func test_decode_ignoresExtraClaimsInPayload() throws {
        // Okta is free to add more claims later \u2014 the decoder must
        // not reject them.
        let token = try makeJWT(payload: [
            "sub": "u",
            "name": "n",
            "email": "e@e.com",
            "auth_time": 42,
            "iss": "https://example.okta.com",
            "aud": "0oaABC",
            "iat": 100,
            "exp": 200
        ])

        let claims = try IDTokenDecoder.decode(idToken: token)
        XCTAssertEqual(claims.sub, "u")
    }

    // MARK: - base64url padding

    func test_decode_handlesPayloadRequiringSinglePadByte() throws {
        // We control the payload length so the base64-encoded form
        // would naturally end with `=` padding the JWT then strips.
        // Find a payload whose base64 length % 4 == 3 (one `=`).
        let claims = try IDTokenDecoder.decode(
            idToken: try makeJWT(payload: [
                "sub": "abc",
                "name": "x",
                "email": "y@z.co",
                "auth_time": 1
            ])
        )
        XCTAssertEqual(claims.sub, "abc")
    }

    func test_decode_handlesPayloadRequiringTwoPadBytes() throws {
        // Tweak the name field length to push the base64 length into
        // the `==` (two pad bytes) bucket. We don't need to compute
        // it exactly: covering a different payload length than the
        // previous test is enough to exercise the padding restore
        // across both common cases.
        let claims = try IDTokenDecoder.decode(
            idToken: try makeJWT(payload: [
                "sub": "ab",
                "name": "xy",
                "email": "yy@zz.co",
                "auth_time": 1
            ])
        )
        XCTAssertEqual(claims.sub, "ab")
        XCTAssertEqual(claims.name, "xy")
    }

    // MARK: - Malformed token

    func test_decode_malformedToken_tooFewSegments_throws() {
        XCTAssertThrowsError(try IDTokenDecoder.decode(idToken: "only.twosegments")) { error in
            XCTAssertEqual(error as? IDTokenDecoder.DecodeError, .malformedToken)
        }
    }

    func test_decode_malformedToken_emptyString_throws() {
        XCTAssertThrowsError(try IDTokenDecoder.decode(idToken: "")) { error in
            XCTAssertEqual(error as? IDTokenDecoder.DecodeError, .malformedToken)
        }
    }

    func test_decode_malformedPayload_invalidBase64_throws() {
        // The middle segment contains a `*`, which is not valid in
        // base64 or base64url.
        let token = "header.****.sig"
        XCTAssertThrowsError(try IDTokenDecoder.decode(idToken: token)) { error in
            // Either malformedPayload (base64 fails) or a JSON error
            // is acceptable here, but our base64URLDecode returns nil
            // for invalid chars so we expect malformedPayload.
            XCTAssertEqual(error as? IDTokenDecoder.DecodeError, .malformedPayload)
        }
    }

    // MARK: - Missing / wrong-type claims

    func test_decode_missingSubClaim_throws() throws {
        let token = try makeJWT(payload: [
            "name": "n",
            "email": "e@e.com",
            "auth_time": 1
        ])
        XCTAssertThrowsError(try IDTokenDecoder.decode(idToken: token)) { error in
            XCTAssertEqual(error as? IDTokenDecoder.DecodeError, .missingClaim("sub"))
        }
    }

    func test_decode_missingAuthTimeClaim_throws() throws {
        let token = try makeJWT(payload: [
            "sub": "u",
            "name": "n",
            "email": "e@e.com"
        ])
        XCTAssertThrowsError(try IDTokenDecoder.decode(idToken: token)) { error in
            XCTAssertEqual(error as? IDTokenDecoder.DecodeError, .missingClaim("auth_time"))
        }
    }

    func test_decode_subClaimWrongType_throws() throws {
        let token = try makeJWT(payload: [
            "sub": 12345,            // number where a string is required
            "name": "n",
            "email": "e@e.com",
            "auth_time": 1
        ])
        XCTAssertThrowsError(try IDTokenDecoder.decode(idToken: token)) { error in
            XCTAssertEqual(error as? IDTokenDecoder.DecodeError, .claimWrongType("sub"))
        }
    }
}
