# Privacy Policy

**Last updated:** September 17, 2026

This Privacy Policy describes how **Mahjong Rise** (“the App”, “we”, “us”, or “our”) collects, uses, and shares information when you use our mobile game on Android (and other platforms where the App may be made available).

By installing or using the App, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree, please do not use the App.

---

## 1. Who we are

**App name:** Mahjong Rise  
**Package name:** `com.rise.mahjong`  
**Developer / Data controller:** Oleksii Hnylytskyi  
**Contact email:** myevidentsuccess@gmail.com

For privacy-related questions, requests, or complaints, please contact us at the email address above. Inappropriate leaderboard names can be reported **in the App** (see Section 8) or by email.

---

## 2. Overview

Mahjong Rise is an offline-capable tile-matching puzzle game with optional online features:

- **Online leaderboard** (powered by Google Firebase)
- **Rewarded advertisements** (powered by Google AdMob)
- **Product analytics** (powered by Google Firebase Analytics)
- **Optional local reminders** (scheduled on your device; not sent through our servers)

We do **not** require you to create an account with an email address or password. Online features use **anonymous authentication** provided by Firebase.

We do **not** sell your personal information.

The App is for a **general audience** and is **not** directed at children. It is **not** enrolled in Google Play’s Families program.

---

## 3. Information we collect

### 3.1 Information you provide

| Data | Description | Required? |
|------|-------------|-----------|
| **Display name** | A nickname you choose for the leaderboard (up to 20 characters) | Optional (default: a generated guest label) |

You are encouraged not to use your real name or other personally identifying information as your display name. Nicknames are **public user-generated content**: other players can see them on the leaderboard. On the leaderboard screen you can **report** a name or **hide** that player. A report is sent to us through the App when you are online; if that fails, the App can open an email draft to myevidentsuccess@gmail.com. Hiding a player is stored **only on your device** and does not notify them.

### 3.2 Information stored on your device (local)

The App stores progress and settings on your device using local storage (SharedPreferences), including:

- Campaign progress (levels unlocked, stars, best scores, in-progress table)
- Courtyard progress (house stage, decorations such as pond / swing / flower bed, table look)
- Pet companionship, stories, and related local state
- Player display name (if set) and local leaderboard sync metadata
- IDs of leaderboard players you have hidden
- Settings (language, sound, music, haptics, covered-tile dimming, reminder opt-in)

This data stays **on your device** unless a feature below sends a subset of it online. Clearing App storage or uninstalling the App deletes it.

The App also reads your device **timezone** locally so reminder times match the clock on your phone. We do not send your timezone to our servers.

### 3.3 Information collected automatically — online leaderboard (Firebase)

If you use the online leaderboard and have an internet connection, the App may send the following to **Google Firebase** (Cloud Firestore):

| Data | Purpose |
|------|---------|
| **Anonymous user ID** | Identifies your leaderboard entry without email/password |
| **Display name** | Shown on the public leaderboard |
| **Rating score** | Calculated from stars, best scores, and campaign progress |
| **Total stars** | Campaign progress |
| **Levels unlocked** | Campaign progress |
| **Sum of best scores** | Rating calculation |
| **Last updated timestamp** | Leaderboard ordering and sync |

The leaderboard is **publicly readable** by anyone using the App. Other players can see your display name and scores. Only you (via your anonymous account on this device) can update your own leaderboard entry. Players cannot delete their own Firestore document from inside the App; deletion is handled by us after a request (see Section 8).

If you **report** a nickname from the leaderboard, the App may also write a moderation record to Firestore (`ugc_reports`), including your anonymous user ID, the reported player’s anonymous ID and nickname, a reason code, and a timestamp. You cannot read other players’ reports. We use these records to review names and may remove or change an entry.

**Firebase services used:**

- Firebase Authentication (Anonymous sign-in)
- Cloud Firestore (database)
- Firebase Analytics (product funnel events)

**Firebase project:** `mahjong-rise`

### 3.4 Information collected automatically — product analytics (Firebase Analytics)

If you have an internet connection, the App may send anonymous gameplay events to **Firebase Analytics** so we can see where players get stuck and which levels or boosters need tuning. These events are not tied to your name or email. They may include:

- Level started, won, lost, or left (including level id, layout, and an anonymous session id)
- Daily-table or campaign mode
- Booster used (hint, shuffle, magnet, undo)
- Rewarded ad offered, completed, or skipped
- Score, remaining tiles, and booster charges at those moments
- Leaderboard opened, pet visit or adopt, reminder notification opened, streak broken
- A leaderboard name was reported or a player was hidden (no nickname is sent with those events)

Analytics is initialized with Firebase and is **not** gated by the advertising consent form. You can limit analytics by playing offline or by restricting app network access in your device settings.

This data is processed by **Google** in accordance with Google’s policies.

### 3.5 Information collected automatically — advertising (Google AdMob)

The App displays **optional rewarded video advertisements** through **Google AdMob** when you choose to watch a short video for an in-game boost (shuffle, magnet, hint, or undo).

In the European Economic Area (EEA), United Kingdom, and other regions where Google requires it, the App shows Google’s **User Messaging Platform (UMP)** consent form **on first launch**, before AdMob is initialized — not only when you tap to watch a video. Where Google requires an ongoing privacy-options entry point, a **Privacy settings** item appears in the App’s settings (and in the table menu) so you can change or withdraw that consent.

When ads are served, Google may collect information such as:

- Advertising ID (AAID on Android)
- Device information (device model, OS version)
- IP address (approximate location may be inferred)
- Ad interaction data (impressions, clicks, rewards)
- Diagnostic and performance data related to ad delivery
- Consent choices collected through UMP

This data is collected and processed by **Google** in accordance with Google’s policies, not directly by us.

**AdMob App ID:** `ca-app-pub-1561854396404271~8263443836`

For more information:

- [Google Privacy Policy](https://policies.google.com/privacy)
- [Google AdMob & Advertising](https://support.google.com/admob/answer/6128543)
- [How Google uses data from sites and apps that use its services](https://policies.google.com/technologies/partner-sites)

You can also reset or limit your advertising ID in **Android device settings** (Settings → Google → Ads → Reset advertising ID / Opt out of Ads Personalization).

### 3.6 Optional local reminders

If you turn reminders **on** in Settings, the App asks Android for notification permission and schedules **local** notifications on your device (for example, courtyard play reminders and pet-care reminders). Scheduling uses the clock and timezone on your phone.

- Reminders are **not** sent through our servers or Firebase Cloud Messaging.
- No precise GPS location is used.
- You can turn reminders off in Settings at any time; the App then cancels scheduled notifications.
- If you open the App from a reminder, we may log an anonymous `notification_open` analytics event (see Section 3.4).

### 3.7 Information we do NOT collect

We do **not** intentionally collect:

- Email address or phone number
- Precise GPS location
- Contacts, photos, microphone, or camera data
- Payment or financial information (the App has no in-app purchases; any future purchases would be handled by Google Play)

---

## 4. How we use your information

We use collected information to:

| Purpose | Legal basis (where applicable) |
|---------|-------------------------------|
| Save and restore your game progress and settings | Performance of the App’s core functionality |
| Display and sync the online leaderboard | Your use of optional online features |
| Calculate and rank player ratings | App functionality |
| Show the advertising consent form and deliver rewarded ads | Consent (UMP where required; you also choose whether to watch a video) |
| Schedule optional local reminders | Consent (in-app toggle and the OS notification permission) |
| Review reported leaderboard names | Legitimate interest / legal obligation to moderate public UGC |
| Understand level difficulty and booster use | Legitimate interest |
| Improve stability and fix bugs | Legitimate interest |
| Comply with legal obligations | Legal requirement |

We do **not** use your data for automated decision-making that produces legal or similarly significant effects.

---

## 5. Data sharing and third parties

We share data only with the following categories of recipients:

| Recipient | Data shared | Purpose |
|-----------|-------------|---------|
| **Google LLC (Firebase)** | Anonymous ID, display name, game stats, name-report records, anonymous gameplay events | Online leaderboard, anonymous auth, UGC reports, product analytics |
| **Google LLC (AdMob / UMP)** | Ad ID, device/ad interaction data, consent choices | Display rewarded ads and collect advertising consent |
| **Google LLC (Google Play)** | Standard Play distribution data | App distribution (when published on Play Store) |

Local reminders are not shared with these recipients.

We do **not** sell, rent, or trade your personal information to third parties for their marketing purposes.

Firebase and AdMob may process data on servers located outside your country, including the United States and the European Union, subject to Google’s data protection terms and standard contractual clauses where applicable.

---

## 6. Data retention

| Data type | Retention |
|-----------|-----------|
| **Local game progress and settings** | Until you uninstall the App or clear App data |
| **Hidden leaderboard players (local)** | Until you uninstall the App or clear App data |
| **Local reminder schedules** | Until you turn reminders off, deny notification permission, uninstall, or clear App data |
| **Leaderboard entry (Firestore)** | Until you request deletion by email and we remove the entry, or we remove inactive entries as part of maintenance |
| **Name-report records (Firestore)** | Until we finish reviewing the report and any related enforcement, then delete or anonymize as part of maintenance |
| **Anonymous Firebase account** | Managed by Firebase; tied to your device session. Uninstalling the App typically creates a new anonymous ID on next install. |
| **Firebase Analytics events** | Retained by Google per [Google’s retention policies](https://policies.google.com/privacy) |
| **AdMob / UMP data** | Retained by Google per [Google’s retention policies](https://policies.google.com/privacy) |

We may retain anonymized or aggregated data that cannot identify you for analytics and service improvement.

---

## 7. Data security

We take reasonable measures to protect your information:

- Data in transit to Firebase is encrypted via HTTPS/TLS
- Firestore security rules restrict writes so users can only update their own leaderboard document
- Leaderboard writes require authenticated (anonymous) access
- Firestore rules do not allow players to delete their own leaderboard document; we delete entries manually after a verified request

No method of transmission or storage is 100% secure. We cannot guarantee absolute security.

---

## 8. Your rights and choices

Depending on your location, you may have the right to:

- **Access** the personal data we hold about you
- **Correct** inaccurate data (e.g., change your display name in the App)
- **Delete** your data
- **Object** to or **restrict** certain processing
- **Withdraw consent** for optional features
- **Lodge a complaint** with your local data protection authority

### How to exercise your rights

1. **Display name:** Change it in the App on the leaderboard screen.
2. **Report or hide a public nickname:** On the leaderboard, open that player and choose **Report this name** or **Hide this player**. Report sends a record to us in the App (email is only a fallback if the App cannot send it). Hide removes them from **your** list only. You can also email myevidentsuccess@gmail.com with the name and, if possible, the rank or score.
3. **Local data:** Uninstall the App or clear App storage in Android Settings → Apps → Mahjong Rise → Storage → Clear data.
4. **Online leaderboard / anonymous account:** There is **no in-app delete button**. Email us at myevidentsuccess@gmail.com with your display name and approximate rating/scores so we can locate and delete your Firestore entry. Because accounts are anonymous, we may not be able to verify identity beyond information you provide.
5. **Advertising consent (EEA/UK and similar regions):** Use **Privacy settings** in the App when that item is shown. You can also skip rewarded videos entirely.
6. **Advertising ID:** Manage via Android device settings (see Section 3.5).
7. **Reminders:** Turn the reminder switch off in App settings, or revoke notification permission in Android Settings.
8. **Analytics / online features:** Play without a network connection, or restrict the App’s network access in Android Settings.

We will respond to requests within a reasonable timeframe and as required by applicable law (typically within 30 days).

---

## 9. Children’s privacy

Mahjong Rise is intended for a **general audience age 13 and over**. It is **not** directed at children under 13 (or the applicable digital-consent age in your jurisdiction). It is **not** designed for Google Play’s Families program, and we do **not** knowingly collect personal information from children.

Advertising is configured with **not under the age of consent**. We do not serve ads as a children’s app.

If you are a parent or guardian and believe your child has provided us with personal information, please contact us at myevidentsuccess@gmail.com and we will take steps to delete such information.

---

## 10. International users

If you access the App from the European Economic Area (EEA), United Kingdom, or other regions with data protection laws, you have additional rights under GDPR/UK GDPR as described in Section 8. Advertising consent in those regions is collected through Google UMP as described in Section 3.5.

Google acts as a processor/sub-processor for Firebase and AdMob services. Google’s compliance documentation is available at [Google Cloud & GDPR](https://cloud.google.com/privacy/gdpr).

---

## 11. Changes to this Privacy Policy

We may update this Privacy Policy from time to time. We will post the updated version on this page and change the **“Last updated”** date at the top.

For material changes, we may also notify you through the App or Google Play listing. Continued use of the App after changes constitutes acceptance of the updated Privacy Policy.

---

## 12. Contact us

If you have questions about this Privacy Policy or our data practices, please contact:

**Oleksii Hnylytskyi**  
Email: myevidentsuccess@gmail.com

---

## 13. Summary (plain language)

| Question | Answer |
|----------|--------|
| Do I need an account? | No email account. Optional anonymous online ID for the leaderboard. |
| Is my name public? | Your chosen nickname appears on the public leaderboard. Other players can report or hide it in the App. |
| Are there ads? | Yes — optional rewarded videos via Google AdMob. In the EEA/UK a consent form appears at launch; Privacy settings reopen it when required. |
| Are there notifications? | Optional local reminders only, if you turn them on. Nothing is pushed from our servers. |
| Is analytics collected? | Yes — anonymous gameplay events via Firebase Analytics when you are online. |
| Is data sold? | No. |
| Can I delete my data? | Yes — clear app data locally; email us to delete the online leaderboard entry (no in-app delete). |
| Who processes my data? | Primarily Google (Firebase, AdMob, UMP) under their policies. |

---

*This Privacy Policy applies to Mahjong Rise (`com.rise.mahjong`) published by Oleksii Hnylytskyi.*
