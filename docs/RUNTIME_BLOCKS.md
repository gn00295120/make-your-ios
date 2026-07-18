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
| Typed state | text, number, boolean, canonical date, bounded string list, bounded string object; session or project persistence | At most 64 declared keys; lists/objects have at most 64 flat string entries and are not nested records |
| Inputs | text input, decimal input, picker, toggle, slider, stepper, date picker, time picker, date-time picker | Values write only their declared binding and native date controls store canonical timestamps |
| Outputs | dynamic text, metric, banner, button label, progress, `collectionView`, bounded `{{key}}` templates | At most 32 references and 2,000 output characters; normal UI templates summarize structured values, while the reviewed export block may expose their canonical JSON |
| Events | `tap`, `valueChanged`, one-time `appear`, foreground `timer`; one event per trigger and up to 8 ordered steps per event | Timer interval is 1–3,600 seconds and runs only while the node is rendered and the scene is active; no background catch-up |
| Expressions | literal, copy, concatenate, decimal arithmetic, list append/remove/count/contains/join, object set/remove/get/count, date add-days/days-between | Flat operands only; collection and numeric budgets fail closed; no iteration, callback, or nested expression tree |
| Conditions | equals, not-equals, numeric/date ordering, logical empty, non-empty | Typed validation before activation |
| Effects | set state, page navigation, in-app message, reviewed local notification, success haptic | Host derives capabilities and owns OS permission prompts |
| Specialized data | task reminders, generic typed record collections, ledger, FX converter/watchlist, news, market watchlist | Each is a compiled adapter with isolated persistence; arbitrary SQL/HTTP is unavailable |
| Media and device | private image and voice-note slots plus the 11 device actions in the capability catalog | Tap initiated, sanitized, bounded, foreground-only where applicable, and hardware-gated |
| Native services | MapKit coordinate/place display and search, reviewed write-only calendar event, reviewed text/JSON/CSV export, local AAC voice note | Fixed host adapters; no location history, calendar reads, silent route/file handoff, background recording, or audio upload |
| AI | reviewed text-only assistant with optional result binding | User confirms the exact payload; no automatic project/device context |
| Games | Snake/platformer presets plus Tiny Game Program v3 | Deterministic fixed-step interpreter; no downloaded or executable game code; stored V2 programs remain compatible |

## Typed values and foreground automation

Date values accept an ISO 8601 timestamp or a date-only input and are normalized
to a canonical UTC timestamp. The `currentDate` operand, date ordering,
`dateAddDays`, and `dateDaysBetween` support finite scheduling and countdown
logic. Native date, time, and date-time controls present the value in the user's
locale while retaining that canonical storage form.

Lists encode at most 64 strings of at most 240 characters each. Objects encode
at most 64 non-empty string keys mapped to string values, with 60-character keys
and 240-character values. Their mutation/query operations are transactional,
and `collectionView` renders the resulting rows without exposing raw JSON. These
containers do not support nested objects, schemaful records, sorting/filtering,
or iteration; use the specialized `recordCollection` block when a tiny app needs
rich editable records.

An `appear` event runs once for a rendered node instance. A timer event has one
validated interval and dispatches only while that node remains rendered and the
iOS scene is active. It is a UI automation primitive, not background execution:
the host neither catches up missed ticks nor schedules silent work after the app
leaves the foreground.

## Native map, calendar, export, and voice blocks

- `map` renders a bounded MapKit region for a configured coordinate or Apple
  Maps place query, keeps optional search visible, returns at most eight markers,
  and opens directions only after the user taps. It does not request the user's
  location or contact arbitrary map providers.
- `calendarEvent` resolves bounded text templates into a visible review sheet,
  optionally lets the user edit the event, and requests EventKit write-only
  access only when the user confirms. It adds one event to the default writable
  calendar and cannot list, read, edit, or delete existing events.
- `documentExport` shows the resolved content before export, enforces a maximum
  of 2,000 characters/8 KB for plain text, JSON, or CSV, validates JSON syntax,
  sanitizes the filename, and opens Apple's `fileExporter`. This explicitly
  reviewed surface may resolve a list or object to its canonical JSON; ordinary
  UI templates still show only a summary. It cannot silently select or
  overwrite a destination.
- `voiceNote` requests microphone permission only after the user taps Record,
  captures one 5–60 second mono AAC clip into a project-local binding, stops at
  the configured limit or when the app leaves the foreground, and always offers
  playback, pause/resume, replacement, and deletion. The clip is capped at 1 MiB,
  checked for a playable M4A container before persistence, protected with the
  project's local assets, and never uploaded or transcribed. A protected staging
  file exists only while recording; crash leftovers are removed on the next app
  launch. Regeneration keeps clips for still-referenced bindings and deletes
  clips whose voice blocks were removed.

## Tiny Game Program v3

Custom games can combine:

- an integer-coordinate world with gravity and solid, clamp, wrap, bounce, or
  destroy edge behavior;
- integer/boolean variables with declared ranges;
- rectangle, circle, and allowlisted SF Symbol entity templates;
- static, kinematic, and dynamic bodies with sensor, solid, or one-way-platform
  collision plus player-axis, platformer-axis, or constant movement;
- initial entities, four-way/horizontal controls, grounded jump actions, and
  facing projectile actions with cooldown, lifetime, and active-count limits;
- start, fixed-tick, contact-begin, and leave-world triggers;
- typed variable conditions and ordered set/add, velocity, spawn, destroy,
  feedback, win, and loss effects; and
- score/lives/variable HUD items, seeded randomness, pause, restart, and a
  permanent host exit menu.

The compiler rejects missing or unreachable tags, partially out-of-bounds
initial entities, invalid movement/body/physics combinations, excessive
aggregate rule budgets, runtime-spawned solids, and invalid target contexts. The
engine caps velocities, runtime entities, spawns, effects, contacts, action
cooldowns, projectiles, lifetimes, and catch-up ticks. Swept sensor collision
keeps fast projectiles from skipping targets. V3 supports a single dynamic solid
player against static solid or one-way platforms; moving platforms and
dynamic-vs-dynamic solids fail closed. Stored V2 programs retain their original
sensor-only behavior.

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

“Composable” does not mean arbitrary or Turing-complete. The current behavior
graph cannot iterate a collection, represent nested or schemaful records in its
flat list/object state, mutate specialized task/ledger records, run a background
timer, call an arbitrary URL, load a plugin, or create a new Apple entitlement.
Moving-platform or dynamic-solid game physics, speech recognition, App Intents
or Shortcuts, and extension targets still require new
typed host blocks, privacy boundaries, schema changes, and release tests before
GPT may use them.

This is the platform expansion rule: add the smallest typed primitive that
unlocks several real app categories, then ship its validator, capability
derivation, native failure states, accessibility behavior, and tests as one
unit. Never solve a missing block by accepting generated code.
