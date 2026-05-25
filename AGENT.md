# AcmeBank — Project Context

## Overview
AcmeBank is a native iOS banking app (iOS 17+, Swift 5.10, SwiftUI) that lets
customers view accounts, review transactions, initiate transfers, and manage
cards. Authentication is handled via Okta OIDC. This repo currently holds the
Hello-World bootstrap scaffold; features are added in subsequent PRs.

## Tech Stack
| Item | Value |
|---|---|
| Platform | iOS 17+ |
| Language | Swift 5.10 |
| UI Framework | SwiftUI |
| Architecture | MVVM + Coordinator (`NavigationStack`) |
| Auth | Okta OIDC (`okta-mobile-swift` 2.x) |
| Networking | `URLSession` + async/await |
| DI | Constructor injection |
| Notifications | `NotificationCenter` (typed wrappers) |
| Project file | XcodeGen (`project.yml`) |
| Test runner | XCTest (unit) + XCUITest (UI — critical flows only) |
| Bundle ID | `com.acmebank.mobile` |
| Min Xcode | 16.0 |

## Running Locally
```bash
./setup.sh                  # installs xcodegen, generates .xcodeproj, opens Xcode
# Manual fallback:
brew install xcodegen && xcodegen generate
open AcmeBank.xcodeproj
```

## Running Tests
```bash
# Xcode: Cmd+U on the AcmeBank scheme
xcodebuild test -scheme AcmeBank \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Okta build configuration
Okta tenant values reach the app via an Xcode Run Script build phase
("Inject Okta configuration") that copies four env vars (`OKTA_ISSUER`,
`OKTA_CLIENT_ID`, `OKTA_REDIRECT_URI`, `OKTA_SCOPES`) into the built
`Info.plist`, and `OktaConfig.fromBundle()` reads them at launch. The
build-machine env vars are the **single source of truth** — no
committed `Okta.plist`, xcconfig, or `.env` is allowed. See the
"Okta build configuration" section of `README.md` for the two
supported workflows (`launchctl setenv` for GUI Xcode, or
`~/.zshrc` exports + `xed .` for shell-launched Xcode).

## Key Directory Structure
```
AcmeBank/
  App/                        ← @main entry + root view (implemented)
  Config/                     ← OktaConfig (build-time tenant config)
  Core/Auth/                  ← AuthService, KeychainStore, UserSession (deferred)
  Core/Networking/            ← APIClient, APIRouter, APIError (deferred)
  Core/Notifications/         ← AppNotification, NotificationPublisher (deferred)
  Core/Extensions/            ← Decimal+Currency, Date+Greeting etc. (deferred)
  Domain/Models/              ← Account, Transaction, Customer (deferred)
  Domain/Repositories/        ← Repository protocols (deferred)
  Data/Remote/                ← API repository implementations (deferred)
  Data/Mock/                  ← Mock repository implementations (deferred)
  Features/Login/             ← Login flow: Coordinator, View, ViewModel (deferred)
  Features/Home/              ← Home flow (deferred)
  Features/Accounts/          ← Accounts flow (deferred)
  Features/Transfer/          ← Transfer flow (deferred)
  Features/Cards/             ← Cards flow (deferred)
  DesignSystem/               ← Colors, Typography, Assets (deferred)
AcmeBankTests/                ← XCTest unit tests (smoke test implemented)
AcmeBankUITests/              ← XCUITest for critical flows (deferred)
project.yml                   ← XcodeGen spec (source of truth — never edit .xcodeproj)
setup.sh                      ← one-shot materialise script
```

## Planned Architecture

### MVVM + Coordinator
- **View** — SwiftUI `View` struct; renders ViewModel state, no business logic. *(deferred)*
- **ViewModel** — `final class: ObservableObject`; `@Published` state, calls repositories. *(deferred)*
- **Coordinator** — `ObservableObject` that owns `NavigationPath`; handles all navigation. *(deferred)*
- **Repository protocols** — in `Domain/`; concrete implementations in `Data/`. *(deferred)*

### Auth (Okta OIDC) *(deferred)*
`AuthService` drives the Okta browser flow, decodes ID token claims, persists
tokens in Keychain via `KeychainStore`, and returns `UserSession`.

### Networking *(deferred)*
`APIClient` wraps `URLSession`; `APIRouter` is an endpoint enum; `RequestInterceptor`
injects Bearer tokens and triggers session-expiry notifications on 401.

### Internal Notifications *(deferred)*
Typed `Notification.Name` constants in `AppNotification`; posted via
`NotificationPublisher`; subscribed in coordinators only (never in ViewModels).

### Design System *(deferred)*
`Colors.swift` and `Typography.swift` extensions on `Color`/`Font` using the
Acme brand palette and type scale.

## Deferred Work (future PRs)
- MVVM + Coordinator wiring (AppCoordinator, RootView, all feature coordinators)
- Okta OIDC authentication (AuthService, KeychainStore, UserSession)
- Networking layer (APIClient, APIRouter, APIError, RequestInterceptor)
- Domain models (Account, Transaction, Customer, TransferRequest)
- Repository protocols + Remote/Mock implementations
- Feature screens: Login, Home, Accounts, Transfer, Cards, More
- Design system (Colors, Typography, Assets.xcassets)
- Internal notifications (AppNotification, NotificationPublisher, NotificationKey)
- Swift extensions (Decimal+Currency, Date+Greeting, String+Initials)
- XCUITest target (AcmeBankUITests) — when first critical-flow story lands
- SwiftLint (`.swiftlint.yml`) + CI workflow (`ios-build.yml`)
- Localisation (Localizable.strings)
- xcconfig injection for API_BASE_URL

## Git Workflow

> **Default PR target branch: `develop`.** Every feature/refactor/docs PR
> opens against `develop`. PRs are only opened against `qa`, `uat`, or
> `main` for explicit promotion PRs.

**Branch model (`develop` → `qa` → `uat` → `main`):**

| Branch  | Role                                 | Receives PRs from              | Promotes to |
|---------|--------------------------------------|--------------------------------|-------------|
| develop | Default integration branch           | feature branches               | qa          |
| qa      | First quality gate                   | develop (promotion PR)         | uat         |
| uat     | Pre-prod acceptance                  | qa (promotion PR)              | main        |
| main    | Production / release tags            | uat (promotion PR)             | tagged only |

All feature PRs MUST target `develop`. Never open a feature PR against
`qa`, `uat`, or `main`. Promotions happen via dedicated promotion PRs.
