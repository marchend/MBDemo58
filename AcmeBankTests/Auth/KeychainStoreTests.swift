import XCTest
@testable import AcmeBank

final class KeychainStoreTests: XCTestCase {

    /// One unique `service` per test run, so concurrent / repeated
    /// invocations on the simulator's shared keychain don't bleed
    /// state between cases. We also scrub every key at setUp and
    /// tearDown for belt-and-braces isolation.
    private var store: KeychainStore!

    override func setUpWithError() throws {
        let uniqueService = "com.acmebank.okta.tests.\(UUID().uuidString)"
        store = KeychainStore(service: uniqueService)
        try scrubAll()
    }

    override func tearDownWithError() throws {
        try scrubAll()
        store = nil
    }

    private func scrubAll() throws {
        for key in [KeychainStore.Key.accessToken, .idToken, .refreshToken] {
            try store.delete(key)
        }
    }

    // MARK: - Round trip

    func test_saveReadDelete_roundTrip() throws {
        try store.save("access-value", for: .accessToken)
        XCTAssertEqual(try store.read(.accessToken), "access-value")

        try store.delete(.accessToken)
        XCTAssertNil(try store.read(.accessToken))
    }

    func test_save_keysAreIndependent() throws {
        try store.save("a", for: .accessToken)
        try store.save("i", for: .idToken)
        try store.save("r", for: .refreshToken)

        XCTAssertEqual(try store.read(.accessToken), "a")
        XCTAssertEqual(try store.read(.idToken), "i")
        XCTAssertEqual(try store.read(.refreshToken), "r")
    }

    // MARK: - Overwrite

    func test_save_twice_keepsLatestValue() throws {
        try store.save("first", for: .refreshToken)
        try store.save("second", for: .refreshToken)
        XCTAssertEqual(try store.read(.refreshToken), "second")
    }

    func test_save_overwrite_doesNotAffectOtherKeys() throws {
        try store.save("id-1", for: .idToken)
        try store.save("access-1", for: .accessToken)
        try store.save("access-2", for: .accessToken)

        XCTAssertEqual(try store.read(.accessToken), "access-2")
        XCTAssertEqual(try store.read(.idToken), "id-1")
    }

    // MARK: - Read missing

    func test_read_missingKey_returnsNil() throws {
        XCTAssertNil(try store.read(.accessToken))
        XCTAssertNil(try store.read(.idToken))
        XCTAssertNil(try store.read(.refreshToken))
    }

    // MARK: - Delete

    func test_delete_missingKey_doesNotThrow() throws {
        XCTAssertNoThrow(try store.delete(.refreshToken))
    }

    func test_delete_removesOnlyTargetedKey() throws {
        try store.save("a", for: .accessToken)
        try store.save("i", for: .idToken)

        try store.delete(.accessToken)

        XCTAssertNil(try store.read(.accessToken))
        XCTAssertEqual(try store.read(.idToken), "i")
    }

    // MARK: - Unicode payload

    func test_save_unicodePayload_roundTrips() throws {
        let unicode = "tok-\u{1F510}-é-\u{4E2D}\u{6587}"
        try store.save(unicode, for: .accessToken)
        XCTAssertEqual(try store.read(.accessToken), unicode)
    }
}
