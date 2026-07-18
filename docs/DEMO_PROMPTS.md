# AI Builder demo prompts

These prompts target the current strict `AppDocument` schema and fixed host
capability catalog. A prompt should be called verified only after it has been
generated with the exact release build, passed document validation, and had its
resulting native flow exercised. Never substitute a screenshot-only mock for
that check.

## Demo 1 — Live FX Watch

```text
Create a one-page native mini app named “Live FX Watch”. It should let me choose the primary currency, add and remove currencies from a searchable catalog, refresh the latest available exchange rates, and configure an at-or-below or at-or-above threshold for each row with a Test Alert button that immediately shows an in-app alert.

Use sky tint, a minimal light visual theme, rounded typography, a plain background, soft corners, regular density, and a dashboard layout. Add a centered hero titled “Rates that matter to you” with subtitle “Build a personal watchlist around one home currency.” Then add one subtle infoBanner explaining that these are latest daily reference rates, not streaming trading quotes. Add one full-width liveDataList titled “My rate watchlist”, subtitle “Tap the bell to set a target or test an alert.” Configure resource exchangeRates, primaryValue USD, initialSymbols TWD, JPY, EUR, GBP, and KRW, allowsPrimarySelection true, allowsItemEditing true, and allowsThresholds true. Declare storage.local and http.request. Do not use currencyConverter, static rate items, arbitrary URLs, taskList, or a fake live metric.
```

## Demo 2 — Use It First

```text
Create a one-page private fridge mini app named “Use It First”. Let me keep one device-only fridge photo, track ingredients with quantity and use-by date, schedule local expiry reminders, and ask AI for a recipe using only ingredient text that I explicitly review and send. AI must never claim to read the photo, collection, device data, or other apps.

Use mint tint, playful preset, system appearance, rounded typography, gradient background, round corners, airy density, material default surface, story layout, and hide the navigation title. Do not put every component in the same card style.

In this order add: (1) a full-width editable image titled “What’s in your fridge?”, subtitle “Choose one private fridge photo.”, binding fridge-photo, banner aspect, fill, alt text “A fridge photo selected by the user”, allowsUserSelection true, media role hero, center focal point, no mask, scrim overlay, plain surface, strong emphasis, fullBleed variant; (2) a centered hero titled “Use it before you lose it”, subtitle “Track what expires next, then turn a few ingredients into dinner.”, symbol leaf.fill; (3) a subtle infoBanner titled “Private by design”, subtitle “Your photo and pantry list stay on this iPhone. AI receives only text you review and send.”, symbol lock.shield.fill; (4) a recordCollection titled “Pantry”, subtitle “Add what you want to use first.”, binding pantry-items, itemName Ingredient, titleLabel Ingredient, noteLabel “Where / note”, valueLabel Quantity, valueKind number, valueUnit unit, dateLabel “Use by”, dateKind date, aggregate count, allowsCompletion true, allowsReminders true, with no initial items, cards variant; (5) an aiAssistant titled “15-minute Rescue Chef”, subtitle “Type ingredients yourself. AI cannot read your photo or pantry list.”, placeholder “Example: spinach, eggs, tofu”, quick prompts “spinach, eggs, tofu”, “tomatoes, rice, cheese”, and “banana, oats, yogurt”, button label “Make a recipe”, framed variant. Its task is: “Using only ingredients typed by the user, suggest one realistic 15-minute recipe with a short name, three concise steps, and one optional substitution. Never claim to inspect other data. Do not make medical or nutrition claims.”

Declare storage.local, photo.pick, notifications.scheduleLocal, and ai.complete. Do not add live data, arbitrary HTTP, taskList, external URLs, or fake computed metrics.
```

## Demo 3 — Daily Brief

```text
Create a one-page editorial mini app named “Daily Brief” for collecting and organizing current headlines without an algorithmic social feed. Add a full-width editorial hero titled “News without the noise” and one full-width editorial newsFeed titled “Your briefing”. Use only the built-in sources bbcWorld, bbcTechnology, and nprNews. Start with topic filters technology, climate, science, and world; allow the user to edit topics and bookmark articles; show at most 24 items. Make clear that headlines come from credited publishers, search and topic filtering happen locally, and opening an article goes to its original source.

Use plum tint, editorial preset, light appearance, serif typography, editorial type scale, bold title weight, paper background, square corners, airy density, plain default surface, flat elevation, hairline stroke, angular controls, no motion, a story layout, and menu page navigation. Declare only storage.local and http.request. Do not invent RSS URLs, scrape arbitrary websites, add an AI summary, claim every story is complete or unbiased, or describe cached headlines as guaranteed real-time.
```

## Demo 4 — Market Pocket

```text
Create a one-page native mini app named “Market Pocket” for a personal stock and ETF watchlist. Add a split hero titled “Keep the market in perspective” and one split marketWatch titled “My watchlist”. Configure provider twelveData, initialSymbols AAPL, allowsSymbolEditing true, showsChart true, and range oneMonth. Explain in the subtitle that AAPL works with the provider's public demo access and other symbols may require the user's own Twelve Data API key inside the runtime.

Use sky tint, minimal preset, system appearance, rounded typography, plain background, soft corners, regular density, plain default surface, and a dashboard layout. Declare only storage.local and http.request. Never include an API key in the document, invent another provider or URL, promise streaming or guaranteed real-time prices, provide buy/sell recommendations, or present this as financial advice.
```

## Demo 5 — Pocket Ledger

```text
Create a one-page soft native mini app named “Pocket Ledger” for personal income and expense tracking. Use one full-width ledger titled “This month”. Configure currencyCode TWD, categories Income, Food, Transport, Home, Fun, and Other, period currentMonth, monthlyBudget 30000, and allowsIncome true. Seed three editable examples: an income entry “Freelance payment” for 18000 in Income dated 2026-07-01, an expense “Groceries” for 1280 in Food dated 2026-07-03, and an expense “Metro” for 500 in Transport dated 2026-07-04. Amounts must be positive and each entry must have a short replaceable note.

Use mint tint, soft preset, system appearance, rounded typography, gradient background, soft corners, airy density, material default surface, and a dashboard layout. Give the ledger the cards variant. Explain that entries stay on this iPhone and that the host calculates income, spending, balance, monthly budget progress, and category totals. Declare only storage.local. Do not add fake metrics that duplicate the ledger, bank connectivity, cloud sync, investment advice, or arbitrary network access.
```

## Demo 6 — Skybound original platformer

```text
Create a one-page playable original platform adventure named “Skybound”. Use exactly one immersive game component titled “Cloud Run” with kind platformer, difficulty standard, palette sky, targetScore 8, levelSeed 2026, playerName Nova, collectibleName Star, and haptics true. The subtitle should say “Collect stars and reach the beacon.” Use touch controls, scoring, pause, restart, best score, collisions, hazards, and a finish goal supplied by the host runtime.

Use sky tint, playful preset, system appearance, rounded typography, expressive type scale, black title weight, gradient background, round corners, regular density, plain default surface, floating elevation, pill controls, expressive motion, a story layout, and no navigation title. Declare only storage.local and haptics.play. This must be an original game: do not use Mario, Nintendo, copyrighted characters, copied level layouts, brand names, downloaded art, music, or sound. If the request mentions a famous platform game, translate only the broad mechanic into this original host-owned platformer.
```

## Demo 7 — Neon Snake

```text
Create a one-page complete Snake-style game named “Neon Snake”. Use exactly one framed game component titled “Glow Garden” with kind snake, difficulty standard, palette neon, targetScore 15, levelSeed 86, playerName Glow, collectibleName Spark, and haptics true. The subtitle should say “Guide the trail, collect sparks, and beat your best score.” Use the host runtime's touch direction controls, collision rules, score, pause, restart, win target, and saved best score.

Use plum tint, playful preset, dark appearance, rounded typography, gradient background, round corners, regular density, material default surface, a flow layout, and no navigation title. Declare only storage.local and haptics.play. Do not add network multiplayer, ads, purchases, arbitrary code, downloaded assets, or copyrighted characters.
```

## Demo 8 — Device Lab

```text
Create a two-page native utility mini app named “Device Lab” that demonstrates all 11 currently supported deviceInput actions. Page one, “Capture”, should contain six full-width deviceInput components: cameraPhoto for a receipt photo, qrCode for a QR payload, barcode for a product barcode, text for visible-text scanning, currentLocation for one coordinate, and contact for one Apple-picker-selected contact. Page two, “Use”, should contain documentText for one small UTF-8 text file, pedometer for today's aggregate step count, shareText for the configured text “Made with my tiny app in MakeYour.”, copyText for “Made with MakeYour”, and haptic for one success confirmation. Give every component a unique kebab-case ID and binding, a clear buttonLabel and resultLabel, and allowsRepeat true.

Use amber tint, native preset, system appearance, system typography, plain background, soft corners, regular density, plain default surface, and flow layouts. Add concise subtitles that accurately state these boundaries: every action starts after a tap; camera and scanner are foreground only; QR and barcode results are inert text and never opened automatically; location and pedometer are one-shot rather than background monitoring; the contact picker returns only the selected contact; file import is limited to a selected text, JSON, or CSV document; sharing uses Apple's destination chooser; clipboard access is write-only; and haptics read no data.

Declare storage.local, camera.capture, camera.scanCode, location.current, contacts.pick, files.import, motion.pedometer, share.present, clipboard.write, and haptics.play. Do not declare photo.pick, http.request, notifications.scheduleLocal, or ai.complete. Do not imply that every action works in Simulator; camera capture, live scanning, pedometer, and meaningful haptic verification require supported physical hardware.
```

## Demo 9 — Waterline composable tracker

```text
Create a one-page hydration mini app named “Waterline” using the composable runtime rather than a specialized tracker. Declare project-persisted number state keys water with initial value 0 and goal with initial value 2000. Add a centered hero titled “A calmer way to hydrate”. Add a half-width metric titled “Today” with valueBinding water and subtitle “Daily goal · {{goal}} ml”. Add a half-width progress control titled “Daily progress” bound to water, minimum 0, maximum 2000, step 250, and unit ml. Add three half-width buttons: “Add 250 ml” sets water to water plus 250 and plays a haptic; “Remove 250 ml” first subtracts 250, then uses a second conditional setState step to set water to 0 when the updated value is less than 0; “Reset” sets water to literal 0 only when water is greater than 0. Use tap events and set every legacy action to none. Add one subtle info banner whose text includes “{{water}} of {{goal}} ml”.

Use sky tint, soft preset, light appearance, rounded typography, balanced type scale, bold titles, gradient canvas, soft corners, airy density, subtle elevation, pill controls, subtle motion, and dashboard layout. Declare only storage.local, calculation.safe, and haptics.play. Do not use a hard-coded tracker component, fake metrics, network access, AI, notifications, photos, or device input.
```

## Demo 10 — Original custom game

```text
Create a one-page original top-down tiny game named “Star Garden” using game kind custom and Tiny Game Program version 3. The player controls a small dynamic sensor glider with four-way touch controls inside a bounded dark garden. Place five static sensor collectible stars and three static sensor fire hazards. Give every non-none body an explicit sensor physics block with valid velocity limits and zero lifetime. Contacting a star must add one to a bounded score variable, destroy that star, and play light feedback. Reaching score 5 must win. Contacting a fire hazard must lose. Show score in the HUD and include the host-owned Start, Pause, Restart, and exit controls. Use a deterministic seed, keep every initial entity fully inside the world, and keep all tags, templates, controls, variables, triggers, targets, and effects valid and reachable.

Use amber tint, bold preset, dark appearance, rounded expressive typography, gradient canvas, round corners, regular density, floating elevation, pill controls, expressive motion, story layout, and an immersive game presentation. Use only rectangle, circle, or allowed SF Symbol visuals. Declare storage.local and haptics.play only. Do not use copyrighted names, characters, levels, external images, audio, arbitrary code, network multiplayer, ads, or purchases.
```

Custom game generation is intentionally more demanding than a preset. Before a
competition recording, run this exact prompt on the release build and exercise
all five collections, the hazard loss path, restart, and the host exit menu.

## Demo 11 — Design-only restyle

First open an existing functional tiny app, switch Builder to **Design only**,
and use this prompt. After generation, verify the review summary and confirm the
same records, values, actions, bindings, data provider, capabilities, and local
photo slots remain intact.

```text
Restyle this tiny app as a calm, premium personal tool without changing any feature, page identity, component identity, copy, value, action, binding, data configuration, capability, or local media slot. Use a custom deep-indigo and warm-coral brand palette with accessible light and dark canvas/surface colors, rounded typography, balanced type scale, bold titles, soft controls, subtle elevation, hairline strokes, and subtle motion. Use a dashboard layout where summaries benefit from columns, keep long-form content readable, use cards or split variants only where the renderer supports them, and preserve the existing canvas photo. Make the result feel authored rather than like a universal card stack.
```

## Demo 12 — Native Dayboard organizer

This prompt exercises the first native-service expansion and the bounded typed
runtime together. Calendar creation must be tested on a device or Simulator with
the exact build's write-only calendar usage description; choosing Cancel is a
valid file-export outcome and must not be presented as an export failure.

```text
Create a one-page native personal organizer named “Taipei Dayboard”. It must use the composable runtime plus the dedicated map, calendarEvent, and documentExport components; do not substitute static text or a generic deviceInput.

Declare these state values: project-persisted date plan-date with a valid ISO 8601 initial value; session date generated-at with a valid ISO 8601 initial value; session text new-stop initially empty; project list stops initially ["Taipei 101 observatory", "Xinyi lunch"]; project object details initially {"Meeting point":"Taipei 101 lobby", "Transit":"MRT Taipei 101/World Trade Center"}; and session text export-stops initially empty. Lists and objects must contain strings only and must not be treated as nested records.

Add a full-width hero titled “One day, one clear plan”. Give its appear event one setState step that copies the currentDate operand into generated-at. Add a datePicker control titled “Plan date” bound to plan-date. Add a text input titled “New stop” bound to new-stop and a button titled “Add stop”; its tap event first sets stops to listAppend(stops, new-stop) only when new-stop is not empty, then clears new-stop. Add a second button titled “Prepare export” that sets export-stops to listJoin(stops, "\n- "). Add one collectionView titled “Stops” bound to stops and another titled “Details” bound to details, each with a clear empty placeholder.

Add one full-width map configured for placeSearch with query “Taipei 101”, fallback coordinate latitude 25.033968 and longitude 121.564468, spanMeters 2000, allowsSearch true, and allowsDirections true. Explain that it searches Apple Maps and does not read the user's current location. Add one calendarEvent titled “Next check-in” whose event title is “Meet at Taipei 101”, location is “Taipei 101 lobby”, notes are “Created from Taipei Dayboard”, startOffsetMinutes is 60, durationMinutes is 60, and allowsEditing is true. Explain that it requests write-only calendar access only after review and cannot read existing events.

Add one documentExport titled “Take the plan with you”, fileName “Taipei Day Plan”, format plainText, buttonLabel “Choose export destination”, and contentTemplate exactly “Taipei Dayboard\nPlan date: {{plan-date}}\nPrepared: {{generated-at}}\nStops:\n- {{export-stops}}”. Explain that the preview is visible and no file is written until the user chooses a destination in Apple's save panel.

Use mint tint, native preset, system appearance, rounded typography, plain canvas, soft corners, regular density, plain surfaces, subtle motion, and a form layout. Declare exactly storage.local, calculation.safe, maps.search, calendar.createEvent, and files.export. Do not request location.current, files.import, contacts.pick, notifications.scheduleLocal, http.request, ai.complete, audio, speech recognition, App Intents, background timers, nested objects, or collection iteration.
```

## Demo 13 — Private Voice Notebook

This prompt exercises the bounded microphone adapter. Use a supported physical
iPhone to verify real recording quality and foreground interruption behavior.

```text
Create a one-page calm personal mini app named “Voice Pocket”. Add a full-width hero titled “A thought, kept private” and one full-width voiceNote titled “Quick reflection” with binding quick-reflection, maximumDurationSeconds 30, and recordButtonLabel “Record a reflection”. Explain in its subtitle that recording begins only after a tap, stays on this iPhone, stops outside the foreground, and is never uploaded or automatically transcribed. Add an info banner reminding the user that the fixed playback and delete controls are always available.

Use plum tint, soft preset, system appearance, rounded typography, plain canvas, soft corners, airy density, subtle elevation, pill controls, subtle motion, and a form layout. Declare exactly storage.local and microphone.recordLocal. Do not add AI, network, speech recognition, background recording, notifications, photos, files, or other device components.
```

## Demo 14 — Reviewed On-Device Transcript

This prompt composes local recording and the bounded Speech adapter. Verify it
on a physical iPhone with an installed on-device model for the chosen language.

```text
Create a one-page private mini app named “Voice to Notes”. Declare project-persisted text state reviewed-transcript initially empty. Add a full-width voiceNote titled “Local recording” with binding source-voice, maximumDurationSeconds 30, and recordButtonLabel “Record locally”. Add a full-width speechTranscript titled “Turn it into editable text” with binding reviewed-transcript, sourceBinding source-voice, an empty localeIdentifier so the host uses the device speech language, and buttonLabel “Review on-device transcript”. Add a text component titled “Saved note” whose valueBinding is reviewed-transcript and whose fallback says “Your accepted transcript will appear here.”

Explain accurately that the voice clip is never uploaded, transcription starts only after another tap, requires a supported on-device language model, has no network fallback, and opens an editable review before storing at most 2,000 characters. Declare exactly storage.local, microphone.recordLocal, and speech.transcribeOnDevice. Do not add live dictation, automatic transcription, AI, HTTP, background recording or recognition, notifications, photos, or other device components.
```

## Verification checklist

For each prompt used in a release or competition demo:

1. show the full prompt without an API key or provider key on screen;
2. capture real Responses API generation and the host's capability review;
3. confirm the generated document passes validation and becomes the active version;
4. exercise the core native behavior, including denial/offline/unavailable states
   relevant to that prompt; and
5. use a supported physical iPhone for camera, microphone, on-device speech,
   live scanner, pedometer, and haptic evidence.

## Recording rule

Show the prompt, real generation progress, validation success, and the resulting
native app. If time is compressed, label the edit as a time cut; do not imply an
instant response. Never expose a real API key in the recording.
