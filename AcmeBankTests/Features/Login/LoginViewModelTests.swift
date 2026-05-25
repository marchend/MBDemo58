import XCTest
@testable import AcmeBank

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - isSignInEnabled

    func testIsSignInEnabled_falseWhenBothEmpty() {
        let vm = LoginViewModel()
        XCTAssertFalse(vm.isSignInEnabled, "isSignInEnabled should be false when both fields are empty")
    }

    func testIsSignInEnabled_falseWhenOnlyUsernameSet() {
        let vm = LoginViewModel()
        vm.username = "user@acme.com"
        XCTAssertFalse(vm.isSignInEnabled, "isSignInEnabled should be false when only username is set")
    }

    func testIsSignInEnabled_falseWhenOnlyPasswordSet() {
        let vm = LoginViewModel()
        vm.password = "secret"
        XCTAssertFalse(vm.isSignInEnabled, "isSignInEnabled should be false when only password is set")
    }

    func testIsSignInEnabled_trueWhenBothSet() {
        let vm = LoginViewModel()
        vm.username = "user@acme.com"
        vm.password = "secret"
        XCTAssertTrue(vm.isSignInEnabled, "isSignInEnabled should be true when both fields are non-empty")
    }

    // MARK: - isPasswordVisible

    func testPasswordVisibilityToggle() {
        let vm = LoginViewModel()
        XCTAssertFalse(vm.isPasswordVisible, "isPasswordVisible should default to false")
        vm.isPasswordVisible.toggle()
        XCTAssertTrue(vm.isPasswordVisible, "isPasswordVisible should be true after first toggle")
        vm.isPasswordVisible.toggle()
        XCTAssertFalse(vm.isPasswordVisible, "isPasswordVisible should be false after second toggle")
    }

    // MARK: - keepSignedIn

    func testKeepSignedInToggle() {
        let vm = LoginViewModel()
        XCTAssertFalse(vm.keepSignedIn, "keepSignedIn should default to false")
        vm.keepSignedIn = true
        XCTAssertTrue(vm.keepSignedIn, "keepSignedIn should be true after being set")
    }

    // MARK: - errorMessage

    func testErrorMessageNilByDefault() {
        let vm = LoginViewModel()
        XCTAssertNil(vm.errorMessage, "errorMessage should be nil by default")
    }

    func testErrorMessageCanBeSet() {
        let vm = LoginViewModel()
        vm.errorMessage = "Incorrect username or password. Please try again."
        XCTAssertNotNil(vm.errorMessage, "errorMessage should be non-nil after being set")
        XCTAssertEqual(
            vm.errorMessage,
            "Incorrect username or password. Please try again.",
            "errorMessage should match the assigned value"
        )
    }

    // MARK: - signIn

    func testSignInClosureCalledWithCorrectArguments() {
        let vm = LoginViewModel()
        vm.username = "user@acme.com"
        vm.password = "p@ssw0rd"
        vm.keepSignedIn = true

        var capturedUsername: String?
        var capturedPassword: String?
        var capturedKeepSignedIn: Bool?

        let expectation = expectation(description: "onSignIn closure called")

        vm.signIn { username, password, keepSignedIn in
            capturedUsername = username
            capturedPassword = password
            capturedKeepSignedIn = keepSignedIn
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)

        XCTAssertEqual(capturedUsername, "user@acme.com")
        XCTAssertEqual(capturedPassword, "p@ssw0rd")
        XCTAssertEqual(capturedKeepSignedIn, true)
    }
}
