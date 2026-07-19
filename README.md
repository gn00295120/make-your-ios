# MakeYour

**Build the tiny app you need — inside one native iPhone app.**

MakeYour turns a plain-language request into a private, native tiny app. Connect
your own OpenAI API key, describe a calculator, tracker, trip dashboard, reminder,
camera tool, game, or something personal, and GPT-5.6 assembles it from MakeYour's
precompiled SwiftUI runtime.

**[Watch the 2:04 demo](https://youtu.be/Qjo_44nRUdg)** ·
**[Try build 4 on TestFlight](https://testflight.apple.com/join/3Rnqg5Ds)** ·
**[View the OpenAI Build Week project](https://devpost.com/software/makeyour)**

[![Watch MakeYour turn a prompt into a native tiny app](artifacts/devpost/demo/MakeYour-YouTube-Thumbnail-v2.jpg)](https://youtu.be/Qjo_44nRUdg)

`Prompt → GPT-5.6 → validation + repair → review → native tiny app`

The demo records the real TripPilot build from start to finish. GPT-5.6's first
candidate contains incompatible logic, MakeYour feeds exact validator diagnostics
back to the model, and repair revision 1 produces a valid three-page app with 31
components and 21 reviewed capabilities. The result then runs locally, including
a working live currency conversion.

MakeYour is an app runtime, not a generated-code loader. It never downloads or
executes generated Swift. The model produces a versioned, declarative
`AppDocument`; MakeYour validates it, brokers sensitive device capabilities, and
renders it with signed, precompiled SwiftUI components. One host can hold many
independently styled tiny apps, while API keys stay in Keychain and project data
stays local by default.

## Demo flow

1. Open **My Apps** and switch between working examples for composable state and
   calculations, a rule-driven original game, live news, market quotes, personal
   accounting, a platform game, Snake, camera/QR capture, foreign exchange,
   task reminders, private photos, reviewed AI, and an opt-in Shortcuts surface.
2. Open **Builder**, choose **Full app** to create features or **Design only** to
   restyle an existing tiny app without changing its behavior, then review the
   generated result before applying it.
3. Open **Design Studio** for an instant, no-key-required workflow: try a preset,
   tune brand colors, type scale, layout, controls, motion, icon, and a private
   canvas photo, then apply the complete design as one undoable app version.
4. Open **AI Key**, add an OpenAI API key, and generate a real document with the
   Responses API. The key is stored in the device Keychain and requests go from
   the device directly to OpenAI. If GPT-5.6 returns an invalid candidate, the
   Builder keeps the prompt and automatically requests validator-guided repairs
   until the document is valid or the user cancels.
5. Add an AI assistant to a mini app. Each request has a review sheet showing
   the exact task and text before anything is sent.

The sample apps work without an API key so reviewers can explore the runtime
immediately. The [public TestFlight beta](https://testflight.apple.com/join/3Rnqg5Ds)
includes the complete prompt, validation, automatic-repair, capability-review,
and native-rendering flow shown in the video.

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

The test suite covers schema strictness, capability derivation, document
validation, fixed-provider parsers, persistence calculations, and deterministic
game engines. Run it with the command above before shipping.

The live AI path is intentionally isolated from the normal test suite because it
uses the API key already saved in the selected Simulator and makes one real
OpenAI request:

```bash
xcodebuild \
  -project MakeYourIOS.xcodeproj \
  -scheme MakeYourIOSLiveE2E \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

On July 19, 2026, the current source passed 244 unit tests, the actual persisted
TripPilot currency UI test, strict SwiftLint across 173 Swift files with zero
violations, `git diff --check`, Apple package validation, and signed release
verification. The live GPT-5.6 test produced an initially invalid TripPilot
candidate, completed automatic repair revision 1, validated 3 pages, 31
components, and 21 capabilities, and opened the result. It requires an API key
saved in the selected Simulator and should not be run repeatedly unless another
billable end-to-end request is intended.

## Architecture

```text
Natural-language request
        ↓
OpenAI Responses API + strict JSON schema
        ↓
AppDocument validator + GPT-5.6 repair loop + bounded compilers
        (untrusted input boundary)
        ↓
Design Genome v2 + SwiftUI component runtime + capability broker
        ↓
Per-project state, private images, and local persistence
```

## Design and media

Generated apps are not forced through one card template. Design Genome v2 gives
each tiny app a semantic light/dark brand palette; type scale and title weight;
canvas, surface, elevation, stroke, control-shape, and motion tokens; four real
page compositions; multiple navigation styles; and renderer-compatible variants
such as editorial, split, full-bleed, framed, cards, dense, and immersive.
`RendererCatalog` rejects variants that a component cannot actually render.

The same design can be created manually in Design Studio or generated with the
Builder's Design-only mode. Design-only output is merged through a host-owned
boundary that preserves pages, component IDs, copy, values, actions, bindings,
data configuration, capabilities, and local media slots. Only the visual genome
is allowed to change.

An image component or canvas background represents a semantic slot such as
`journal-photo` or `design-canvas-background`, never a file path. The user fills
that slot with `PhotosPicker`; MakeYour normalizes the image, stores it in the
project-local asset store, and keeps the bytes outside the generated document
and AI prompt. Media metadata can safely describe role, focal point, mask,
overlay, aspect, and content mode without exposing the underlying asset.

Device features use the same bounded 21-capability model. A generated document
may request host-owned camera, QR/barcode/text scanner, one-time location, Apple
contact picker, bounded text-file import, today's pedometer count, share sheet,
clipboard write, or haptic components. It can also use a bounded MapKit
coordinate/place-search view, create one reviewed event with EventKit write-only
access, export reviewed text/JSON/CSV through Apple's file exporter, and keep one
foreground-only voice note in a project-local slot, and turn that note into an
editable on-device transcript after a second tap. Access
that needs a user gesture or permission starts only after the user taps;
captured results stay in that tiny app by default, scanned URLs are shown as text
rather than opened, and unsupported simulators or devices receive an honest
fallback. Maps do not read the user's location, calendar creation cannot read
existing events, no export occurs until the user chooses a destination, and
voice notes are never uploaded or recorded after the app leaves the foreground.
Speech transcription has no network fallback and stores text only after the user
reviews and accepts the editable result.
The host rejects incomplete audio, protects temporary recording files, removes
crash leftovers on the next launch, and deletes a clip when regeneration removes
its voice binding.

A generated tiny app may also include one inert `shortcutAccess` block. That
explicitly opts only that project into one precompiled **Open Tiny App** App
Intent. The dynamic system picker receives only opted-in projects' stable IDs,
display names, and validated icons—not prompts, state, media, provider keys, or
generated code.
The intent requires local device authentication, opens MakeYour in the
foreground, and revalidates the project before routing. Removing the block or
deleting the project makes a saved stale shortcut fail closed; a duplicated
project does not inherit the opt-in.

## Composable runtime blocks

Generated tiny apps are no longer limited to choosing a prebuilt card or one
hard-coded vertical feature. The declarative runtime now includes typed text,
number, boolean, date, bounded string-list, and bounded string-object state;
session or per-project persistence; text/number/date/time inputs, pickers,
toggles, sliders, steppers, progress, dynamic text/metrics/banners/buttons and a
native collection view; ordered tap/value-change/appear/foreground-timer events;
finite arithmetic, date, collection, and condition operations; navigation,
alerts, local reminders, and haptics. State templates let several native views
share one value without downloading or executing code. Lists and objects are
flat bounded string containers rather than a general structured-record DSL;
rich editable data still uses the specialized record collection and ledger
blocks.

Games use a separate bounded Tiny Game Program v3: deterministic fixed-step
worlds, visual entity templates, sensor/solid/one-way collision, touch controls,
grounded jumping, facing projectiles, variables, timer/contact/boundary rules,
ordered effects, HUD, win/loss, pause, and restart. The polished Snake and
platformer presets remain available, while custom programs can cover top-down
collectors, dodgers, shooters, and compact static-platform games. Every custom
program is compiled and budget-checked before the runtime accepts it; stored V2
programs remain compatible.

## AI inside generated apps

Mini apps can include an allowlisted `aiAssistant` component. The component has
a focused task and accepts only text the user explicitly enters or reviews as a
visible state prefill, including an accepted local transcript. Before every
request, MakeYour shows the exact task and text for review. Photos, task lists,
other fields, other projects, and the full `AppDocument` are not attached. The
request uses the user's Keychain-backed API key directly with the OpenAI
Responses API.

See [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) for the complete Design
Genome v2 contract, [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the product
boundary,
[docs/RUNTIME_BLOCKS.md](docs/RUNTIME_BLOCKS.md) for the composable behavior and
game vocabulary,
[docs/CAPABILITY_CATALOG.md](docs/CAPABILITY_CATALOG.md) for the exact shipping
capabilities and hardware-limited roadmap, and
[docs/DEVPOST_SUBMISSION.md](docs/DEVPOST_SUBMISSION.md) for the OpenAI Build
Week submission draft and demo storyboard.

App Store Connect metadata, review notes, privacy/support pages, export options,
and the release checklist live in [docs/app-store](docs/app-store).

## Privacy and safety

- API keys are stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- Keys are never written to project files, `UserDefaults`, logs, or generated
  documents.
- Generated documents are size-limited and validated against an allowlist.
- The runtime exposes local UI, calculations, fixed-provider news/market data,
  project data, selected or captured photos, user-initiated scanning, MapKit
  search, write-only calendar creation, reviewed document export, on-device
  reviewed voice transcription, an opt-in authenticated Shortcuts opener,
  opt-in local notifications, deterministic games, and reviewed text-only AI
  requests.
  It does not execute Swift, JavaScript, WebAssembly, or plugins.
- Mini apps are private workspaces inside one signed host app; they are not
  independent `.ipa` files.

## License

The current source is available under the
[PolyForm Shield License 1.0.0](LICENSE). You may use, change, and distribute it
for purposes other than providing a product that competes with MakeYour or
another product provided by the licensor. This is a source-available license,
not an OSI open-source license.

OpenAI, Devpost, and the OpenAI Build Week judges have an additional free and
unrestricted evaluation grant through the end of the judging period. See
[NOTICE.md](NOTICE.md) for the exact grant, brand exclusions, and third-party
notices. Competing commercial uses require a separate written license; see
[COMMERCIAL-LICENSING.md](COMMERCIAL-LICENSING.md).

Versions published through commit `4a8f26d` were previously offered under MIT.
Those terms are preserved in the
[historical MIT license](docs/legal/MIT-LICENSE-HISTORICAL.md).
