import XCTest
@testable import AcmeBank

final class OktaConfigTests: XCTestCase {

    private func makeDict(
        issuer: Any? = "https://acme.okta.com/oauth2/default",
        clientID: Any? = "0oaABC123",
        redirectURI: Any? = "com.acmebank.mobile:/callback",
        scopes: Any? = "openid profile email offline_access"
    ) -> [String: Any] {
        var d: [String: Any] = [:]
        if let v = issuer { d[OktaConfig.Key.issuer] = v }
        if let v = clientID { d[OktaConfig.Key.clientID] = v }
        if let v = redirectURI { d[OktaConfig.Key.redirectURI] = v }
        if let v = scopes { d[OktaConfig.Key.scopes] = v }
        return d
    }

    // MARK: - Happy path

    func test_validated_withFullyPopulatedDictionary_yieldsExpectedValues() throws {
        let config = try OktaConfig.validated(infoDictionary: makeDict())

        XCTAssertEqual(config.issuer, URL(string: "https://acme.okta.com/oauth2/default"))
        XCTAssertEqual(config.clientID, "0oaABC123")
        XCTAssertEqual(config.redirectURI, URL(string: "com.acmebank.mobile:/callback"))
        XCTAssertEqual(config.scopes, ["openid", "profile", "email", "offline_access"])
    }

    // MARK: - Missing / empty values

    func test_validated_missingIssuer_throwsMissingKey() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(issuer: nil))) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey(OktaConfig.Key.issuer))
        }
    }

    func test_validated_missingClientID_throwsMissingKey() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(clientID: nil))) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey(OktaConfig.Key.clientID))
        }
    }

    func test_validated_missingRedirectURI_throwsMissingKey() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(redirectURI: nil))) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey(OktaConfig.Key.redirectURI))
        }
    }

    func test_validated_missingScopes_throwsMissingKey() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(scopes: nil))) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .missingKey(OktaConfig.Key.scopes))
        }
    }

    func test_validated_emptyIssuer_throwsEmptyValue() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(issuer: ""))) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .emptyValue(OktaConfig.Key.issuer))
        }
    }

    func test_validated_whitespaceOnlyClientID_throwsEmptyValue() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(clientID: "   \t  "))) { error in
            XCTAssertEqual(error as? OktaConfig.ConfigError, .emptyValue(OktaConfig.Key.clientID))
        }
    }

    // MARK: - Malformed URL

    func test_validated_malformedIssuerURL_throwsMalformedURL() {
        // A bare token with no scheme is a relative URL — we reject it
        // because Okta's issuer must be a full absolute https URL.
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(issuer: "not a url"))) { error in
            guard case .malformedURL(let key, _)? = error as? OktaConfig.ConfigError else {
                XCTFail("Expected .malformedURL, got \(error)")
                return
            }
            XCTAssertEqual(key, OktaConfig.Key.issuer)
        }
    }

    func test_validated_malformedRedirectURI_throwsMalformedURL() {
        XCTAssertThrowsError(try OktaConfig.validated(infoDictionary: makeDict(redirectURI: "no scheme here"))) { error in
            guard case .malformedURL(let key, _)? = error as? OktaConfig.ConfigError else {
                XCTFail("Expected .malformedURL, got \(error)")
                return
            }
            XCTAssertEqual(key, OktaConfig.Key.redirectURI)
        }
    }

    // MARK: - Scopes splitting

    func test_validated_scopesSplitOnSingleSpaces() throws {
        let config = try OktaConfig.validated(infoDictionary: makeDict(scopes: "openid profile email"))
        XCTAssertEqual(config.scopes, ["openid", "profile", "email"])
    }

    func test_validated_scopesSplitOnMixedWhitespace() throws {
        let config = try OktaConfig.validated(infoDictionary: makeDict(scopes: "openid  profile\temail\noffline_access"))
        XCTAssertEqual(config.scopes, ["openid", "profile", "email", "offline_access"])
    }

    func test_validated_scopesTrimsLeadingTrailingWhitespace() throws {
        let config = try OktaConfig.validated(infoDictionary: makeDict(scopes: "  openid profile  "))
        XCTAssertEqual(config.scopes, ["openid", "profile"])
    }

    func test_validated_singleScope_yieldsSingleElementArray() throws {
        let config = try OktaConfig.validated(infoDictionary: makeDict(scopes: "openid"))
        XCTAssertEqual(config.scopes, ["openid"])
    }
}
