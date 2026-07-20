# OpenAI Build Week submission

Devpost project `1342394` is submitted to OpenAI Build Week as submission
`1094239` at `https://devpost.com/software/makeyour`. The updated public demo is
`https://youtu.be/Qjo_44nRUdg`, and the judging repository is
`https://github.com/gn00295120/make-your-ios`. The approved public TestFlight
build is available at `https://testflight.apple.com/join/3Rnqg5Ds`.

## Project name

MakeYour

## Tagline

The iPhone app that makes the tiny apps you wish already existed.

## One-line pitch

MakeYour turns a sentence into a private, native mini app — a converter, task
reminder, tracker, checklist, or personal workflow — and keeps all of them in
one iPhone app that can evolve through conversation.

## Inspiration

Modern vibe coding makes software creation dramatically easier, but people keep
rebuilding the same small products: one more calculator, one more tracker, one
more reminder app. Most users do not actually want another repository, build
pipeline, account, and App Store download. They want one small capability that
fits their life right now.

MakeYour asks a different question: what if those repeated apps were not separate
products at all? What if a person could describe the tool they need, use it
immediately inside one trusted host, and change it later with another sentence?

## Try it

MakeYour 1.0.0 build 4 is approved for public TestFlight testing:
[Join the public TestFlight](https://testflight.apple.com/join/3Rnqg5Ds).

The twelve seeded tiny apps work without an OpenAI key. Bring your own key only
when you want GPT-5.6 to create or redesign a tiny app from a prompt.

## What it does

- Stores a user's OpenAI API key in device-only iOS Keychain storage.
- Sends the builder prompt and current app document directly from the device to
  the OpenAI Responses API.
- Uses GPT-5.6 Structured Outputs to produce a strict, versioned app document.
- Automatically returns validator diagnostics to GPT-5.6 and continues repair
  revisions until the document is valid or the user cancels.
- Gives GPT-5.6 a catalog of 30 precompiled native blocks and 21 reviewed
  capabilities instead of arbitrary executable code.
- Validates component count, identifiers, content limits, capabilities, and
  schema version before activation.
- Renders the result as native SwiftUI through a fixed component runtime.
- Gives each mini app its own bounded visual identity: theme, typography,
  semantic light/dark palette, type scale, backgrounds, page layouts and
  navigation, controls, motion, component surfaces, spans, emphasis, and
  renderer-compatible variants.
- Includes a native Design Studio with live iPhone preview, presets, custom
  colors, typography, layout, icon, motion, undo/redo, and a private canvas
  photo; the complete edit applies as one app version.
- Offers GPT-5.6 Design-only generation behind a host-owned merge that preserves
  every feature, value, action, binding, data configuration, capability, and
  local media slot.
- Supports project-local photo slots without putting image bytes or paths in the
  generated document or builder prompt.
- Composes a local voice-note block with reviewed on-device speech transcription;
  unsupported languages fail closed and never fall back to network recognition.
- Lets generated apps include focused AI assistants with an exact-payload review
  before every text-only request.
- Keeps multiple private mini apps in an App Library and lets the user switch,
  duplicate, edit, and use them.
- Includes working generic record CRUD, local reminders, and a live exchange-rate
  watchlist that reviewers can use without an API key.

## How we built it

MakeYour is a native SwiftUI app with three layers:

```text
natural-language intent
  → GPT-5.6 strict JSON AppDocument
  → semantic validator + automatic repair
  → capability review + native SwiftUI runtime
```

The generated document is deliberately not arbitrary Swift, JavaScript, or
WebAssembly. It selects from 30 precompiled native blocks and 21 declared,
reviewed capabilities. The current catalog covers hero content, text, metrics, inputs,
pickers, actions, checklists, typed date/list/object state, bounded collection and
date operations, currency, tasks, generic records, news, markets, ledgers,
deterministic games, private images, device inputs, MapKit place views, reviewed
write-only calendar creation, reviewed document export, text-only AI assistants,
local voice notes, reviewed on-device transcripts, and information banners. The
general list/object values are bounded flat string
containers rather than a full structured-record language. Design Genome v2 adds
semantic tokens, four real page compositions, safe media treatments, and
per-renderer variants without arbitrary generated layout code. The runtime owns
every side effect.

Codex was used throughout the build to turn the product thesis into the
architecture, SwiftUI implementation, validation boundary, tests, lint-clean
refactors, simulator verification, demo capture, GitHub handoff, TestFlight
release, and Devpost submission. GPT-5.6 is used inside the product because
designing a coherent mini app requires understanding intent, preserving a
working existing document, and producing a reliable structured replacement.

## Challenges

The hardest problem was not generating UI. It was defining the boundary between
“content” and “code.” A general-purpose generated language would be difficult to
secure, test, and ship on iOS. We instead designed a non-Turing-complete document
format with an allowlisted capability runtime, limits, and a last-known-good
version model.

A second challenge was making BYOK honest. The key is stored with
`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, never written to app documents or
logs, and injected only into the direct provider request. The UI also requires a
clear disclosure before any builder data is sent.

A third challenge was making generated apps feel authored rather than templated.
We split semantic components from Design Genome v2, added six coherent starting
directions, custom semantic palettes, multiple real page compositions and
renderer-specific variants, and kept accessibility behavior under the native
runtime's control. The same genome now powers both manual Design Studio edits
and GPT-5.6 Design-only proposals.

A fourth challenge was making generation failure recoverable. The first complex
TripPilot candidate contained an incompatible expression. MakeYour retained the
prompt, turned semantic validation failures into bounded repair diagnostics, and
kept GPT-5.6 in the loop until revision 1 passed and opened successfully.

## Accomplishments

- A coherent, runnable product rather than a static concept prototype.
- Twelve functional native mini apps available on first launch, including two
  examples generated through MakeYour's own Builder: Live FX Watch and Use It First.
- A real GPT-5.6 TripPilot run in which an invalid first candidate was repaired
  automatically into a working 3-page app with 31 components and 21 reviewed
  capabilities.
- Real Responses API Structured Outputs integration.
- Real in-mini-app Responses API text completion with per-request review.
- Real Keychain round-trip and local-notification scheduling.
- Persistent multi-app library with replacement versions.
- Project-local, metadata-stripped image persistence with duplicate/delete lifecycle.
- Design Genome v2, Design Studio, and a function-preserving AI Design-only path.
- A hardened generated currency runtime verified against the persisted TripPilot
  project at `100 USD = 3,250.00 TWD` and `1 USD = 32.50 TWD`.
- A signed MakeYour 1.0.0 build 4 approved for public external TestFlight testing.
- The current source passes 244 unit tests, the persisted TripPilot currency UI
  test, and strict SwiftLint across 173 Swift files with zero violations. A
  dedicated, explicitly billable GPT-5.6 generation E2E remains available for a
  Simulator with a saved review key.
- Visual verification of editorial, split/card, and immersive treatments on an
  iPhone 17 Pro Simulator.

## What we learned

The useful “new language” is not a syntax that people should write. It is the
contract between AI and a deterministic runtime. Natural language remains the
user interface; JSON Schema is the generation boundary; typed Swift models are
the execution boundary.

## What's next

- Richer schemaful relationships, filtering, and iteration for local records.
- Versioned JSON Patch feature edits and cross-version rollback.
- Per-project SQLite namespaces and migrations.
- Broader automated accessibility and snapshot diagnostics fed back to the model.
- Richer precompiled App Intents, media workflows, and additional allowlisted
  HTTPS data sources with separately reviewed boundaries.
- Early App Review guidance before broadening runtime programmability.

## Replacement demo storyboard (ready for upload, 2:04.20)

- **0:00** — Tour the real My Apps, Builder, and AI Key screens. The OpenAI key
  remains hidden.
- **0:21** — Show the complete TripPilot prompt, then accelerate only the real
  model-wait intervals.
- **0:33** — Preserve the visible semantic-validation failure and automatic
  `Repairing revision 1` transition instead of hiding the first invalid result.
- **0:49** — Complete capability review, enable the generated version, and open
  the real three-page TripPilot runtime.
- **0:54** — Enter the persisted generated app, scroll through its rate data,
  and show the working `100 USD = 3,250.00 TWD` converter.
- **1:06** — Show another tiny app evolving its style and behavior while local
  task state remains intact.
- **1:26** — Switch among several differently designed tiny apps.
- **1:49** — Credit Codex for the schema, validator, repair loop, safety
  boundary, tests, release, and native SwiftUI runtime.

The replacement is `artifacts/devpost/demo/MakeYour-OpenAI-Build-Week-Demo-v2.mp4`.
It is 124.20 seconds, H.264 1080p at constant 30 fps with normalized AAC
narration. Full decode and black-frame scans pass. The source generation run is
210.70 seconds; the edit keeps the prompt, first validation failure, automatic
repair, capability review, and final runtime while accelerating only the two
model-wait intervals. The replacement is public at
`https://youtu.be/Qjo_44nRUdg`, and Devpost project version 8 now uses it. Public
metadata verification confirmed a 2:04 duration, 1920 × 1080 rendition, correct
title, and public availability before the entry was re-submitted.

## Previous demo storyboard (1:35.30)

- **0:00** — Tour the real My Apps, Builder, and AI Key screens. The OpenAI key
  remains hidden.
- **0:21** — Create Daily Focus from a real prompt with three tasks and a local
  reminder; the generation wait is shortened and labeled.
- **0:37** — Complete a task, request a calm green design and evening reflection,
  then open Version 3 with the completed task still intact.
- **0:57** — Return to My Apps and switch among a travel budget converter, live
  currency alerts, a private food journal, and other mini apps.
- **1:20** — Explain how Codex helped build and test the schema, validator, safety
  boundary, and native SwiftUI runtime.
- **1:28** — Close on the product thesis: one app, your tiny apps, continuously
  adaptable.

The first 80 seconds use real iOS Simulator operation. The footage demonstrates
one prompt-to-app creation, one real Version 2 → Version 3 update with retained
task state, and switching among distinct mini apps. The generation wait is
shortened and labeled; no credential is exposed. The Codex credit and closing
line use a held frame from the real app library rather than concept mockups.

## Submission status

- [x] Add the public repository URL, PolyForm Shield license, and unrestricted
  OpenAI Build Week judging grant through the end of the judging period.
- [x] Record and verify a clear, narrated 1:35.30 video covering Codex and GPT-5.6.
- [x] Upload it publicly to YouTube and verify the submitted link.
- [x] Show Codex and GPT-5.6 usage explicitly in the voiceover.
- [x] Enter Codex Session ID `019f6ea0-c425-7813-b991-2cccb37d8c1e`.
- [x] Publish the judging repository at
  `https://github.com/gn00295120/make-your-ios`.
- [x] Verify judging access: the repository is public as of 2026-07-20. If its
  visibility changes to private, share it with `testing@devpost.com` and
  `build-week-event@openai.com` before 2026-07-21 5:00 PM PT, and retain access
  through the end of judging on 2026-08-05 5:00 PM PT.
- [x] Submit as `Individual` from `Taiwan` to `Apps for Your Life`.
- [x] Clone the public repository, regenerate the Xcode project, and pass all 43
  tests using the README instructions.
- [x] After submission, expand the current source to Design Genome v2 and pass
  109 unit tests, three Design Studio UI paths, and one live GPT-5.6 E2E.
- [x] Expand the runtime further to 19 reviewed capabilities, typed collections,
  native map/calendar/export/voice blocks, Tiny Game v3, 203 unit tests, and nine
  non-billable UI tests.
- [x] Add the 20th reviewed capability: tap-initiated, on-device-only transcription
  of a linked local voice note with editable review and atomic text-state commit.
- [x] Add the 21st reviewed capability: an AI-selectable `shortcutAccess` opt-in
  backed by one authenticated foreground App Intent and a fail-closed dynamic
  Tiny App entity catalog.
- [x] Upload build 2 to App Store Connect, receive external TestFlight approval,
  and attach it to the public `Devpost Judges` group without replacing build 1
  in App Store review.
- [x] Add continuous validator-guided GPT-5.6 repair, prove it with the complex
  TripPilot generation, and record the full generation-to-runtime session.
- [x] Fix and harden generated currency conversion, pass 244 unit tests and the
  persisted TripPilot UI test, and publish externally approved TestFlight build 4.
- [x] Update the live Devpost project to version 7 and re-submit submission
  `1094239`; Devpost returned `Submitted` while submissions remained open.
- [x] Produce a 2:04.20 replacement demo with the real TripPilot generation,
  automatic repair, working generated currency conversion, natural OpenAI TTS
  narration, English subtitles, and no black-frame transition.
- [x] Publish and verify the replacement YouTube upload, update live Devpost
  project version 8, and re-confirm submission `1094239` is `Submitted`.
- Replace any placeholder project name only after updating the bundle display
  name, README, screenshots, and narration together.
- [x] Submit to OpenAI Build Week; Devpost returned `Submitted` at
  `2026-07-17T19:37:24.389-04:00`.
