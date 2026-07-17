# MakeYour 1.0 release checklist

## Completed in the repository

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
- [x] External TestFlight group `Devpost Judges` with public link
- [x] Build 1 submitted to Beta App Review

## Current local release status (2026-07-17)

- Preserved archive: `artifacts/app-store/build/MakeYourIOS-1.0.0-build1-final.xcarchive.zip`
- Working archive: `/tmp/MakeYourIOS-1.0.0-build1-final.xcarchive`
- Distribution IPA: `artifacts/app-store/build/MakeYourIOS-1.0.0-build1-AppStore.ipa`
- TestFlight public link: `https://testflight.apple.com/join/3Rnqg5Ds`
- Beta App Review state: `WAITING_FOR_REVIEW`
- Verification: 43 tests passed, strict SwiftLint reported 0 violations, and
  the exported app passed strict Apple Distribution code-signature verification.
- Apple accepted MakeYour 1.0.0 (1) at 2026-07-17 19:06 Asia/Taipei. Processing
  completed successfully and the build is `VALID`.

## Required before App Review submission

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

## App Store Connect fields

- [x] App information: name, subtitle, categories, content rights, age rating
- [x] Pricing and availability (Free, USA base territory, 175 territories)
- [ ] App privacy answers
- [x] Version information: description, keywords, support URL, screenshots
- [x] Build selection and export compliance
- [x] App Review contact, notes, and review attachment
- [x] Release method

## Final TestFlight pass

- [ ] Fresh-install launch seeds four reviewable mini apps
- [ ] Live FX refresh, add/remove currency, base selection, threshold, Test Alert
- [ ] Use It First record add/edit/delete, completion, photo, and reminder
- [ ] Builder generation with review key
- [ ] Generated mini app opens without host back button or bottom tabs
- [ ] Upper-right menu routes to My Apps, Builder, and AI Key
- [ ] AI request confirmation Send button works on first presentation
- [ ] VoiceOver labels, Dynamic Type, light mode, and dark mode smoke tests
- [ ] Offline/cached FX and provider-error states
- [ ] Delete project and remove API key

## Submission boundary

Uploading a build creates remote state but is reversible. Submit only after all
metadata, URLs, screenshots, privacy answers, pricing, and review access are verified.
