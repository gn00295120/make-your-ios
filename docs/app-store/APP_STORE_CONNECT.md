# App Store Connect release sheet

This file is the copy-and-paste source of truth for MakeYour 1.0.0 (build 1).

## App record

- Platforms: iOS
- Name: `MakeYour`
- Primary language: English (U.S.)
- Bundle ID: `com.longweiwang.makeyourios`
- SKU: `MAKEYOUR-IOS-001`
- User access: Full Access
- Version: `1.0.0`
- Build: `1`
- Copyright: `2026 Longwei Wang`
- Primary category: Productivity
- Secondary category: None
- Price: Free
- Distribution: iPhone only

## English (U.S.) metadata

### Subtitle

```text
Build your own tiny apps
```

### Promotional text

```text
Describe the personal tool you need, then use it as a private native mini app—with records, reminders, photos, live FX rates, and reviewed AI.
```

### Keywords

```text
AI,builder,mini apps,tracker,reminder,checklist,currency,productivity,BYOK,personal
```

### Description

```text
Stop downloading another tiny app. Make yours.

MakeYour turns a sentence into a useful native mini app inside one trusted iPhone app. Build a personal tracker, checklist, calculator, reminder workflow, photo journal, currency watchlist, or another small tool—then keep several apps and switch between them whenever you need.

WHAT YOU CAN BUILD

• Personal record collections with notes, numbers, dates, totals, completion, and reminders
• Task lists and local notification workflows
• Calculators and currency tools
• Photo-first private journals and trackers
• Live FX watchlists with a chosen base currency, editable currencies, and threshold alerts
• Focused AI helpers that receive only text you explicitly review and send

YOUR STYLE, NOT ONE TEMPLATE

Generated apps can use different native themes, typography, backgrounds, layouts, spacing, surfaces, imagery, symbols, and colors. MakeYour keeps the experience accessible and familiar while giving each app its own visual direction.

BRING YOUR OWN OPENAI KEY

Your API key is stored in iOS Keychain for this device only. AI requests travel directly from your iPhone to OpenAI. MakeYour does not operate an account or proxy server and never puts your key in a project file or prompt.

PRIVATE BY DESIGN

Projects, records, watchlists, and selected photos stay on your iPhone. Before an in-app AI request, MakeYour shows the exact task and text that will be sent. Photos, records, other apps, and device data are not attached.

SAFE NATIVE RUNTIME

AI does not download or execute Swift, JavaScript, plug-ins, or arbitrary code. It creates a validated declarative app document. MakeYour renders that document using precompiled native SwiftUI components and a fixed capability allowlist.

Live currency values are the latest available daily reference rates from Frankfurter, not streaming market quotes and not financial advice.
```

### URLs

- Support URL: `https://makeyour-support.lucasfutures.chatgpt.site/support`
- Privacy Policy URL: `https://makeyour-support.lucasfutures.chatgpt.site/privacy`
- Marketing URL: optional; use the project or Devpost page once public

## Traditional Chinese metadata

### Subtitle

```text
一句話做出你的迷你 App
```

### Promotional text

```text
描述你需要的小工具，立即生成可操作的原生迷你 App：資料、提醒、照片、匯率與經你確認後才送出的 AI 功能，都放在同一個 App 裡。
```

### Keywords

```text
AI,迷你App,生成,待辦,提醒,追蹤,換匯,匯率,生產力,個人工具
```

### Description

```text
別再下載另一個小工具，直接做出自己的。

MakeYour 能把一句需求變成同一個 iPhone App 裡可立即操作的原生迷你 App。你可以製作個人追蹤器、待辦清單、計算機、提醒流程、相片日誌、匯率觀察表，再把多個 App 收進自己的 App Library 隨時切換。

可生成的功能包括：

• 含備註、數字、日期、統計、完成狀態與提醒的個人資料表
• 待辦清單與本機通知
• 計算與換匯工具
• 只留在裝置上的相片日誌與追蹤器
• 可選主要貨幣、增刪幣別與設定門檻警示的匯率觀察表
• 只有在你確認文字後才會送出的專用 AI 助手

每個生成 App 都能選擇不同的原生主題、字體、背景、版面、間距、卡片表面、圖片、圖示與顏色，不會被限制成同一個卡片模板。

你可以使用自己的 OpenAI API key。Key 只存放在本機 iOS Keychain，AI 請求由 iPhone 直接送到 OpenAI；MakeYour 沒有代理伺服器，也不會把 Key 寫入專案或提示詞。

AI 不會下載或執行 Swift、JavaScript、外掛或任意程式碼，而是產生受 schema 限制的宣告式 App 文件，再由預先編譯的原生 SwiftUI 元件與固定能力白名單呈現。

匯率為 Frankfurter 提供的最新可用每日參考匯率，不是串流交易報價，也不構成投資建議。
```

## App privacy answers

Recommended conservative declaration for version 1.0:

- Data collection: Yes
- Data type: User Content → Other User Content
- Purpose: App Functionality
- Linked to the user: Yes, because reviewed text is authorized through the user's OpenAI account
- Used for tracking: No
- Tracking domains: None
- Photos or videos: Not collected; selected photos never leave the device
- Product interaction / analytics / diagnostics: Not collected by MakeYour
- Advertising: None

The app's privacy manifest mirrors this declaration and also declares the `CA92.1`
required-reason API for app-only `UserDefaults` access.

## Age rating

Recommended: answer the questionnaire truthfully, mark no unrestricted web access,
no broadly distributed user-generated content, no messaging, no ads, and no mature
content. Override the calculated result to `13+` because the core BYOK AI capability
requires an OpenAI account, whose terms require users to be at least 13 (or the
applicable local minimum age), with parental permission when under 18.

Do not select Made for Kids.

## Export compliance

- Uses encryption: Yes, only standard HTTPS and Apple Keychain provided by the OS
- Exempt/non-exempt encryption declaration: `ITSAppUsesNonExemptEncryption = NO`
- No custom or non-exempt encryption algorithms

## Availability and release

- Start with all countries and regions where both Apple and OpenAI API access are supported.
- Review country-specific AI availability before final selection.
- Release option: Automatically release after approval.
- App Store server notifications, Game Center, in-app purchases, and subscriptions: Not used.
