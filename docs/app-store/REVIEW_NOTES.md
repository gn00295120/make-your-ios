# App Review notes — expanded-capability build draft

This draft describes the current source tree, not the already submitted
MakeYour 1.0.0 (build 1) binary. Paste it into App Review only after uploading
and selecting a new build that contains the expanded capability catalog. Attach
a generation recording made with that exact build.

```text
MakeYour is a native host for private tiny apps. It does not download, install, interpret, or execute generated Swift, JavaScript, WebAssembly, scripts, plug-ins, or other executable code.

The OpenAI Responses API returns a strict declarative JSON AppDocument. The app validates schema version, size, identifiers, component configuration, and the exact capability set. It renders only precompiled SwiftUI components and fixed host-owned actions. Generated content cannot add arbitrary URLs, methods, headers, sockets, entitlements, extensions, or credentials.

Review without an OpenAI key:

A fresh install seeds ten working examples. The following cover the expanded runtime without requiring an OpenAI key or MakeYour account:

1. Open “Daily Brief.” Refresh credited BBC/NPR headlines, search locally, change topic filters, bookmark an item, and open an original publisher link.
2. Open “Market Pocket.” Refresh AAPL through Twelve Data's public demo access and change the 1W/1M/3M chart range. Other symbols are optional and require the reviewer's own Twelve Data key, stored in Keychain and removable from the provider-key screen.
3. Open “Pocket Ledger.” Add, edit, and delete income or expense entries; change category/date/note; and review balance, spending, budget progress, and the category chart. These values are computed from local entries.
4. Open “Skybound” and “Neon Snake.” Both are complete, deterministic host-rendered games with touch controls, pause, restart, scoring, and saved best scores. Skybound uses original characters, level generation, and artwork; it contains no third-party game assets or code.
5. Open “Device Lab.” Contact selection, document import, share sheet, and clipboard write use native system surfaces after a tap. Camera capture, VisionKit QR/barcode/text scanning, today's pedometer count, and meaningful haptic verification require supported physical iPhone hardware. One-time location can use a real or simulated coordinate. Unsupported Simulator/hardware states display an explanatory fallback rather than simulated success.
6. “Live FX Watch” and “Use It First” remain available for base-currency selection, editable FX rows, in-app threshold testing, records, local reminders, private photo selection, and reviewed text-only AI UI.
7. Open Builder, then Design Studio. This native, no-key-required editor has a live preview for presets, semantic light/dark colors, typography, page layout/navigation, controls, motion, icon, and an optional private canvas photo. Cancel leaves the active app unchanged; Apply validates the complete document and creates one new version.

AI generation review:

AI generation is an optional bring-your-own-key feature. No MakeYour account, demo account, or developer credential is required.

1. Open the small four-dot menu in the upper-right corner of a tiny app and choose AI Key, or use AI Key outside a tiny app. This screen explains local Keychain storage, network access, model selection, and consent before any OpenAI request can be sent.
2. Open Builder, create a project or describe a change, and generate. If the generated version adds a capability, MakeYour presents a host-controlled review sheet before activation.
3. Builder also offers Design only. GPT-5.6 proposes visual changes, then a host-owned merger preserves the current app name, pages, component identities, copy, values, actions, bindings, data configuration, capabilities, user-selectable image slots, and local canvas binding. The reviewer sees a native preview and change summary before applying one new version.
4. Generated results open as native tiny apps. There is no downloaded executable, host back button, or bottom host tab bar; the upper-right four-dot menu returns to My Apps, Builder, or AI Key.
5. In an aiAssistant component, enter text or review an explicitly configured text-state prefill. Before Send, the app shows the exact task, exact text, destination, and local-data disclosure. Photos, audio, records, captured device results, other projects, and general device data are never attached automatically.
6. A generated app may include one visible Shortcuts access block. After approving `shortcuts.openTinyApp`, open Apple's Shortcuts app, add MakeYour's fixed Open Tiny App action, and choose that exact project. The action requires local device authentication and foregrounds MakeYour. It does not execute generated code, accept a generated URL, or run in the background.

Device and data boundaries:

- Camera and scanner access starts only after a tap and camera permission. Scanner results are inert text; scanned URLs are never opened automatically.
- Location requests one foreground coordinate. There is no continuous, visit, geofence, or background tracking.
- Apple's contact picker reveals only the one contact the reviewer selects. MakeYour does not enumerate the address book.
- File import reads only one selected UTF-8 text, JSON, or CSV file up to 256 KB and stores at most 2,000 characters.
- A generated map component displays a configured coordinate or searches only Apple Maps. It does not request current-location access or location history. Opening directions requires a tap and hands the selected place to Apple Maps.
- A generated calendar component shows the complete proposed event in a review sheet, then requests EventKit write-only access only when the reviewer taps Add Event. It can add that one event to the default writable calendar but cannot enumerate, read, edit, or delete existing events. The build includes `NSCalendarsWriteOnlyAccessUsageDescription`: “MakeYour adds a calendar event only after you review it and tap Add Event.”
- A generated document-export component shows the resolved content preview and opens Apple's destination chooser only after a tap. Plain text, JSON, and CSV exports are bounded to 2,000 characters/8 KB; the tiny app cannot choose a destination or overwrite a file silently.
- A generated voice-note component requests microphone access only after the reviewer taps Record. It stores one validated mono AAC clip of 5–60 seconds (maximum 1 MiB) in that tiny app's protected local asset directory, always exposes play/pause/delete controls, and stops when the app loses the active foreground. Permission-sheet inactivity is handled separately so first-time approval resumes only after the app is active. Protected crash-staged files are swept on next launch, and regeneration deletes audio for removed bindings. Audio is never uploaded, automatically transcribed, or attached to an AI request. The build includes `NSMicrophoneUsageDescription`: “MakeYour records a local voice note only after you tap Record inside a tiny app.”
- A generated speech-transcript component can reference only an existing voice-note binding and a distinct declared text-state destination. After the reviewer taps, it requests Speech Recognition permission, verifies the exact requested locale, requires `supportsOnDeviceRecognition`, and sets `requiresOnDeviceRecognition`. Unsupported or unavailable on-device recognition fails closed with no network fallback. Recognition cancels outside the foreground. The result is capped at 2,000 characters and shown in an editable review sheet; Cancel stores nothing, while Use Transcript atomically commits the accepted text before any `valueChanged` event. The build includes `NSSpeechRecognitionUsageDescription`: “MakeYour transcribes a linked local voice note only after you tap, using on-device recognition when available.”
- The generated Shortcuts access component is an inert opt-in marker: it cannot contain an action, event, binding, value, arbitrary phrase, URL, or background work. Apple's dynamic entity query receives only valid opted-in project UUIDs, names, and allowlisted icons. The fixed intent revalidates the entity before execution, and the app revalidates again before presentation without falling back to another project. Removing the marker or deleting the app invalidates a stale shortcut; duplication strips the marker. Once visible, the tiny app behaves normally, including any already validated page-appearance behavior.
- Pedometer access reads only today's aggregate step count after a tap, with no raw or background motion stream.
- The share sheet sends nothing until the reviewer chooses a destination. Clipboard access is tap-initiated and write-only. Haptics collect no data.
- Deleting a tiny app removes its document, local runtime state, project images and voice notes, local notifications, and Shortcuts eligibility. Host-level API keys must be removed separately because other tiny apps may use them.

Privacy and storage:

- OpenAI and optional Twelve Data API keys use iOS Keychain with When Unlocked, This Device Only protection.
- Requests go directly from the device to the named provider; the developer operates no account, analytics, or proxy server.
- Projects, records, bookmarks, cached responses, and captured results stay on device unless the user deliberately shares text or opens an external article.
- User-selected component images, Design Studio canvas photos, and voice notes stay in the tiny app's project-local asset store. Generated documents contain only semantic bindings and presentation or duration metadata; media bytes and local paths are not sent to GPT-5.6.
- Privacy & Safety is accessible from the AI Key screen and contains a catalog of all 21 host capabilities.

Fixed network services:

- https://api.openai.com — user-authorized app generation and reviewed text completion
- https://api.frankfurter.dev — latest daily reference currency rates
- https://feeds.bbci.co.uk — built-in BBC World and BBC Technology RSS feeds
- https://feeds.npr.org — built-in NPR News RSS feed
- https://api.twelvedata.com — AAPL public demo or user-key-authorized quote and daily-history requests

Market and currency data may be delayed and are not trading advice. Notifications and privacy-sensitive device permissions are requested only in response to an explicit feature action.
```

## Contact fields

- First name: `Longwei`
- Last name: `Wang`
- Phone: `+886 987432061`
- Email: `support@claude-world.com`
- Sign-in required: No. MakeYour has no account system. OpenAI generation and
  non-demo market symbols are optional bring-your-own-key features.

## Submission evidence required for this draft

- a recording from the selected build showing real OpenAI generation and the
  capability review sheet;
- a physical-iPhone recording or review note confirming camera, scanner,
  pedometer, haptic, and write-only calendar behavior;
- a current-build check of MapKit search/directions and the document-export
  preview, cancellation, and successful destination flow;
- a physical-iPhone check of Shortcuts discovery, Siri, local authentication,
  cold/warm foreground routing, app-to-app switching, and stale-project failure; and
- a clean-install check confirming all twelve seeded examples and honest hardware-denied,
  permission-denied, and offline states.
