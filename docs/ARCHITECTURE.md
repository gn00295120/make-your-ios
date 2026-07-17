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
- `http.request`
- `ai.complete`

Each request passes through manifest declaration, host availability, per-project
user grant, operating-system permission, execution limits, and result
sanitization. The current runtime implements local UI/state, calculations,
explicit local notifications, user-selected project-local photos, and reviewed
text-only AI completion. General HTTP is reserved in the manifest but is not
exposed as an arbitrary generated network primitive.

## Visual grammar

The DSL separates meaning from presentation. A component remains a metric,
task list, image, or AI assistant, while safe presentation tokens control its
native SwiftUI rendering:

```text
theme: appearance + typography + background + corner + density + default surface
page:  flow | dashboard | form | story
node:  surface + span + alignment + emphasis + semantic variant
```

Six presets (`native`, `minimal`, `soft`, `editorial`, `playful`, and `bold`)
provide coherent starting points. The AI can combine the tokens instead of
falling back to a universal card stack. There are no arbitrary frames, custom
CSS, downloaded fonts, shaders, or executable layout expressions. Dynamic Type
can collapse multi-column rows back to one column.

## Private media boundary

Generated image nodes contain a semantic binding and display instructions only.
They never contain user image bytes, local paths, or Photos identifiers. The
host's `LocalAssetStore` maps `(project ID, binding)` to an opaque local asset,
normalizes selected images to bounded JPEGs, strips source metadata through
re-encoding, applies data protection, and excludes the asset directory from
backup. Duplicate and delete operations include the project's private assets.

The builder sends only the semantic slot to the model. Runtime AI does not read
the asset store.

## AI inside a mini app

`ai.complete` is not a general model tool or autonomous agent. It is a fixed
host component with a focused, document-defined text task. The user enters or
chooses text, then reviews the exact task and payload in a confirmation sheet.
Only after confirmation does the host make a direct Responses API request using
the user's Keychain-backed credential. Images, other controls, task data, other
projects, and the document itself are excluded. The AI badge and disclosure are
host UI and cannot be removed by the generated theme.

## Generation loop

Production generation should become a repair loop rather than a single prompt:

```text
goal → acceptance tasks → draft document → validate → preview/smoke test
     → diagnostics → JSON patch → user review → immutable active version
```

The last known-good version stays runnable if generation or migration fails.
Permission, external data sharing, destructive migrations, and AI cost changes
must appear as a user-visible diff before activation.

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
  currency converter, generic record collections, fixed-provider live-data
  watchlists, image slots, text-only AI assistants, banners, dividers,
  navigation, page layouts, and presentation tokens.
- BYOK: OpenAI Responses API; editable model; device-only Keychain storage.
- Samples: AI-generated Live FX Watch and Use It First projects, an editorial
  currency converter, a soft local task reminder, plus an optional photo-and-AI
  journal starter.

Future releases should add safe expression ASTs, versioned JSON Patch editing,
per-project SQLite namespaces, automated accessibility and snapshot checks, and
additional narrowly reviewed fixed-provider capabilities.
