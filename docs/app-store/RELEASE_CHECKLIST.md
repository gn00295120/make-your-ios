# MakeYour release checklist

## Submitted build 1 snapshot

The checked items in this section describe the preserved MakeYour 1.0.0 build 1
archive and its July 17 submission. They do not certify the expanded
capability changes currently in the source tree.

- [x] Bundle ID `com.longweiwang.makeyourios`
- [x] Version `1.0.0`, build `1`
- [x] iPhone-only target, iOS 18.0 minimum
- [x] App Store category set to Productivity
- [x] 1024 × 1024 RGB App Icon with no alpha
- [x] `ITSAppUsesNonExemptEncryption = NO`
- [x] Privacy manifest with no tracking and `CA92.1` UserDefaults reason
- [x] In-app Privacy & Safety disclosure
- [x] English and Traditional Chinese metadata draft
- [x] App Review notes and review steps
- [x] Privacy policy and support page source
- [x] Export options for App Store Connect distribution
- [x] Release archive build
- [x] Full unit test and strict SwiftLint gates
- [x] Eight reviewed 6.9-inch iPhone screenshots (1320 × 2868, no alpha)
- [x] Final AI-generation demo capture
- [x] Explicit App ID and App Store provisioning profile
- [x] App Store Connect app record (`MAKEYOUR-IOS-001`)
- [x] Apple Distribution-signed IPA export
- [x] App Store Connect upload accepted for processing
- [x] App privacy answers published
- [x] MakeYour 1.0.0 submitted to App Review
- [x] External TestFlight group `Devpost Judges` with public link
- [x] Build 1 submitted to Beta App Review

## Submitted build 1 status snapshot (2026-07-17)

- Preserved archive: `artifacts/app-store/build/MakeYourIOS-1.0.0-build1-final.xcarchive.zip`
- Working archive: `/tmp/MakeYourIOS-1.0.0-build1-final.xcarchive`
- Distribution IPA: `artifacts/app-store/build/MakeYourIOS-1.0.0-build1-AppStore.ipa`
- TestFlight public link: `https://testflight.apple.com/join/3Rnqg5Ds`
- Beta App Review state: `WAITING_FOR_REVIEW`
- App Store version state: `WAITING_FOR_REVIEW`
- App Review submission: `c3e9fc5c-9daf-47da-ad6d-8d4b63480047`, submitted
  2026-07-17 23:30 Asia/Taipei
- Release method: automatic after approval (`AFTER_APPROVAL`)
- Verification: 43 tests passed, strict SwiftLint reported 0 violations, and
  the exported app passed strict Apple Distribution code-signature verification.
- Apple accepted MakeYour 1.0.0 (1) at 2026-07-17 19:06 Asia/Taipei. Processing
  completed successfully and the build is `VALID`.

## Expanded capability build gates

Current source verification snapshot (2026-07-18):

- 85/85 unit tests and the separately gated 1/1 live OpenAI generation UI test
  passed on an iPhone 17 Pro Simulator running iOS 26.5.
- Strict SwiftLint checked 91 Swift files with zero violations; `git diff
  --check`, generic Simulator build, and signed physical-iPhone build passed.
- The built iPhone app contains camera, contact, When In Use location, and
  motion usage descriptions plus `PrivacyInfo.xcprivacy`; strict local
  code-signature verification passed.
- The exact candidate was installed on the connected iPhone. Automated launch
  was denied because the phone was locked, so the physical camera/scanner and
  permission interaction gates below deliberately remain unchecked.
- Live BBC RSS, live Twelve Data AAPL demo data, the generated `E2E Proof`
  document, and its rendered runtime were observed on the Simulator.

- [ ] Increment `CURRENT_PROJECT_VERSION` above build `1`; do not overwrite or
  relabel the preserved build 1 archive.
- [ ] Generate the Xcode project from the committed `project.yml`, archive the
  current source, and export a newly signed IPA.
- [ ] Run the full unit suite, strict SwiftLint, `git diff --check`, release
  build, archive validation, and strict code-signature verification; record the
  actual results without copying the historical 43-test count.
- [ ] Confirm the archive contains camera, contact, When In Use location, and
  motion usage descriptions, plus the current privacy manifest.
- [ ] Fresh-install the exact candidate on TestFlight and confirm all ten seeded
  tiny apps appear.
- [ ] Exercise capability review for generated documents and verify missing or
  unused declarations are rejected.
- [ ] Test Frankfurter, BBC World, BBC Technology, NPR News, Twelve Data AAPL
  demo access, a user-supplied Twelve Data key, and OpenAI generation against
  their fixed adapters, including timeout, malformed, rate-limit, and offline
  states.
- [ ] On a supported physical iPhone, test camera grant/deny/capture, QR,
  supported barcode and visible-text scanning, one-time location, today's
  pedometer count, and haptic feedback.
- [ ] On the target iOS release, test contact cancellation/selection, bounded
  text/JSON/CSV import, share cancellation/destination choice, and tap-initiated
  clipboard write.
- [ ] Verify that deleting a tiny app removes its document, runtime state,
  project images, and pending/delivered local notifications while leaving
  host-level API keys available to other projects.
- [ ] Record a current-build demo showing real OpenAI generation, capability
  review, two contrasting generated tiny apps, and smooth project switching.
- [ ] Capture new screenshots and App Review attachments if the selected build
  presents features not shown in build 1 assets.
- [ ] Replace the App Review notes with the expanded-build draft only after that
  binary is uploaded and selected.
- [ ] Reconfirm App Store privacy answers for OpenAI and Twelve Data provider
  account identifiers/retention; update `PrivacyInfo.xcprivacy` if needed.
- [ ] Publish the July 18 privacy/support text at the production HTTPS URLs and
  verify those public pages from a logged-out browser.
- [ ] Submit the new build to internal TestFlight, then external Beta App Review,
  before replacing or updating the App Store review submission.

## Historical build 1 pre-submission items

- [x] Create or confirm the explicit App ID `com.longweiwang.makeyourios` in the
  Apple Developer account.
- [x] Create the MakeYour app record in App Store Connect using SKU
  `MAKEYOUR-IOS-001`.
- [x] Publish privacy and support pages at stable public HTTPS URLs.
- [x] Set support and App Review contact details.
- [x] Add App Review contact name, phone, and email.
- [x] Attach a real-device AI generation recording to App Review. No MakeYour
  account or developer-owned OpenAI credential is required for review.
- [ ] Confirm agreements, tax, and banking status even though version 1 is free.
- [x] Set availability to all 175 current App Store territories and automatically
  include new territories. AI remains an optional BYOK feature.
- [x] Export an Apple Distribution-signed App Store IPA.
- [x] Pass Apple's package analysis and upload the build.

## Historical build 1 App Store Connect fields

- [x] App information: name, subtitle, categories, content rights, age rating
- [x] Pricing and availability (Free, USA base territory, 175 territories)
- [x] App privacy answers
- [x] Version information: description, keywords, support URL, screenshots
- [x] Build selection and export compliance
- [x] App Review contact, notes, and review attachment
- [x] Release method

## Expanded-build TestFlight pass

- [ ] Fresh-install launch seeds ten reviewable tiny apps
- [ ] Daily Brief refresh, local search/topics/bookmarks, cache, and original link
- [ ] Market Pocket AAPL demo, provider-key add/remove, symbols, ranges, and cache
- [ ] Pocket Ledger entry CRUD, income/expense totals, budget, and category chart
- [ ] Skybound and Neon Snake controls, pause, restart, win/loss, and saved score
- [ ] Device Lab's 11 actions, including honest Simulator/hardware fallbacks
- [ ] Live FX refresh, add/remove currency, base selection, threshold, Test Alert
- [ ] Use It First record add/edit/delete, completion, photo, and reminder
- [ ] Builder generation with review key
- [ ] Generated mini app opens without host back button or bottom tabs
- [ ] Upper-right menu routes to My Apps, Builder, and AI Key
- [ ] AI request confirmation Send button works on first presentation
- [ ] VoiceOver labels, Dynamic Type, light mode, and dark mode smoke tests
- [ ] Offline/cache/provider-error states for FX, news, market, and OpenAI
- [ ] Delete project; separately remove OpenAI and Twelve Data keys

## Historical build 1 App Review submission

Apple accepted the review submission on 2026-07-17. The version, Build 1, and
review submission item were verified through the App Store Connect API; both the
version and review submission are `WAITING_FOR_REVIEW`.
