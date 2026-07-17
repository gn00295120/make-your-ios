# Verified AI Builder demo prompts

These prompts were entered into MakeYour's Builder and generated working,
validated `AppDocument` results through the OpenAI Responses API.

## Demo 1 — Live FX Watch

```text
Create a one-page native mini app named “Live FX Watch”. It should let me choose the primary currency, add and remove currencies from a searchable catalog, refresh the latest available exchange rates, and configure an at-or-below or at-or-above threshold for each row with a Test Alert button that immediately shows an in-app alert.

Use sky tint, a minimal light visual theme, rounded typography, a plain background, soft corners, regular density, and a dashboard layout. Add a centered hero titled “Rates that matter to you” with subtitle “Build a personal watchlist around one home currency.” Then add one subtle infoBanner explaining that these are latest daily reference rates, not streaming trading quotes. Add one full-width liveDataList titled “My rate watchlist”, subtitle “Tap the bell to set a target or test an alert.” Configure resource exchangeRates, primaryValue USD, initialSymbols TWD, JPY, EUR, GBP, and KRW, allowsPrimarySelection true, allowsItemEditing true, and allowsThresholds true. Declare storage.local and http.request. Do not use currencyConverter, static rate items, arbitrary URLs, taskList, or a fake live metric.
```

## Demo 2 — Use It First

```text
Create a one-page private fridge mini app named “Use It First”. Let me keep one device-only fridge photo, track ingredients with quantity and use-by date, schedule local expiry reminders, and ask AI for a recipe using only ingredient text that I explicitly review and send. AI must never claim to read the photo, collection, device data, or other apps.

Use mint tint, playful preset, system appearance, rounded typography, gradient background, round corners, airy density, material default surface, story layout, and hide the navigation title. Do not put every component in the same card style.

In this order add: (1) a full-width editable image titled “What’s in your fridge?”, subtitle “Choose one private fridge photo.”, binding fridge-photo, banner aspect, fill, alt text “A fridge photo selected by the user”, allowsUserSelection true, plain surface, strong emphasis, photoOverlay variant; (2) a centered hero titled “Use it before you lose it”, subtitle “Track what expires next, then turn a few ingredients into dinner.”, symbol leaf.fill; (3) a subtle infoBanner titled “Private by design”, subtitle “Your photo and pantry list stay on this iPhone. AI receives only text you review and send.”, symbol lock.shield.fill; (4) a recordCollection titled “Pantry”, subtitle “Add what you want to use first.”, binding pantry-items, itemName Ingredient, titleLabel Ingredient, noteLabel “Where / note”, valueLabel Quantity, valueKind number, valueUnit unit, dateLabel “Use by”, dateKind date, aggregate count, allowsCompletion true, allowsReminders true, with no initial items; (5) an aiAssistant titled “15-minute Rescue Chef”, subtitle “Type ingredients yourself. AI cannot read your photo or pantry list.”, placeholder “Example: spinach, eggs, tofu”, quick prompts “spinach, eggs, tofu”, “tomatoes, rice, cheese”, and “banana, oats, yogurt”, button label “Make a recipe”. Its task is: “Using only ingredients typed by the user, suggest one realistic 15-minute recipe with a short name, three concise steps, and one optional substitution. Never claim to inspect other data. Do not make medical or nutrition claims.”

Declare storage.local, photo.pick, notifications.scheduleLocal, and ai.complete. Do not add live data, arbitrary HTTP, taskList, external URLs, or fake computed metrics.
```

## Recording rule

Show the prompt, real generation progress, validation success, and the resulting
native app. If time is compressed, label the edit as a time cut; do not imply an
instant response. Never expose a real API key in the recording.
