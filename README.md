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
