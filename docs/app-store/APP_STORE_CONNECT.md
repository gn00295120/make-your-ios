# App Store Connect release sheet — expanded capability build

This file describes the current expanded source tree. It must not be applied to
the already submitted MakeYour 1.0.0 (build 1) binary. Before using this
metadata, increment the build number, archive the current source, complete the
physical-device checks in `RELEASE_CHECKLIST.md`, upload that archive, and
select the matching build in App Store Connect.

## App record

- Platforms: iOS
- Name: `MakeYour`
- Primary language: English (U.S.)
- Bundle ID: `com.longweiwang.makeyourios`
- SKU: `MAKEYOUR-IOS-001`
- User access: Full Access
- Version: `1.0.0` (existing App Store version; change only if releasing as an update)
- Build: next uploaded build, greater than `1`
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
Describe the tool you need, then use a private native tiny app with provider data, records, games, device actions, and reviewed AI.
```

### Keywords

```text
AI,builder,mini apps,scanner,QR,news,stocks,budget,reminder,productivity
```

### Description

```text
Stop downloading another tiny app. Make yours.

MakeYour turns a sentence into a useful native tiny app inside one trusted iPhone app. Build a personal tracker, checklist, calculator, reminder workflow, photo journal, live-data dashboard, budget ledger, or small game—then keep several apps and switch between them whenever you need.

WHAT YOU CAN BUILD

• Personal record collections with notes, numbers, dates, totals, completion, and reminders
• Task lists and local notification workflows
• Calculators and currency-conversion tools
• Credited BBC/NPR news collections with local search, topics, and bookmarks
• Stock and ETF watchlists with latest/delayed Twelve Data quotes and charts
• Income and expense ledgers with balances, budgets, and category totals
• Complete original platform and Snake games with touch controls and scoring
• Photo-first private journals and trackers using selected or captured images
• Latest daily FX watchlists with a chosen base currency, editable currencies, and threshold alerts
• Tap-initiated camera, QR/barcode/text scanning, one-time location, contact and text-file selection, today's steps, sharing, clipboard write, and haptic feedback
• Focused AI helpers that receive only text you explicitly review and send

YOUR STYLE, NOT ONE TEMPLATE

Generated apps can use different native themes, typography, backgrounds, layouts, spacing, surfaces, imagery, symbols, and colors. MakeYour keeps the experience accessible and familiar while giving each app its own visual direction.

BRING YOUR OWN OPENAI KEY

Your API key is stored in iOS Keychain for this device only. AI requests travel directly from your iPhone to OpenAI. MakeYour does not operate an account or proxy server and never puts your key in a project file or prompt.

Market Pocket includes AAPL public demo access. Other symbols can use your optional Twelve Data key, also stored in the device-only Keychain and sent directly to that provider.

PRIVATE BY DESIGN

Projects, records, bookmarks, watchlists, ledgers, and selected or captured results stay on your iPhone. Device access starts only after you tap, scanned URLs are not opened automatically, and there is no background location or motion monitoring. Sharing leaves MakeYour only after you choose a destination in Apple's share sheet. Before an in-app AI request, MakeYour shows the exact task and text that will be sent. Photos, records, other apps, and device data are not attached automatically.

SAFE NATIVE RUNTIME

AI does not download or execute Swift, JavaScript, plug-ins, or arbitrary code. It creates a validated declarative app document. MakeYour renders that document using precompiled native SwiftUI components and a fixed capability allowlist.

Network components use only fixed, precompiled providers: Frankfurter for latest daily FX reference rates, BBC/NPR for credited RSS feeds, Twelve Data for latest/delayed market data, and OpenAI for user-authorized AI. Market and currency values are not guaranteed real-time and are not financial advice.

Camera capture, live scanning, pedometer data, and meaningful haptic feedback require supported physical iPhone hardware. Unsupported devices and Simulator show an honest unavailable state.
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
描述你需要的小工具，生成含服務資料、個人紀錄、遊戲、裝置動作與經你確認後才送出的 AI 原生迷你 App。
```

### Keywords

```text
AI,迷你App,生成,掃描,QR,新聞,股票,記帳,提醒,生產力
```

### Description

```text
別再下載另一個小工具，直接做出自己的。

MakeYour 能把一句需求變成同一個 iPhone App 裡可立即操作的原生迷你 App。你可以製作個人追蹤器、待辦清單、計算機、提醒流程、相片日誌、新聞與市場看板、收支帳本或小遊戲，再把多個 App 收進自己的 App Library 隨時切換。

可生成的功能包括：

• 含備註、數字、日期、統計、完成狀態與提醒的個人資料表
• 待辦清單與本機通知
• 計算與換匯工具
• 可在本機搜尋、分類與收藏的 BBC／NPR 新聞
• 含最新或延遲報價與圖表的股票、ETF 觀察表
• 自動計算收支、結餘、預算與分類統計的個人帳本
• 有觸控、碰撞、計分、暫停與重玩的原創平台遊戲及貪食蛇
• 使用自行選取或拍攝照片、只留在裝置上的日誌與追蹤器
• 可選主要貨幣、增刪幣別與設定門檻警示的最新每日匯率觀察表
• 點擊後才啟動的相機、QR／條碼／文字掃描、單次定位、聯絡人與文字檔選取、今日步數、分享、剪貼簿寫入與觸覺回饋
• 只有在你確認文字後才會送出的專用 AI 助手

每個生成 App 都能選擇不同的原生主題、字體、背景、版面、間距、卡片表面、圖片、圖示與顏色，不會被限制成同一個卡片模板。

你可以使用自己的 OpenAI API key；AAPL 以外的市場代號也可選擇加入自己的 Twelve Data key。Key 只存放在本機 iOS Keychain，請求由 iPhone 直接送到指定服務；MakeYour 沒有代理伺服器，也不會把 Key 寫入專案或提示詞。

專案、紀錄、收藏、帳本與拍攝或選取的結果留在 iPhone。裝置功能只在點擊後啟動，掃描到的網址不會自動開啟，也沒有背景定位或動作監控。分享內容只有在你從 Apple 分享表單選擇目的地後才會離開 MakeYour。相機拍攝、即時掃描、計步與有意義的觸覺測試需要支援的實體 iPhone；不支援的裝置或模擬器會清楚顯示無法使用。

AI 不會下載或執行 Swift、JavaScript、外掛或任意程式碼，而是產生受 schema 限制的宣告式 App 文件，再由預先編譯的原生 SwiftUI 元件與固定能力白名單呈現。

網路元件只使用預先編譯的固定服務：Frankfurter 每日參考匯率、BBC／NPR RSS、Twelve Data 市場資料與經使用者授權的 OpenAI。市場與匯率資料不保證即時，也不構成投資建議。
```

## App privacy answers

Current privacy-manifest baseline for the expanded build:

- Data collection: Yes
- Data type: User Content → Other User Content
- Purpose: App Functionality
- Linked to the user: Yes, because reviewed text is authorized through the user's OpenAI account
- Used for tracking: No
- Tracking domains: None
- Photos or videos: Not collected; selected and captured photos stay on device
- Precise location, contacts, and fitness: Not collected by MakeYour; the
  one-time results stay in project-local state and are not sent to a provider
- Product interaction / analytics / diagnostics: Not collected by MakeYour
- Advertising: None

The app's privacy manifest mirrors this declaration and also declares the `CA92.1`
required-reason API for app-only `UserDefaults` access.

Before submitting the expanded build, re-run Apple's privacy questionnaire
against the current retention practices of OpenAI and Twelve Data, following
Apple's [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
guidance. In particular, determine whether provider-account API keys must also
be declared as a User ID/identifier and whether retained symbol/feed request
logs create an additional Search History or Usage Data declaration. If an
answer changes, update both App Store Connect and `PrivacyInfo.xcprivacy`; do
not rely on the build 1 answers by default.

## Age rating

Recommended: answer the questionnaire truthfully, mark no unrestricted web access,
no broadly distributed user-generated content, no messaging, no ads, and no mature
content. Override the calculated result to `13+` because the core BYOK AI capability
requires an OpenAI account, whose terms require users to be at least 13 (or the
applicable local minimum age), with parental permission when under 18.

Reconfirm this against OpenAI's current
[Terms of Use](https://openai.com/policies/terms-of-use/) at submission time.

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
