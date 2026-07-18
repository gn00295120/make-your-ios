# Design Genome v2

Design Genome v2 is MakeYour's bounded design language for native tiny apps. It
allows visibly different products without asking GPT-5.6 to generate executable
layout code. The document describes intent; the signed SwiftUI runtime owns the
rendering, accessibility behavior, media access, and every side effect.

## Design contract

The genome has four layers:

```text
brand       palette + app icon + tint
foundation  type + canvas + density + shape + elevation + stroke + motion
composition page layout + page navigation + component placement
expression  component variant + surface + emphasis + media treatment
```

All fields are Codable, schema-constrained, and validated before activation.
Older documents remain valid because v2 fields resolve through their preset
defaults.

## Theme tokens

| Token | Allowed values or shape | Purpose |
| --- | --- | --- |
| Preset | native, minimal, soft, editorial, playful, bold | Coherent starting point |
| Appearance | system, light, dark | Color-scheme preference |
| Palette | primary, secondary, accent, light/dark canvas and surface hex colors | Semantic brand colors |
| Typography | system, rounded, serif, monospaced | Native font design |
| Type scale | compact, balanced, editorial, expressive | Hierarchy and rhythm |
| Title weight | regular, semibold, bold, black | Brand voice |
| Background | grouped, plain, tinted, paper, gradient, midnight | Canvas treatment |
| Corner | square, soft, round | Surface radius family |
| Density | compact, regular, airy | Spacing rhythm |
| Default surface | plain, card, tinted, outlined, material | Component fallback |
| Elevation | flat, subtle, floating | Depth without arbitrary shadows |
| Stroke | none, hairline, accent | Boundary treatment |
| Control shape | native, soft, pill, angular | Buttons and interactive controls |
| Motion | none, subtle, expressive | Bounded transition energy |

Custom colors are semantic rather than hard-coded per view. The runtime resolves
the palette once for light or dark mode, then increases contrast when requested
by the accessibility environment.

## Page composition

| Layout | Runtime behavior |
| --- | --- |
| Flow | Natural single-column utility stack |
| Dashboard | Adaptive two-column rhythm for compact summaries, collapsing at large Dynamic Type |
| Form | Grouped, readable input and action sections |
| Story | Editorial full-width sequence for narrative and media-led apps |

Multi-page apps can use automatic, segmented, chips, or menu navigation. The
runtime chooses an honest fallback when the available width or accessibility
size makes a compact navigation treatment unsuitable.

Each component also declares `full`, `half`, or `adaptive` span; leading,
center, or trailing alignment; subtle, regular, or strong emphasis; and one of
the safe surfaces. Layout remains host-owned: the document cannot provide frame
coordinates, CSS, constraints, shaders, or executable expressions.

## Renderer variants

Variants are component-specific contracts, not universal style names.
`RendererCatalog` is the source of truth and prevents unsupported combinations.

| Component family | Distinct variants |
| --- | --- |
| Hero and image | centered, editorial, split, fullBleed, framed, immersive, photoOverlay |
| Metrics and summaries | numberFirst, progress, cards, dense, framed |
| Buttons | outlinedAction, softAction |
| Checklists and tasks | timeline, cards, dense |
| Currency converter | split, framed, dense |
| Records, live data, ledger | cards, dense |
| News | editorial, cards, dense |
| Market | split, cards, dense |
| Games | framed, fullBleed, immersive |
| AI and device tools | cards, framed |

`automatic` and `compact` remain safe fallbacks where supported. Adding a new
variant requires a real renderer, catalog registration, validator coverage,
strict-schema coverage, and light/dark plus accessibility verification.

## Semantic media

Images never use model-provided paths, Photos identifiers, or remote asset
downloads. A document stores only a binding and visual metadata:

- role: content, hero, background, logo, avatar, thumbnail, decorative;
- focal point: center, top, bottom, leading, trailing;
- mask: none, rounded, circle, capsule;
- overlay: none, scrim, tint;
- aspect, content mode, alt text, and whether selection is allowed.

`PhotosPicker` fills the semantic slot. `LocalAssetStore` re-encodes the image,
strips source metadata, applies size limits and data protection, and stores it in
the tiny app's project boundary. Design Studio can fill the reserved
`design-canvas-background` slot. Only that binding is recorded in the document;
the bytes never enter a builder or runtime AI request.

## Accessibility rules

The design is a preference; accessibility is a runtime requirement.

- Dynamic Type can collapse dashboard columns and expand controls.
- Reduce Motion disables continuous and expressive movement.
- Reduce Transparency replaces material-dependent surfaces with opaque ones.
- Increased Contrast strengthens text and surface separation.
- Differentiate Without Color keeps state understandable through labels,
  symbols, strokes, and shape.
- Decorative images are hidden from accessibility; meaningful images require
  alt text.

Design Studio itself is tested at Accessibility Extra Extra Extra Large in
addition to its normal apply, cancel, undo, and redo paths.

## Design Studio transaction

Design Studio edits a working copy and renders it in a live iPhone preview.
Users can apply a preset, then independently adjust palette, typography, page
layout and navigation, density, corner and control shape, elevation, stroke,
motion, icon, and the local canvas image.

Undo and redo operate on the working design. Cancel discards it. Apply validates
the complete `AppDocument` and calls `WorkspaceStore.applyDesign`, creating
exactly one new immutable version for the whole studio session.

## GPT-5.6 Design-only transaction

Design-only generation uses the same strict Structured Outputs schema as full
generation, but the host does not trust the model to preserve behavior.
`AppDocumentDesignMerger` copies only:

- app symbol and tint;
- theme tokens, except the existing local background binding;
- page presentation;
- component presentation;
- image aspect, content mode, alt text, decorative flag, role, focal point,
  mask, and overlay.

The merger keeps the current name, summary, pages, component IDs and kinds,
copy, values, actions, bindings, configurations, capabilities, selection flags,
and user media bindings. Validation runs again, then the user sees a native
preview and concise change summary before applying one new version.

## Extension checklist

Before a new visual ability ships:

1. model it as a bounded semantic token with a backward-compatible default;
2. expose the exact enum or pattern in the strict JSON schema;
3. implement the renderer in every supported environment;
4. register compatible component kinds in `RendererCatalog`;
5. reject invalid colors, media metadata, and variants in the validator;
6. preserve the field correctly in full-app and Design-only transactions;
7. test schema round trips, validation, persistence, light/dark mode, large
   Dynamic Type, and relevant accessibility overrides; and
8. update seeded examples and demo prompts so the capability is visible.

The implementation source of truth starts at
`MakeYourIOS/Models/DesignGenome.swift`,
`MakeYourIOS/Runtime/RendererCatalog.swift`, and
`MakeYourIOS/Features/Builder/AppDocumentDesignMerger.swift`.
