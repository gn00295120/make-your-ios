# MakeYour 1.0.0 build 4 TestFlight receipt

Verified on 2026-07-19 (Asia/Taipei).

- Bundle ID: `com.longweiwang.makeyourios`
- Version/build: `1.0.0 (4)`
- Minimum iOS: `18.0`
- ASC build ID and delivery UUID: `d653563f-78da-4cda-a648-41a64e5bf291`
- ASC processing state: `VALID`
- Export compliance: `usesNonExemptEncryption = false`
- IPA: `MakeYourIOS-1.0.0-build4-TestFlight.ipa`
- IPA SHA-256: `16cb216cf8324737fab911eea3f280d3ad8a3ad33e50642b144fe7be76e04a82`
- Archive: `MakeYourIOS-1.0.0-build4.xcarchive.zip`
- Archive SHA-256: `1f7a7f5c8809d8f948b78dacf3242afdd5877597e673899860aca8a618938209`
- Apple package validation: passed with no errors
- Upload: passed with no errors
- External group: `Devpost Judges`
- Beta App Review state: `APPROVED`
- External build state: `BETA_APPROVED`
- Public link: `https://testflight.apple.com/join/3Rnqg5Ds`

Build 4 contains the hardened generated-currency runtime and validator, plus the
continuous GPT-5.6 repair flow. Verification passed with 244/244 unit tests, the
actual persisted TripPilot currency UI test, strict SwiftLint with zero
violations across 173 Swift files, and `git diff --check`.

The existing App Store review submission was not replaced. Version `1.0.0`
remains `WAITING_FOR_REVIEW` with release type `AFTER_APPROVAL` and build 1
selected.
