# AcmeBank iOS

Native iOS banking app — Swift 5.10, SwiftUI, iOS 17+.

## Quick Start

```bash
./setup.sh
```

The script installs [XcodeGen](https://github.com/yonaskolb/XcodeGen) via
Homebrew if it's not already present, materialises `AcmeBank.xcodeproj` from
`project.yml`, and opens it in Xcode.

**Manual fallback** (for environments that block shell scripts):
```bash
brew install xcodegen
xcodegen generate
open AcmeBank.xcodeproj
```

## Okta build configuration

The Okta tenant configuration is **never committed**. There is no
`Okta.plist`, no `.env`, no xcconfig with real values. Instead, an Xcode
Run Script build phase ("Inject Okta configuration") reads four
environment variables from the calling shell at build time and writes
them into the built `Info.plist` via `plutil -replace`. Swift code reads
them through `OktaConfig.fromBundle()`.

Required env vars:

| Variable             | Example                                       |
|----------------------|-----------------------------------------------|
| `OKTA_ISSUER`        | `https://acme.okta.com/oauth2/default`        |
| `OKTA_CLIENT_ID`     | `0oaXXXXXXXXXXXXXXXXX`                        |
| `OKTA_REDIRECT_URI`  | `com.acmebank.mobile:/callback`               |
| `OKTA_SCOPES`        | `openid profile email offline_access`         |

If any of the four is unset, the build fails fast with
`OKTA_<NAME> not set` from the script's `${VAR:?msg}` guard — the
app will never silently ship with an empty Okta config.

### Setting the env vars so Xcode sees them

Xcode passes the calling process's environment to build phase scripts,
so where you start Xcode matters.

**1. GUI-launched Xcode (Finder, Dock, Spotlight)** — use `launchctl`
so the values are visible to every GUI-launched app:

```bash
launchctl setenv OKTA_ISSUER       "https://acme.okta.com/oauth2/default"
launchctl setenv OKTA_CLIENT_ID    "0oaXXXXXXXXXXXXXXXXX"
launchctl setenv OKTA_REDIRECT_URI "com.acmebank.mobile:/callback"
launchctl setenv OKTA_SCOPES       "openid profile email offline_access"
```

You only need to do this once per login session (re-run after reboot,
or put the commands in a login item).

**2. Shell-launched Xcode (`xed .` from Terminal)** — export the vars
from your shell rc and open Xcode through that shell:

```bash
# ~/.zshrc
export OKTA_ISSUER="https://acme.okta.com/oauth2/default"
export OKTA_CLIENT_ID="0oaXXXXXXXXXXXXXXXXX"
export OKTA_REDIRECT_URI="com.acmebank.mobile:/callback"
export OKTA_SCOPES="openid profile email offline_access"
```

Then, from a **fresh** shell where those exports are in effect:

```bash
cd path/to/AcmeBank
xed .
```

The Xcode instance launched by `xed` inherits the shell's environment.
An Xcode already running from a Dock click will **not** pick up these
exports — quit it and reopen via `xed` (or use `launchctl setenv`).

## Running Tests

In Xcode: **Cmd+U** on the `AcmeBank` scheme.

CLI:
```bash
xcodebuild test -scheme AcmeBank \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Project File

`AcmeBank.xcodeproj` is **generated** — never commit it. The source of truth
is `project.yml`. After adding new Swift files, run `xcodegen generate` to
refresh the project.

## Architecture

MVVM + Coordinator, SwiftUI `NavigationStack`. See `CLAUDE.md` / `AGENT.md`
for the full planned architecture and deferred-work list.
