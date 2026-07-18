# Product and runtime architecture

## What MakeYour is

MakeYour turns repeated vibe-coding requests into private, reusable mini apps.
The user works in natural language; the AI emits a declarative document; a
deterministic iOS runtime renders and operates it.

It is best understood as four products in one:

1. an AI app builder;
2. a validator/compiler for a small declarative schema;
3. a native SwiftUI mini-app runtime;
4. a library with isolated data and versions for each project.

## Is this a new language?

Internally, yes: the versioned JSON document is a domain-specific language.
It should not begin as a new human-authored syntax. The three stable layers are:

```text
natural language → JSON AppDocument → typed runtime graph
```

The language is deliberately not Turing-complete. It has no arbitrary loops,
recursion, `eval`, dynamic modules, Swift, JavaScript, or Wasm. Every side effect
must be a registered host capability. This keeps generated output predictable,
testable, accessible, and bounded.

## Capability catalog

Capabilities are host intents, not raw Apple frameworks. The current document
vocabulary declares exactly 20 capabilities:

- `storage.local`
- `calculation.safe`
- `notifications.scheduleLocal`
- `photo.pick`
- `camera.capture`
- `camera.scanCode`
- `location.current`
- `contacts.pick`
- `files.import`
- `files.export`
- `maps.search`
- `calendar.createEvent`
- `microphone.recordLocal`
- `speech.transcribeOnDevice`
- `motion.pedometer`
- `share.present`
- `clipboard.write`
- `haptics.play`
- `http.request`
- `ai.complete`

Each request passes through manifest declaration, host availability, per-project
user grant, operating-system permission, execution limits, and result
sanitization. The active capability set is derived again by the host and must
exactly match what the document uses; generated text cannot silently escalate
access. The current runtime implements local UI/state, calculations, explicit
local notifications, user-selected and camera-captured project-local photos,
user-initiated QR/barcode/text scanning, fixed-provider network components, and
reviewed text-only AI completion. General HTTP is not exposed as an arbitrary
generated network primitive.

Device and native-service components are host adapters. The current catalog
includes camera capture, QR/barcode/text scanning, one-time foreground location,
Apple's single-contact picker, bounded text-file import, one-time pedometer
reads, reviewed sharing, clipboard writes, haptic feedback, MapKit display and
place search, reviewed write-only calendar creation, and bounded text/JSON/CSV
export through Apple's save panel, plus a bounded foreground-only local voice
note and reviewed on-device transcription of that note. Permission- or gesture-gated operations start
only at the documented user action, check availability, and sanitize and bound
their inputs and outputs. Maps do not request the user's location, calendar
creation cannot read existing events, exports cannot choose a destination, and
voice recordings cannot continue in the background or reach AI/network adapters.
Speech transcription verifies the locale, requires on-device support, exposes
an editable review, commits accepted text atomically, and has no network fallback.
Scanned URLs are never opened or forwarded to AI by default. Adding a generated
version that needs a new capability first presents a host-controlled review
sheet.

`CapabilityRegistry` is the platform ledger for every compiled host ability. It
records category, privacy risk, availability mode, user-action requirement,
framework/permission note, and the enforced boundary. Its exhaustive mapping
means a new enum case cannot compile until the product supplies metadata; the AI
schema exposes only abilities that actually ship in the signed host.

The complete shipping/roadmap split, including all 11 current device actions,
is maintained in [CAPABILITY_CATALOG.md](CAPABILITY_CATALOG.md).

## Design Genome v2

The DSL separates meaning from presentation. A component remains a metric,
task list, image, or AI assistant, while safe presentation tokens control its
native SwiftUI rendering:

```text
theme: semantic light/dark palette + type scale + title weight
       + canvas + surface + elevation + stroke + control shape + motion
page:  flow | dashboard | form | story
       + automatic | segmented | chips | menu navigation
node:  surface + span + alignment + emphasis + renderer-compatible variant
media: semantic binding + role + aspect + focal point + mask + overlay
```

Six presets (`native`, `minimal`, `soft`, `editorial`, `playful`, and `bold`)
provide coherent starting points. The AI can combine the tokens instead of
falling back to a universal card stack. There are no arbitrary frames, custom
CSS, downloaded fonts, shaders, or executable layout expressions. Dynamic Type
can collapse multi-column rows back to one column.

`RuntimeDesignContext` resolves the semantic palette and tokens once for the
active color scheme and accessibility environment. `PageLayoutEngine` makes the
four page layouts materially different, while `RendererCatalog` maintains a
per-component allowlist for variants such as `editorial`, `split`, `fullBleed`,
`framed`, `cards`, `dense`, and `immersive`. Unsupported combinations are
normalized or rejected instead of silently producing broken UI. Reduce Motion,
Reduce Transparency, Increased Contrast, Differentiate Without Color, and large
Dynamic Type remain host-enforced constraints.

The no-key Design Studio edits this same genome with a live iPhone preview,
presets, custom light/dark colors, typography, page composition, controls,
motion, icon, and a project-local canvas photo. Cancel is non-destructive; Apply
validates the result and records all design edits as exactly one new version.

Builder also has a GPT-5.6 Design-only mode. The model may propose visual tokens,
but `AppDocumentDesignMerger` performs the final host-side merge. It preserves
the app name and summary, page and component identities, copy, values, actions,
bindings, data configuration, capabilities, user-selectable image slots, and
the existing local canvas binding. This is a hard product boundary rather than
a prompt-only promise. The proposed design receives a native preview and change
summary before the user applies it.

The complete token and renderer contract lives in
[DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

## Composable behavior graph

`RuntimeLogic` is the safe behavior layer between static components and
specialized host features. It provides six typed values (`text`, `number`,
`boolean`, canonical `date`, bounded string `list`, and bounded string `object`),
session or project persistence, and finite ordered events. Lists and objects are
flat containers with at most 64 entries, not nested or schemaful records. Inputs,
pickers, date/time controls, accepted speech transcripts, AI results, and device
results can write a binding;
text, metrics, banners, buttons, progress, and `collectionView` can render the
same state through bindings or bounded `{{state-key}}` templates. Ordinary UI
templates expose a structured-value summary rather than raw JSON; the reviewed
document-export surface may deliberately resolve canonical list/object JSON.

Events may run only a validated list of steps: set state, navigate, show an
in-app message, schedule a local notification, or play a haptic. Each node may
have at most one event for each `tap`, `valueChanged`, `appear`, and `timer`
trigger. `appear` runs once for a rendered node instance; timers use a validated
1–3,600 second interval and dispatch only while the node is rendered and the iOS
scene is active, with no background work or missed-tick catch-up. Expressions
are flat literal/state/current-date operands with copy, concatenate, decimal
arithmetic, bounded list/object mutation and query, and date add/difference
operations. Conditions provide typed equality, numeric/date ordering, and
logical empty/non-empty checks. There are no event-emitting steps, loops,
recursion, callbacks, collection iteration, or dynamic dispatch, so generated
logic cannot create an unbounded execution chain.

The engine calculates the complete state transaction before committing it. A
missing reference, invalid type, divide-by-zero, malformed/oversized collection,
excessive magnitude, or storage failure leaves the prior state active.
Project-persisted values carry a type fingerprint so a schema change resets only
the incompatible key, while legacy scalar state can migrate into the current
envelope. The validator separately limits state, events, steps, operands, string
lengths, notification delays, timer intervals, and exact host capabilities.

Custom games use a sibling `TinyGameProgram` rather than the general behavior
graph. Its compiler validates world dimensions, entity and rule references,
reachability, controls, spawn/effect/contact budgets, and full initial bounds.
The deterministic fixed-step engine owns movement, swept sensor contacts,
static solid and one-way platform resolution, grounded jumps, bounded
projectiles and cooldowns, edge-crossing events, ordered rule effects, feedback,
terminal states, pause, restart, and seeded spawning. V3 supports original
top-down collectors, dodgers, simple shooters, and compact static-platform
games, while retaining stored V2 program compatibility. Moving platforms and
dynamic-vs-dynamic solid collisions deliberately fail compilation.

The exact shipping vocabulary and extension rules live in
[RUNTIME_BLOCKS.md](RUNTIME_BLOCKS.md).

## Private media boundary

Generated image nodes, canvas backgrounds, and voice notes contain semantic
bindings and display/limit instructions only. They never contain user media
bytes, local paths, or Photos identifiers. The
host's `LocalAssetStore` maps `(project ID, binding)` to an opaque local asset,
normalizes selected images to bounded JPEGs, strips source metadata through
re-encoding, stores validated AAC voice clips up to 1 MiB, applies data
protection, and excludes the asset directory from backup. Duplicate and delete
operations include both image and audio assets. Recording first uses a protected,
backup-excluded staging directory; the next app launch removes any crash
leftovers. Full app regeneration reconciles voice bindings, preserving a clip
only while the resulting document still references it.

The builder sends only the semantic slot and visual metadata to the model.
Runtime AI does not read the asset store. A user-selected Design Studio canvas
photo stays at the host-owned `design-canvas-background` binding and cannot be
replaced by model output; local voice bytes likewise never enter a generation or
runtime-AI request. The speech adapter can read only the explicitly linked local
voice binding after a tap, requires an on-device model, and exposes editable text
for review. Only the accepted text state—not the audio—may then be used as a
visible, editable AI input prefill.

## AI inside a mini app

`ai.complete` is not a general model tool or autonomous agent. It is a fixed
host component with a focused, document-defined text task. The user enters text
or edits a visible state prefill such as an accepted transcript, then reviews
the exact task and payload in a confirmation sheet.
Only after confirmation does the host make a direct Responses API request using
the user's Keychain-backed credential. Images, other controls, task data, other
projects, and the document itself are excluded. The AI badge and disclosure are
host UI and cannot be removed by the generated theme.

## Generation loop

Full-app generation follows a reviewable replacement loop:

```text
goal → acceptance tasks → draft document → validate → preview/smoke test
     → diagnostics → JSON patch → user review → immutable active version
```

The last known-good version stays runnable if generation or migration fails.
Permission, external data sharing, destructive migrations, and AI cost changes
must appear as a user-visible diff before activation.

Design-only generation is intentionally narrower:

```text
style request → GPT-5.6 structured proposal → host design-only merge
              → validate → native preview + change summary → one new version
```

## Product boundary

Every generated app remains a project inside MakeYour. It does not gain its own
process, bundle identifier, entitlement, extension, or App Store identity. The
host can only expose capabilities that were compiled, signed, reviewed, and
declared in advance.

An optional future Mac service could export an Xcode project for users who need
a standalone app. Compilation and distribution would then happen through Xcode,
TestFlight, and App Store Connect, outside the iPhone runtime.

Calling the document “JSON” does not automatically make it App Store-safe.
[App Review Guideline 2.5.2](https://developer.apple.com/app-store/review/guidelines/)
prohibits downloading or executing code that changes an app's functionality,
while section 4.7 provides a separate, higher-compliance path for certain mini
apps. MakeYour's MVP therefore keeps a fixed host feature catalog, private
projects, bounded actions, and no general-purpose scripting. The team should
seek early App Review guidance before broadening the action graph or exposing
native capabilities.

Entitlements are part of the signed host binary, so generated projects cannot
add them at runtime. See Apple's
[Entitlements documentation](https://developer.apple.com/documentation/bundleresources/entitlements).
Provider data disclosure and explicit consent follow Apple's
[Generative AI HIG](https://developer.apple.com/design/human-interface-guidelines/generative-ai),
and small credentials are stored using
[Keychain Services](https://developer.apple.com/documentation/security/keychain-services).

## MVP catalog

- App Library: create, duplicate, switch, and delete private projects.
- Builder: prompt, deterministic preview, and generated-document replacement.
- Runtime: hero, text, metric, input, picker, button, checklist, task list,
  typed text/number/boolean/date/list/object state, date/time and
  toggle/slider/stepper/progress controls, collection views, finite decimal/date/
  collection calculations and conditions, ordered foreground events,
  currency converter, generic record collections, a typed ledger,
  fixed-provider exchange/news/market views, playable Snake and original
  platform games, bounded custom rule-driven games, image slots, camera and code/text scanning, one-time location,
  contact/file pickers, MapKit place views, reviewed write-only calendar events,
  reviewed document export, foreground local voice notes, reviewed on-device
  speech transcripts, pedometer,
  share/clipboard/haptics, text-only AI
  assistants, banners, dividers, navigation, page layouts, and presentation
  tokens.
- BYOK: OpenAI Responses API; editable model; device-only Keychain storage.
- Samples: a composable hydration tracker, a custom Star Garden game, live news,
  a market watchlist, a personal ledger, original platform and Snake games, a
  camera/QR capture kit, Live FX Watch, Use It First, an
  editorial currency converter, a local task reminder, and a photo-and-AI
  journal starter.

Future releases should add schemaful record relationships and bounded collection
filter/sort/iteration primitives, moving-platform and dynamic-solid game
physics, versioned JSON Patch editing, per-project SQLite namespaces, automated
accessibility and snapshot checks, live microphone dictation, and additional
narrowly reviewed capabilities such as precompiled App Intents.
