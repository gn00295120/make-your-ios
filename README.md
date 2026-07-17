# MakeYour

MakeYour is a personal app runtime for iPhone. Describe a small app, connect your
own AI API key, and get a usable native mini app inside MakeYour — without
rebuilding the same calculator, tracker, checklist, or reminder app from scratch.

The host app never downloads or executes generated Swift code. The model produces
a versioned, declarative `AppDocument`; MakeYour validates that document and
renders it with a catalog of precompiled SwiftUI components and capabilities.

## Demo flow

1. Open **My Apps** and switch between **Live FX Watch**, **Use It First**,
   **Quick Convert**, and **Gentle Tasks**. The first two were generated through
   MakeYour's own Builder and ship as reviewable examples.
2. Open **Builder**, describe a change, and preview the generated result.
3. Open **AI Key**, add an OpenAI API key, and generate a real document with the
   Responses API. The key is stored in the device Keychain and requests go from
   the device directly to OpenAI.
4. Add an AI assistant to a mini app. Each request has a review sheet showing
   the exact task and text before anything is sent.

The sample apps work without an API key so reviewers can explore the runtime
immediately.

## Screens

| App library | AI builder |
| --- | --- |
| ![MakeYour app library](artifacts/screenshots/library.png) | ![MakeYour AI builder](artifacts/screenshots/builder.png) |

| Currency mini app | Task + notify mini app |
| --- | --- |
| ![Currency converter](artifacts/screenshots/converter.png) | ![Task reminder app](artifacts/screenshots/reminder-scheduled.png) |

## Build

Requirements: Xcode 26.6+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
xcodegen generate
xcodebuild \
  -project MakeYourIOS.xcodeproj \
  -scheme MakeYourIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Run tests:

```bash
xcodebuild \
  -project MakeYourIOS.xcodeproj \
  -scheme MakeYourIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

Current verification: 43 tests passing on an iPhone 17 Pro iOS 26.5 simulator,
plus `swiftlint lint --strict` with zero violations.

## Architecture

```text
Natural-language request
        ↓
OpenAI Responses API + strict JSON schema
        ↓
AppDocument validator (untrusted input boundary)
        ↓
Visual grammar + SwiftUI component runtime + capability broker
        ↓
Per-project state, private images, and local persistence
```

## Design and media

Generated apps are not forced through one card template. The document can choose
from six visual directions, page layouts, typography, background, density,
component span, alignment, surface, emphasis, and semantic variants. These
tokens form a bounded visual DSL: broad enough for distinct native designs, but
still deterministic, accessible, and safe to validate.

An image component represents a semantic slot such as `journal-photo`, never a
file path. The user fills that slot with `PhotosPicker`; MakeYour normalizes the
image, stores it in the project-local asset store, and keeps the bytes outside
the generated document and AI prompt.

## AI inside generated apps

Mini apps can include an allowlisted `aiAssistant` component. The component has
a focused task and accepts only text the user explicitly enters. Before every
request, MakeYour shows the exact task and text for review. Photos, task lists,
other fields, other projects, and the full `AppDocument` are not attached. The
request uses the user's Keychain-backed API key directly with the OpenAI
Responses API.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the product boundary and
roadmap, and [docs/DEVPOST_SUBMISSION.md](docs/DEVPOST_SUBMISSION.md) for the
OpenAI Build Week submission draft and demo storyboard.

App Store Connect metadata, review notes, privacy/support pages, export options,
and the release checklist live in [docs/app-store](docs/app-store).

## Privacy and safety

- API keys are stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- Keys are never written to project files, `UserDefaults`, logs, or generated
  documents.
- Generated documents are size-limited and validated against an allowlist.
- The runtime exposes local UI, calculations, project data, selected photos,
  opt-in local notifications, and reviewed text-only AI requests. It does not
  execute Swift, JavaScript, WebAssembly, or plugins.
- Mini apps are private workspaces inside one signed host app; they are not
  independent `.ipa` files.
