# MakeYour Support

MakeYour creates private native mini apps inside one iPhone app. For help,
contact `support@claude-world.com`.

## Common questions

### Where is my OpenAI API key stored?

In iOS Keychain with When Unlocked, This Device Only protection. Remove it at
any time from AI Key → Remove.

Market Pocket also supports an optional Twelve Data API key for symbols other
than the provider's AAPL demo. It uses the same device-only Keychain protection
and can be removed from the market provider-key screen. Deleting one tiny app
does not remove either host-level key because another tiny app may use it.

### Why can't MakeYour generate an app?

Confirm that the API key is valid for the selected Responses API model, that
Allow requests to OpenAI is enabled, and that the iPhone has a network
connection. MakeYour displays provider errors without printing the API key.

### Are Live FX values streaming market prices?

No. They are the latest available daily reference rates from Frankfurter. They
are suitable for a personal reference tool, not trading or financial advice.

### Where do news and stock data come from?

Daily Brief uses fixed BBC World, BBC Technology, and NPR News RSS feeds. Search,
topic filtering, and bookmarks run locally; opening an article goes to the
publisher's original page. Market Pocket uses fixed Twelve Data quote and
daily-history endpoints. AAPL supports the provider's public demo access; other
symbols require your own Twelve Data key. Quotes can be delayed, unavailable,
or rate-limited and are not financial advice.

### Why is camera, microphone, speech, scanning, steps, or haptics unavailable?

Still-photo capture, VisionKit QR/barcode/text scanning, pedometer data, and
meaningful haptic feedback require supported physical iPhone hardware. They may
show an unavailable message in Simulator or on unsupported devices. Camera,
microphone, Speech Recognition, location, and motion actions also require the matching iOS permission. MakeYour
requests access only after you tap the action; you can review or change access
in iOS Settings.

### What does a device action read or share?

- Camera and scanning run only in the foreground. Scanned URLs are displayed as
  inert text and are never opened automatically.
- Current location returns one coordinate; it does not start background or
  continuous tracking.
- Apple's contact picker returns only the contact you select. MakeYour does not
  browse the address book.
- Document import reads one selected UTF-8 text, JSON, or CSV file up to 256 KB
  and stores at most 2,000 characters.
- Pedometer reads today's aggregate step count once, not raw/background motion.
- Voice recording captures one 5–60 second local AAC clip after a tap, stops
  outside the active foreground, validates the finished audio before saving,
  and is never uploaded or automatically transcribed. Regeneration removes a saved clip when
  its voice binding no longer exists.
- A linked transcript starts only after another tap. It requires a supported
  on-device language model, has no network fallback, and shows editable text
  before storage. Cancel stores nothing; an accepted transcript stays in that
  tiny app's local state.
- Share presents Apple's destination chooser. Clipboard access writes configured
  text only after a tap and never reads the clipboard. Haptics collect no data.

### How do I open a tiny app from Shortcuts or Siri?

Generate or revise that tiny app with one Shortcuts access block and approve the
new capability. In Apple's Shortcuts app, add MakeYour's **Open Tiny App** action
and choose the project. Its picker receives only opted-in projects' stable IDs,
names, and safe icons.
The action requires local device authentication and opens MakeYour in the
foreground; it does not receive project state, media, prompts, or API keys.

If a saved shortcut says the tiny app is unavailable, the project was deleted,
its access block was removed, or the local catalog cannot be read safely. Add
the block again only if you want to re-enable access. Duplicated tiny apps do
not inherit the source app's Shortcuts opt-in.

### How do I remove my data?

Long-press an app in My Apps and choose Delete to remove its document and
project-local runtime state, images, and voice notes, plus its pending and delivered local
notifications and Shortcuts eligibility. Remove the OpenAI key from AI Key and any Twelve Data key from
the market provider-key screen before uninstalling. Deleting MakeYour from the
iPhone removes its sandboxed projects, assets, caches, and runtime state, but
iOS does not guarantee that uninstalling removes Keychain items.

### Does AI see my photos or records?

No. Tiny-app AI helpers accept text entered or visibly prefilled into that helper.
An accepted transcript can become an editable prefill, but audio is never attached. The exact task and
text appear on a confirmation screen before every request. Photos, voice notes,
records, scans, coordinates, contacts, imported files, step counts, other apps, and
general device data are not attached automatically.

## When contacting support

Include the MakeYour version and build, iOS version, device model, the feature
being used, whether it was Simulator or a physical iPhone, and the exact error
text. Never send an API key, private prompt, selected/captured image or voice
note, scanned value, coordinate, contact, imported text, or personal record in a support
message.
