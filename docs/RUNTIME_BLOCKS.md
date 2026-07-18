# Composable runtime blocks

MakeYour exposes a bounded native vocabulary rather than generating Swift. GPT
chooses and connects these blocks; the host validates, compiles, renders, and
executes them. A block is considered available only when the document model,
strict generation schema, converter, validator, renderer or engine, and tests all
ship together.

## Shipping layers

| Layer | Available blocks | Important boundary |
| --- | --- | --- |
| Structure | 1–3 focused pages, start page, segmented/chip/menu navigation, flow/dashboard/form/story layouts | Maximum page/node budgets; no arbitrary view tree |
| Presentation | semantic palette, light/dark canvas and surface, typography, type scale, title weight, density, corners, elevation, stroke, controls, motion, component spans/surfaces/alignment/variants | Native Dynamic Type and accessibility constraints win over generated styling |
| Scalar state | text, number, boolean; session or project persistence | At most 64 declared keys; project-local namespace |
| Inputs | text input, decimal input, picker, toggle, slider, stepper | Values write only their declared binding |
| Outputs | dynamic text, metric, banner, button label, progress, bounded `{{key}}` templates | At most 32 references and 2,000 output characters |
| Events | `tap`, `valueChanged`; up to 4 events per node and 8 ordered steps per event | Steps cannot emit another event, loop, or recurse |
| Expressions | literal, copy, concatenate, add, subtract, multiply, divide, min, max | Flat operands only; bounded decimal magnitude; divide-by-zero fails closed |
| Conditions | equals, not-equals, numeric ordering, empty, non-empty | Typed validation before activation |
| Effects | set state, page navigation, in-app message, reviewed local notification, success haptic | Host derives capabilities and owns OS permission prompts |
| Specialized data | task reminders, generic typed record collections, ledger, FX converter/watchlist, news, market watchlist | Each is a compiled adapter with isolated persistence; arbitrary SQL/HTTP is unavailable |
| Media and device | private image slots plus the 11 device actions in the capability catalog | Tap initiated, sanitized, bounded, and hardware-gated |
| AI | reviewed text-only assistant with optional result binding | User confirms the exact payload; no automatic project/device context |
| Games | Snake/platformer presets plus Tiny Game Program v2 | Deterministic fixed-step interpreter; no downloaded or executable game code |

## Tiny Game Program v2

Custom games can combine:

- an integer-coordinate world with gravity and solid, clamp, wrap, bounce, or
  destroy edge behavior;
- integer/boolean variables with declared ranges;
- rectangle, circle, and allowlisted SF Symbol entity templates;
- static, kinematic, and dynamic bodies with player-axis or constant movement;
- initial entities, four-way/horizontal controls, and action buttons that spawn
  known templates;
- start, fixed-tick, contact-begin, and leave-world triggers;
- typed variable conditions and ordered set/add, velocity, spawn, destroy,
  feedback, win, and loss effects; and
- score/lives/variable HUD items, seeded randomness, pause, restart, and a
  permanent host exit menu.

The compiler rejects missing or unreachable tags, partially out-of-bounds
initial entities, invalid movement/body combinations, excessive aggregate rule
budgets, and invalid target contexts. The engine caps runtime entities, spawns,
effects, contacts, and catch-up ticks. Custom v2 games target top-down collectors,
dodgers, and simple shooters; solid platform collision and jumping use the
precompiled platformer preset today.

## How common personal apps compose

- Water, habit, budget, tip, unit, dosage, and countdown tools combine scalar
  state, numeric controls, arithmetic, conditions, persistence, and dynamic
  metrics.
- Forms, preference panels, decision helpers, onboarding flows, and quizzes
  combine inputs, pickers, toggles, navigation, conditions, and messages.
- Pantry, subscription, inventory, reading, medication, and expense apps use
  typed record collections or the ledger, with optional reminders.
- Camera utilities and field tools combine device results with dynamic state and
  explicit share/copy actions.
- AI writing, planning, tutoring, and transformation tools use the reviewed
  assistant, then bind its result into another native component or event.
- Original arcade ideas use the custom game interpreter; polished Snake and
  platform jumping use their dedicated presets.

## Deliberate gaps

“Composable” does not mean arbitrary or Turing-complete. The current scalar
graph cannot iterate a collection, mutate specialized task/ledger records, run a
background timer, call an arbitrary URL, load a plugin, or create a new Apple
entitlement. Date/list/object state, collection query/mutation actions, richer
game physics, audio, maps, calendar, Shortcuts, and extension targets require new
typed host blocks, privacy boundaries, schema changes, and release tests before
GPT may use them.

This is the platform expansion rule: add the smallest typed primitive that
unlocks several real app categories, then ship its validator, capability
derivation, native failure states, accessibility behavior, and tests as one
unit. Never solve a missing block by accepting generated code.
