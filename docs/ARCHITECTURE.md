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
vocabulary declares:

- `storage.local`
- `calculation.safe`
- `notifications.scheduleLocal`
- `photo.pick`
- `camera.capture`
- `camera.scanCode`
- `location.current`
- `contacts.pick`
- `files.import`
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

Device components are native host adapters. The current catalog includes camera
capture, QR/barcode/text scanning, one-time foreground location, Apple’s
single-contact picker, bounded text-file import, one-time pedometer reads,
reviewed sharing, clipboard writes, and haptic feedback. They request access
only after a tap, check availability, sanitize and bound outputs, persist results
within the project boundary, and never open scanned URLs or forward results to
AI by default. Adding a generated version that needs a new capability first
presents a host-controlled review sheet.

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

## Private media boundary

Generated image nodes and canvas backgrounds contain a semantic binding and
display instructions only. They never contain user image bytes, local paths, or
Photos identifiers. The
host's `LocalAssetStore` maps `(project ID, binding)` to an opaque local asset,
normalizes selected images to bounded JPEGs, strips source metadata through
re-encoding, applies data protection, and excludes the asset directory from
backup. Duplicate and delete operations include the project's private assets.

The builder sends only the semantic slot and visual metadata to the model.
Runtime AI does not read the asset store. A user-selected Design Studio canvas
photo stays at the host-owned `design-canvas-background` binding and cannot be
replaced by model output.

## AI inside a mini app

`ai.complete` is not a general model tool or autonomous agent. It is a fixed
host component with a focused, document-defined text task. The user enters or
chooses text, then reviews the exact task and payload in a confirmation sheet.
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
  currency converter, generic record collections, a typed ledger,
  fixed-provider exchange/news/market views, playable Snake and original
  platform games, image slots, camera and code/text scanning, one-time location,
  contact/file pickers, pedometer, share/clipboard/haptics, text-only AI
  assistants, banners, dividers, navigation, page layouts, and presentation tokens.
- BYOK: OpenAI Responses API; editable model; device-only Keychain storage.
- Samples: live news, a market watchlist, a personal ledger, original platform
  and Snake games, a camera/QR capture kit, Live FX Watch, Use It First, an
  editorial currency converter, a local task reminder, and a photo-and-AI
  journal starter.

Future releases should add safe expression ASTs, versioned JSON Patch editing,
per-project SQLite namespaces, automated accessibility and snapshot checks, and
additional narrowly reviewed fixed-provider capabilities.
