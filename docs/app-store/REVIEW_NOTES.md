# App Review notes — MakeYour 1.0.0 (1)

Paste the text below into App Review Information.

```text
MakeYour is a native host for private mini apps. It does not download, install, interpret, or execute generated Swift, JavaScript, WebAssembly, scripts, plug-ins, or other executable code.

The OpenAI Responses API returns a strict declarative JSON AppDocument. The app validates schema version, size, identifiers, component configuration, and declared capabilities. It then renders only precompiled SwiftUI components and fixed host-owned actions. Generated content cannot add arbitrary network hosts: version 1 supports only the fixed Frankfurter exchange-rate resource and direct, user-approved OpenAI requests.

Two reviewable examples are available on first launch without an OpenAI key:

1. Open “Live FX Watch.” Change the base currency, use Add currency, refresh the latest daily reference rates, tap a row's bell, set a threshold, and tap Test Alert. This immediately presents an in-app alert. Values are reference rates, not streaming quotes.
2. Open “Use It First.” Add a pantry record with a quantity and use-by date. Save it, tap the reminder control, and schedule a local notification. The photo slot is optional and remains on device.

AI generation review:

AI generation is an optional bring-your-own-key feature. No MakeYour account, demo account, or developer credential is required. A real-device recording attached to this review submission demonstrates the complete OpenAI generation flow and resulting native mini app.

1. Open the small four-dot menu in the upper-right corner of a mini app and choose AI Key, or use the AI Key tab outside a mini app. This screen explains local Keychain storage, network access, model selection, and consent before any request can be sent.
2. Open Builder to inspect the natural-language design flow. Without a key, the four seeded mini apps and all local host capabilities remain fully reviewable.
3. Generated results open as native mini apps. There is no back button or bottom host tab bar; the upper-right four-dot menu returns to My Apps, Builder, or AI Key.
4. In “Use It First,” enter ingredients in 15-minute Rescue Chef. Before Send, the app shows the exact task, exact text, destination, and local-data disclosure. Photos, pantry records, other projects, and device data are never attached automatically.

Privacy and storage:
- The API key is stored in iOS Keychain with When Unlocked, This Device Only protection.
- Requests go directly from the device to OpenAI; the developer operates no account or proxy server.
- Projects, records, and photos stay on device.
- MakeYour contains no advertising, analytics, tracking, or account system.
- Privacy & Safety is accessible from the AI Key screen.

Network services:
- https://api.openai.com — user-authorized app generation and reviewed text completion
- https://api.frankfurter.dev — latest daily reference currency rates

Notifications are requested only after the reviewer explicitly schedules a reminder.
```

## Contact fields

- First name: `Longwei`
- Last name: `Wang`
- Phone: `+886 987432061`
- Email: `support@claude-world.com`
- Sign-in required: No. MakeYour has no account system. AI generation is an optional
  bring-your-own-key feature and its complete flow is shown in the attached recording.
