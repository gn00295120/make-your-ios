# Host capability catalog

MakeYour can grow toward a broad catalog of iPhone abilities, but a generated
tiny app can use only behavior already compiled, signed, and reviewed in the
host app. AI selects declarative components and capability identifiers; it does
not import frameworks, add entitlements, create extensions, or execute code.

This document separates what the current source actually exposes from possible
future work. A future candidate is not available to AI until its host adapter,
permission copy, validation rules, tests, and review surface all ship together.

## Available to AI-generated tiny apps

The current runtime has exactly 20 host capabilities. The host derives the
required set from the generated document and rejects both missing and unused
declarations.

| Capability | Current host behavior | Boundary |
| --- | --- | --- |
| `storage.local` | Persists validated typed state, specialized project data, and project assets | One app sandbox; no access to another tiny app or arbitrary files |
| `calculation.safe` | Runs bounded decimal, date, flat-list, and flat-object operations in ordered state transactions | No Swift, scripts, loops, nested records, arbitrary expressions, or executable output |
| `notifications.scheduleLocal` | Schedules reviewed local reminders | User action and notification permission; no remote push or silent background work |
| `photo.pick` | Imports a user-selected photo through the system picker | Cannot enumerate the photo library; normalized project-local image only |
| `camera.capture` | Presents foreground still-photo capture | Starts after a tap and camera permission; no hidden or background capture |
| `camera.scanCode` | Scans QR, supported barcodes, or visible text | Starts after a tap; result is inert text and scanned URLs are not opened automatically |
| `location.current` | Requests one current foreground coordinate | No continuous updates, geofencing, visits, or background tracking |
| `contacts.pick` | Presents Apple's single-contact picker | Returns only the selected contact's displayed name, first phone number, and first email when available; no address-book browsing |
| `files.import` | Imports one selected UTF-8 text, JSON, or CSV file | Maximum source size 256 KB; at most 2,000 characters are stored |
| `files.export` | Exports reviewed plain text, JSON, or CSV through Apple's save panel | At most 2,000 characters and 8 KB; cannot choose a destination or overwrite silently |
| `maps.search` | Displays a bounded MapKit region and searches Apple Maps | No current-location access, location history, arbitrary map provider, or silent route launch |
| `calendar.createEvent` | Creates one event after an editable review sheet and confirmation | EventKit write-only access; cannot enumerate, edit, or delete existing events |
| `microphone.recordLocal` | Records and plays one project-local AAC voice note | Visible tap and microphone permission; 5–60 seconds, maximum 1 MiB, no background capture or upload |
| `speech.transcribeOnDevice` | Transcribes one linked project-local voice note | Visible tap and Speech permission; requires supported on-device recognition, editable review before storage, and no network fallback |
| `motion.pedometer` | Reads today's aggregate step count once | Starts after a tap; no raw motion stream or background monitoring |
| `share.present` | Presents configured text in Apple's share sheet | Nothing leaves MakeYour until the user selects a destination |
| `clipboard.write` | Writes configured text to the system clipboard | Tap-initiated and write-only; no clipboard reads or background writes |
| `haptics.play` | Plays one host-defined success haptic | Local feedback only; reads and stores no sensor data |
| `http.request` | Fetches through compiled provider adapters | No arbitrary URL, method, headers, body, sockets, or generated credential handling |
| `ai.complete` | Sends reviewed text to the OpenAI Responses API | Requires the user's Keychain-backed key and confirmation; other project/device data is not attached automatically |

The fixed-provider network adapters currently cover:

- Frankfurter latest daily reference exchange rates;
- BBC World, BBC Technology, and NPR News RSS feeds;
- Twelve Data quotes and daily history, with AAPL public demo access and an
  optional user-supplied Twelve Data key for other symbols; and
- OpenAI app generation and reviewed text completion through the separate
  `ai.complete` boundary.

News search, topic filtering, and bookmarks run locally. Market watchlists,
cached results, ledgers, and game state are also local. Provider responses can
be delayed, unavailable, or subject to provider limits; none are represented as
guaranteed real-time trading data.

## Runtime blocks are not permissions

Presentation and behavior primitives do not each create a new privacy
capability. A generated app can combine text, number, boolean, date, bounded
string-list, and bounded string-object state; bindings and templates; text,
number, picker, date/time, toggle, slider, stepper, and progress controls;
collection views; conditions; calculations; page navigation; foreground
`appear`/timer events; and in-app messages without requesting a new Apple
framework permission. Project persistence derives `storage.local`; arithmetic,
date, and collection operations derive `calculation.safe`; notification and
haptic steps derive their corresponding reviewed capabilities. Lists and
objects are flat string containers, not a general structured-record language.

Custom game worlds, entity templates, controls, rules, HUD, and deterministic
simulation are also host-owned local blocks. They use `storage.local` only when
the game persists host-managed results and `haptics.play` only when feedback is
enabled. They never grant arbitrary drawing code, scripts, downloaded assets,
network multiplayer, ads, purchases, or background execution.

See [RUNTIME_BLOCKS.md](RUNTIME_BLOCKS.md) for the complete non-permission
vocabulary and its current limits.

## The 11 current device actions

A generated `deviceInput` component can select exactly one of these action
kinds. Several actions share a host capability because they use the same
reviewed adapter.

| Device action | Capability | Result |
| --- | --- | --- |
| `cameraPhoto` | `camera.capture` | One captured project-local photo |
| `qrCode` | `camera.scanCode` | User-tapped QR payload as inert text |
| `barcode` | `camera.scanCode` | User-tapped EAN-13, EAN-8, Code 128, or UPC-E payload as inert text |
| `text` | `camera.scanCode` | User-tapped recognized text from the live scanner |
| `currentLocation` | `location.current` | One latitude/longitude coordinate |
| `contact` | `contacts.pick` | Selected contact summary only |
| `documentText` | `files.import` | Bounded text from one selected document |
| `pedometer` | `motion.pedometer` | Today's aggregate step count |
| `shareText` | `share.present` | System share sheet for configured text |
| `copyText` | `clipboard.write` | Configured text written to the clipboard |
| `haptic` | `haptics.play` | One local tactile confirmation |

Camera capture, VisionKit live scanning, pedometer data, and meaningful haptic
feedback require supported physical hardware for complete verification. The
simulator may report an unavailable state. Location can be simulated, but that
does not replace a real-device permission and accuracy test. Contact, document,
and share flows use system-controlled UI and must also be smoke-tested on the
target iOS release before shipping.

## Current native map, calendar, export, voice, and speech blocks

These five capabilities use dedicated generated component kinds rather than
`deviceInput` actions:

| Component | Capability | Current behavior |
| --- | --- | --- |
| `map` | `maps.search` | Shows a configured coordinate or up to eight Apple Maps place-search results; optional search is visible, and directions open Apple Maps only after a tap |
| `calendarEvent` | `calendar.createEvent` | Resolves bounded text templates, shows title/location/notes/start/end for review, then requests write-only EventKit access and adds one confirmed event |
| `documentExport` | `files.export` | Shows the resolved content preview, enforces size limits for text/JSON/CSV, validates JSON syntax, and opens Apple's `fileExporter` destination chooser after a tap |
| `voiceNote` | `microphone.recordLocal` | Records one 5–60 second AAC clip after a tap, stops when the app leaves the foreground, and always exposes local play/pause/delete controls |
| `speechTranscript` | `speech.transcribeOnDevice` | Reads only a linked local `voiceNote`, requires an exact supported locale and on-device model, then presents an editable transcript before committing at most 2,000 characters to text state |

The map block does not request location permission. The calendar block uses
`NSCalendarsWriteOnlyAccessUsageDescription` and never reads the user's existing
events. The export block does not receive broad Files access or write before the
user chooses a destination. The voice block uses `NSMicrophoneUsageDescription`,
keeps at most one validated, playable 1 MiB clip in its project binding, prunes
removed bindings after regeneration, clears crash-staged audio on next launch,
and never automatically transcribes, uploads, or records in the background. The
separate speech block uses `NSSpeechRecognitionUsageDescription`, verifies the
requested locale rather than accepting recognizer fallback, requires
`supportsOnDeviceRecognition`, sets `requiresOnDeviceRecognition`, cancels when
it leaves the foreground, and fails closed instead of using network recognition.

## Safe next candidates, not yet supported

These are plausible additions because each can be expressed as a narrow,
separately reviewed host adapter. They remain roadmap items and are not in the
AI schema today.

- precompiled App Intent or Shortcuts actions with explicit input/output types.

Each candidate still needs a product-specific privacy boundary, availability
fallback, permission timing, data-retention rule, validator support, tests, and
App Review disclosure before it may be exposed to generation.

## Entitlement, extension, and hardware-limited roadmap

The following abilities cannot be added dynamically by an AI-generated
document. They require new signed host work, additional review, and often a
physical device or external setup:

- HealthKit, HomeKit, NFC, CarPlay, and other restricted or approval-gated
  entitlements;
- widgets, Live Activities, share extensions, notification service extensions,
  and other extension targets, often with an App Group;
- remote push notifications, background processing, and background sensor
  modes, which require signed capabilities and sometimes a server;
- Bluetooth accessory workflows, nearby-device permissions, accessory hardware,
  and protocol-specific safety design; and
- hardware-dependent camera depth, NFC tags, motion sensors, and accessory
  integrations that cannot be meaningfully validated in Simulator.

Supporting one of these later means shipping a new version of MakeYour with the
required entitlement or extension. It never means allowing a tiny app to grant
itself that access.

## Admission rule for any new capability

A capability is “supported” only when all of the following are true:

1. a bounded native adapter is compiled into the signed host;
2. the document schema and validator describe only that bounded behavior;
3. the host derives and reviews the capability instead of trusting model text;
4. permission, cancellation, denial, offline, and unavailable states are usable;
5. inputs, outputs, persistence, deletion, and external sharing are documented;
6. unit tests and the relevant simulator or physical-device checks pass; and
7. App Store privacy, permission strings, review notes, and demo material match
   the exact binary being submitted.

Until all seven are satisfied, the capability stays out of the generation
schema and must be described only as roadmap work.
