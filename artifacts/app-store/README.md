# MakeYour 1.0 App Store handoff

This folder contains the reviewed visual assets for MakeYour 1.0.0 (build 1).

## Public TestFlight build 2 - 2026-07-19

The expanded runtime was archived as MakeYour `1.0.0 (2)`, validated, uploaded,
and approved for external TestFlight testing. It is attached to the existing
`Devpost Judges` public group together with build 1:

- Public link: `https://testflight.apple.com/join/3Rnqg5Ds`
- External state: `BETA_APPROVED`
- Build ID: `9578d2af-dda3-482e-ac7f-16fb450d582c`
- Archive: `build/MakeYourIOS-1.0.0-build2.xcarchive.zip`
- Archive SHA-256: `4f646caf3d43691e57ffbffe5310d8648563364b2bb6f87ec15433289646f8c6`
- IPA: `build/MakeYourIOS-1.0.0-build2-TestFlight.ipa`
- IPA SHA-256: `e2c73674be2a7dad57a745392f8ee279fe54689f7a16d02727a82106badc7555`

The App Store review submission was intentionally left unchanged: version
`1.0.0` remains `WAITING_FOR_REVIEW`, release type `AFTER_APPROVAL`, with build 1
selected. See `build/UPLOAD_RECEIPT-build2.md` for the operational receipt.

## App Store screenshots

Upload the JPEG files in `screenshots/upload/` in this order. All eight files are
1320 x 2868 pixels, RGB, and have no alpha channel, which matches Apple's 6.9-inch
iPhone portrait screenshot slot.

1. `01-app-library.jpg` - multiple generated mini apps
2. `02-live-fx-watch.jpg` - editable live FX watchlist
3. `03-rate-test-alert.jpg` - threshold rule and visible test alert
4. `04-use-it-first.jpg` - a distinct photo-first generated design
5. `05-use-it-first-record.jpg` - local record, date, quantity, and reminder
6. `06-reviewed-ai-helper.jpg` - exact-text AI confirmation flow
7. `07-quick-convert.jpg` - native currency calculator
8. `08-ai-builder.jpg` - natural-language app builder

The PNG originals remain in `screenshots/`.

## Demo video

Use `videos/final-ai-generation-polished.mp4` for the hackathon/demo edit. It is
a 20.3-second, 1206 x 2622, H.264 recording of the real Builder generating a
Travel Budget app and opening it in the immersive runtime. It is a demo asset,
not a formatted App Store App Preview.

## Store copy and review material

- Metadata: `../../docs/app-store/APP_STORE_CONNECT.md`
- App Review instructions: `../../docs/app-store/REVIEW_NOTES.md`
- Submission checklist: `../../docs/app-store/RELEASE_CHECKLIST.md`
- Privacy and support web pages: `../../docs/app-store/site/`

## Verified release state - 2026-07-17

- Preserved archive: `build/MakeYourIOS-1.0.0-build1-final.xcarchive.zip`
- Archive SHA-256: `33e2504969b34dcfc4df4c6ed04a44c5de7ec96ff4b93726a547767b4dac9bb9`
- Working archive: `/tmp/MakeYourIOS-1.0.0-build1-final.xcarchive`
- App Store IPA: `build/MakeYourIOS-1.0.0-build1-AppStore.ipa`
- IPA SHA-256: `5d8593518b2016ac2711aa15a78cca836a43a0476500896efbd37441fcc5940f`
- Bundle ID: `com.longweiwang.makeyourios`
- Version/build: `1.0.0 (1)`
- Device family: iPhone only
- Minimum iOS: 18.0
- Tests: 39 passed, 0 failed
- Strict SwiftLint: 0 violations across 57 Swift files
- Distribution signature, App Store provisioning profile, and embedded privacy
  manifest: verified

Xcode automatically created the explicit App Store provisioning profile and
re-signed the exported IPA with the Apple Distribution identity. Apple accepted
MakeYour 1.0.0 (1) at 2026-07-17 19:06 Asia/Taipei and reported `Uploaded package
is processing` followed by `Upload succeeded`. See `build/UPLOAD_RECEIPT.md`.
