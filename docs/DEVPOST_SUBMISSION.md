# OpenAI Build Week submission

Devpost project `1342394` is submitted to OpenAI Build Week as submission
`1094239` at `https://devpost.com/software/makeyour`. The public demo is
`https://youtu.be/gIKuI1H-lH4`, and the judging repository is
`https://github.com/gn00295120/make-your-ios`.

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

## What it does

- Stores a user's OpenAI API key in device-only iOS Keychain storage.
- Sends the builder prompt and current app document directly from the device to
  the OpenAI Responses API.
- Uses GPT-5.6 Structured Outputs to produce a strict, versioned app document.
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
  → validator + native SwiftUI runtime
```

The generated document is deliberately not arbitrary Swift, JavaScript, or
WebAssembly. It selects from a catalog of precompiled components and declared
capabilities. The current catalog covers hero content, text, metrics, inputs,
pickers, actions, checklists, currency, tasks, generic records, news, markets,
ledgers, deterministic games, private images, device inputs, text-only AI
assistants, and information banners. Design Genome v2 adds semantic tokens,
four real page compositions, safe media treatments, and per-renderer variants
without arbitrary generated layout code. The runtime owns every side effect.

Codex was used throughout the build to turn the product thesis into the
architecture, SwiftUI implementation, validation boundary, tests, lint-clean
refactors, and simulator verification. GPT-5.6 is used inside the product because
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

## Accomplishments

- A coherent, runnable product rather than a static concept prototype.
- Ten functional native mini apps available on first launch, including two
  examples generated through MakeYour's own Builder: Live FX Watch and Use It First.
- A real GPT-5.6 demo that creates Daily Focus from a prompt, evolves it from
  Version 2 to Version 3 while preserving a completed task, and switches among
  several distinct mini apps.
- Real Responses API Structured Outputs integration.
- Real in-mini-app Responses API text completion with per-request review.
- Real Keychain round-trip and local-notification scheduling.
- Persistent multi-app library with replacement versions.
- Project-local, metadata-stripped image persistence with duplicate/delete lifecycle.
- Design Genome v2, Design Studio, and a function-preserving AI Design-only path.
- 109 passing unit tests, three passing Design Studio UI paths, a passing live
  GPT-5.6 generation E2E, and a zero-violation strict SwiftLint run across 105
  Swift files.
- Visual verification of editorial, split/card, and immersive treatments on an
  iPhone 17 Pro Simulator.

## What we learned

The useful “new language” is not a syntax that people should write. It is the
contract between AI and a deterministic runtime. Natural language remains the
user interface; JSON Schema is the generation boundary; typed Swift models are
the execution boundary.

## What's next

- Safe expression ASTs and richer local relationships between records.
- Versioned JSON Patch feature edits and cross-version rollback.
- Per-project SQLite namespaces and migrations.
- Broader automated accessibility and snapshot diagnostics fed back to the model.
- Additional carefully reviewed capabilities for calendar, location, share, and
  allowlisted HTTPS data sources.
- Early App Review guidance before broadening runtime programmability.

## Final demo storyboard (1:35.30)

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

- [x] Add the public repository URL and MIT license.
- [x] Record and verify a clear, narrated 1:35.30 video covering Codex and GPT-5.6.
- [x] Upload it publicly to YouTube and verify the submitted link.
- [x] Show Codex and GPT-5.6 usage explicitly in the voiceover.
- [x] Enter Codex Session ID `019f6ea0-c425-7813-b991-2cccb37d8c1e`.
- [x] Publish the judging repository at
  `https://github.com/gn00295120/make-your-ios`.
- [x] Submit as `Individual` from `Taiwan` to `Apps for Your Life`.
- [x] Clone the public repository, regenerate the Xcode project, and pass all 43
  tests using the README instructions.
- [x] After submission, expand the current source to Design Genome v2 and pass
  109 unit tests, three Design Studio UI paths, and one live GPT-5.6 E2E.
- Replace any placeholder project name only after updating the bundle display
  name, README, screenshots, and narration together.
- [x] Submit to OpenAI Build Week; Devpost returned `Submitted` at
  `2026-07-17T19:37:24.389-04:00`.
