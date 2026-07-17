# OpenAI Build Week submission draft

Live Devpost project `1342394` is now published as `MakeYour` at
`https://devpost.com/software/makeyour`, but it has not yet been submitted to the
hackathon. The public repository is
`https://github.com/gn00295120/make-your-ios`; the YouTube URL and required
submission answers still need to be attached.

## Working project name — owner must make the final choice

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
  backgrounds, page layouts, component surfaces, spans, emphasis, and variants.
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
pickers, actions, checklists, a currency converter, task lists, generic record
collections, fixed-provider live-data lists, private images, text-only AI
assistants, and information banners. A bounded visual grammar makes these apps
meaningfully distinct without arbitrary generated layout code. The runtime owns
every side effect.

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
We split semantic components from presentation tokens, added six coherent visual
directions and multiple page compositions, and kept accessibility behavior under
the native runtime's control.

## Accomplishments

- A coherent, runnable product rather than a static concept prototype.
- Four functional native mini apps available on first launch, including two
  examples generated through MakeYour's own Builder: Live FX Watch and Use It First.
- A real GPT-5.6 demo that creates both Travel Budget and Daily Focus from
  prompts, then evolves Daily Focus from Version 2 to Version 3 while preserving
  the user's completed task.
- Real Responses API Structured Outputs integration.
- Real in-mini-app Responses API text completion with per-request review.
- Real Keychain round-trip and local-notification scheduling.
- Persistent multi-app library with replacement versions.
- Project-local, metadata-stripped image persistence with duplicate/delete lifecycle.
- 43 passing tests and a zero-violation strict SwiftLint run.
- Visual verification on iPhone 17 Pro Simulator in light mode.

## What we learned

The useful “new language” is not a syntax that people should write. It is the
contract between AI and a deterministic runtime. Natural language remains the
user interface; JSON Schema is the generation boundary; typed Swift models are
the execution boundary.

## What's next

- Safe expression ASTs and richer local relationships between records.
- JSON Patch edits, immutable published versions, undo, and rollback.
- Per-project SQLite namespaces and migrations.
- Automated accessibility and snapshot diagnostics fed back to the model.
- Additional carefully reviewed capabilities for calendar, location, share, and
  allowlisted HTTPS data sources.
- Early App Review guidance before broadening runtime programmability.

## Final demo storyboard (1:15.30)

- **0:00** — Core concept and real AI Key screen: MakeYour is a personal app
  workshop built for OpenAI Build Week; the user's key is hidden and GPT-5.6 is
  selected.
- **0:13** — Prompt 01: create a Travel Budget converter, open the generated
  native app, enter 2,500 USD, and use the 2,300 EUR result.
- **0:32** — Prompt 02: create a different Daily Focus app with three tasks,
  persistent data, and local reminder actions.
- **0:43** — Evolve that same app: complete a task, return to Builder, ask for a
  calm green design and an evening reflection, then open Version 3 with the
  completed task still intact.
- **0:59** — How Codex shaped and verified the schema, validator, SwiftUI runtime,
  safety boundary, tests, and App Store release pipeline.
- **1:08** — Closing product thesis: make a tiny app once, then keep improving it
  whenever life changes.

The final recording shows the AI Key screen so the BYOK product model is clear,
but the saved value remains hidden and no credential is exposed. The first 59.1
seconds are built around real Simulator workflows; short end-frame holds only
give the narration room. The footage demonstrates two separate prompt-to-app
flows and a real Version 2 → Version 3 update rather than relying on a feature
montage or static screenshots.

## Before submission

- [x] Add the public repository URL and MIT license.
- [x] Record and verify a clear, narrated 1:15.30 video covering Codex and GPT-5.6.
- Upload it publicly to YouTube and verify the submitted link.
- [x] Show Codex and GPT-5.6 usage explicitly in the voiceover.
- Run `/feedback` and enter the resulting Codex Session ID.
- [x] Publish the judging repository at
  `https://github.com/gn00295120/make-your-ios`.
- Select a submission category and confirm all invited team members accepted.
- Run the clean-clone build instructions.
- Replace any placeholder project name only after updating the bundle display
  name, README, screenshots, and narration together.
- Review the Devpost text and publish manually.
