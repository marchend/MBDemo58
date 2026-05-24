# Bootstrap Plan — AcmeBank iOS

## In scope (this PR)

### Project name + tech stack decisions
- **App name:** AcmeBank
- **Platform:** iOS 17+, Swift 5.10, SwiftUI
- **Architecture:** MVVM + Coordinator (full architecture deferred; only a placeholder ContentView ships)
- **Project mechanism:** XcodeGen (`project.yml`) — never hand-crafted `.xcodeproj`
- **Test framework:** XCTest (unit tests via `AcmeBankTests` target)
- **Bundle ID:** `com.acmebank.mobile`
- **Minimum Xcode:** 16.0

### Directory structure (bootstrap only)
```
AcmeBank/                       ← SwiftUI app source root
  App/
    AcmeBankApp.swift           ← @main entry point (WindowGroup + ContentView)
    ContentView.swift           ← Hello-World placeholder ("AcmeBank")
AcmeBankTests/
  AcmeBankTests.swift           ← single smoke test (ContentView initialises)
project.yml                     ← XcodeGen spec
.gitignore                      ← standard iOS/XcodeGen ignore rules
setup.sh                        ← one-shot materialise script
bootstrap_plan.md               ← this file
CLAUDE.md                       ← project context for Anthropic agents
AGENT.md                        ← project context for other model families
README.md                       ← updated with setup instructions
```

### How to run locally
```bash
./setup.sh          # installs xcodegen if absent, runs xcodegen generate, opens Xcode
# Manual fallback:
brew install xcodegen && xcodegen generate
open AcmeBank.xcodeproj
```

### How to run tests
In Xcode: Cmd+U on the `AcmeBank` scheme.
CLI: `xcodebuild test -scheme AcmeBank -destination 'platform=iOS Simulator,name=iPhone 16'`

### Definition of Hello World
The app launches and displays a single screen with the text **"AcmeBank"** centred on a system background. One XCTest confirms `ContentView` initialises without crashing.

---

## Out of scope — deferred to future work

- **MVVM + Coordinator pattern** (AppCoordinator, RootView, LoginCoordinator, TabBarCoordinator, HomeCoordinator, TransferCoordinator, CardsCoordinator, MoreCoordinator) — future PR
- **Authentication — Okta OIDC** (`AuthService`, `KeychainStore`, `UserSession`, `Okta.plist`, `okta-mobile-swift` SPM dependency) — future PR
- **Networking layer** (`APIClient`, `APIRouter`, `APIError`, `RequestInterceptor`, `API_BASE_URL` xcconfig) — future PR
- **Domain models** (`Account`, `Transaction`, `Customer`, `TransferRequest`, `Address`) — future PR
- **Repository protocols** (`AccountRepositoryProtocol`, `TransactionRepositoryProtocol`, `CustomerRepositoryProtocol`, `TransferRepositoryProtocol`) — future PR
- **Data layer — Remote repositories** (`AccountAPIRepository`, `TransactionAPIRepository`, `CustomerAPIRepository`) — future PR
- **Data layer — Mock repositories** (`MockAccountRepository`, `MockTransactionRepository`, `MockCustomerRepository`) — future PR
- **Feature screens** (Login, Home, Accounts, Transfer, Cards, More) — future PRs per feature
- **Design system** (`Colors.swift`, `Typography.swift`, `Assets.xcassets`) — future PR
- **Internal notifications** (`AppNotification`, `NotificationPublisher`, `NotificationKey`) — future PR
- **Extensions** (`Decimal+Currency`, `Date+Greeting`, `String+Initials`) — future PR
- **XCUITest target** (`AcmeBankUITests`) — added when first critical-flow story (login) lands
- **SwiftLint** (`.swiftlint.yml`) — future PR
- **CI workflow** (`ios-build.yml`, xcconfig injection, `-warnings-as-errors`) — future PR
- **Localisation** (`Localizable.strings`) — future PR
