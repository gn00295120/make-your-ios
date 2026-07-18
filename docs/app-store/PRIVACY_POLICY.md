# MakeYour Privacy Policy

Effective date: July 19, 2026

MakeYour is designed as a local, private workspace for creating and using native
mini apps on iPhone. This policy explains what stays on the device, what may be
sent to a service at the user's request, and how the user controls that data.

## Data stored on the device

MakeYour stores mini-app documents and runtime state in the app's local
container. Depending on the tiny apps a user creates, this can include records,
tasks, ledgers, game scores, news bookmarks, market and currency watchlists,
cached provider results, AI consent settings, selected or captured project
images (including an optional Design Studio canvas background), bounded voice
notes and accepted on-device transcripts, scanned text or codes, a one-time coordinate, a selected contact summary,
imported text, or today's aggregate step count.

The user's OpenAI API key and any optional Twelve Data API key are stored
separately in iOS Keychain using When Unlocked, This Device Only protection.
These are host-level credentials and are not placed in generated app documents.

MakeYour does not operate a user-account system or a synchronization server.

## OpenAI requests

AI features are optional and require the user to provide an OpenAI API key and
enable AI requests.

When generating or revising a mini app, MakeYour sends the builder instruction
and the current declarative app document directly from the device to OpenAI. When
using an AI helper inside a mini app, MakeYour first displays the exact task and
user-entered or visibly prefilled text on a confirmation screen. An accepted
local transcript can become an editable prefill, but its audio is not attached.
Only that reviewed task and text are
sent after the user taps Send.

MakeYour does not attach selected photos, canvas backgrounds, voice recordings,
local records, notification contents, other projects, or general device data to
an AI request. Generated documents contain only semantic media bindings and
visual or duration metadata, never media bytes or local paths. The API key is
used only as the authorization header for the direct OpenAI request.

OpenAI processes these requests under the agreement and data controls associated
with the user's OpenAI API account. Users should review OpenAI's
[API data controls](https://platform.openai.com/docs/models/default-usage-policies-by-endpoint)
and the terms that apply to their account before enabling this feature.

## Fixed-provider data requests

Live FX Watch sends the selected ISO base and quote currency codes to the fixed
Frankfurter API endpoint to retrieve the latest available daily reference rates.
The news component fetches only the built-in BBC World, BBC Technology, or NPR
News RSS endpoints selected by the tiny app. Search terms, topic filters, and
bookmarks are applied locally and are not sent to those feed providers.

The market component sends a requested symbol, chart interval/range parameters,
and either Twelve Data's public AAPL demo credential or the user's own Twelve
Data API key to the fixed Twelve Data endpoints. The key is associated with the
user's relationship with Twelve Data, not a MakeYour account.

These adapters do not send project records, photos, voice recordings, captured
device results, or the OpenAI API key. As with any network request, the provider and network
operators may process technical information such as an IP address to deliver,
limit, and secure the service. Opening a news article leaves MakeYour for the
publisher's original page, where that publisher's policy applies.

## Device permissions and user-initiated actions

Generated tiny apps may use only host-owned device actions compiled into
MakeYour. Camera capture, QR/barcode/text scanning, a current coordinate, a
single-contact picker, selected text-file import, today's pedometer count, and a
local voice note or linked on-device transcript start only after the user taps.
Camera, microphone, Speech Recognition, location, and motion access use the
corresponding iOS permission or system-controlled picker. There is no hidden
camera or microphone use, continuous location tracking, address-book
enumeration, arbitrary file browsing, raw motion streaming, or background
sensor monitoring.

Camera photos and captured results are stored in the requesting tiny app's local
project state. QR codes and other scanned values are treated as inert text;
MakeYour does not automatically open scanned URLs or execute their contents.
Text-file import accepts one user-selected UTF-8 text, JSON, or CSV file up to
256 KB and stores no more than 2,000 characters. The contact picker stores only
the selected contact's displayed name, first phone number, and first email
address when available.

A voice-note component records one mono AAC clip for 5–60 seconds, capped at
1 MiB. Recording stops at its configured limit or when MakeYour leaves the
foreground. The clip remains in the requesting tiny app's protected local asset
directory until replaced, deleted, or its binding is removed by app regeneration;
MakeYour does not automatically transcribe or upload it. A protected, backup-excluded staging
file is used only while recording, and any crash leftover is removed at the next
app launch. Incomplete or unplayable audio is rejected rather than persisted.

If a tiny app contains an explicitly linked speech-transcript component, the
user may tap it to request Apple's Speech Recognition permission and process
that one local clip. MakeYour first verifies the requested locale and that the
recognizer supports on-device recognition, then requires on-device processing.
If those checks fail, transcription is unavailable; MakeYour does not fall back
to a network recognizer. Recognition cancels outside the foreground. The result
is capped at 2,000 characters and remains editable in a review sheet. Cancel
stores nothing; Use Transcript stores the accepted text in the tiny app's local
state. That accepted text is sent to OpenAI only if the user later places or
keeps it in an AI editor and separately confirms the exact AI request.

Sharing and clipboard actions also require a tap. A share action presents
Apple's share sheet, and data leaves MakeYour only after the user chooses a
destination; that destination's privacy policy then applies. A copy action
writes configured text to the iOS clipboard and never reads clipboard contents.
Other apps may be able to access clipboard content under iOS rules. A haptic
action plays local tactile feedback and collects no sensor data.

## Data collection and tracking

The developer of MakeYour does not receive or store user projects, photos, voice
recordings, captured device results, API keys, prompts, AI results, news bookmarks, market
or currency watchlists, analytics, advertising IDs, or usage profiles on a
MakeYour server. MakeYour contains no advertising SDK, analytics SDK, data
broker integration, or cross-app tracking.

Because reviewed free-form text may be transmitted to OpenAI and processed in
connection with the user's OpenAI account, MakeYour conservatively declares
Other User Content as collected for App Functionality, linked to the user, and
not used for tracking in its App Store privacy label.

MakeYour contacts these providers only to deliver the feature the user requests;
MakeYour does not direct provider processing toward advertising or tracking.
Provider processing is governed by the provider's published terms, privacy
materials, and the user's account agreement. Users should review those materials
before enabling a provider-backed feature.

## Retention and deletion

Local data remains until the user deletes the relevant tiny app, removes a
host-level credential, or deletes MakeYour from the device. A user can:

- remove the OpenAI API key from the AI Key screen;
- remove the Twelve Data key from the market provider-key screen;
- delete a tiny app from My Apps to remove its document, project-local runtime
  state, images, and voice notes, and its pending or delivered local notifications; and
- delete MakeYour from iPhone to remove the app's sandboxed projects, assets,
  caches, and runtime state.

Deleting one tiny app does not remove the host-level OpenAI or Twelve Data API
keys because another tiny app may use them. Remove those keys separately using
the in-app controls above before uninstalling; uninstalling an app does not
guarantee deletion of its Keychain items. Revoking a permission in iOS Settings
prevents future access but does not by itself delete results already saved
locally.

Data processed by OpenAI or Twelve Data is subject to the retention and deletion
controls of the user's account with that provider. Frankfurter, BBC, NPR,
Twelve Data, and an article publisher may retain limited delivery, rate-limit,
or security logs under their own operating practices.

## Children

MakeYour is not directed to children under 13. OpenAI features also require the
user to satisfy the minimum age and parental-permission requirements associated
with the user's OpenAI account and location.

## Security

MakeYour uses iOS sandboxing, Keychain protection, HTTPS, bounded structured
documents, and an allowlisted native capability runtime. No security method can
guarantee absolute protection, but MakeYour minimizes the data it transmits and
does not operate a central user-data store.

## Changes

This policy may be updated when MakeYour's features or providers change. The
effective date above will be updated when material changes are made.

## Contact

Privacy or support questions: `support@claude-world.com`
