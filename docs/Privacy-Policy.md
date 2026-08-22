# Privacy Policy

**Last updated:** August 15, 2026

This Privacy Policy describes how **Mahjong Rise** (“the App”, “we”, “us”, or “our”) collects, uses, and shares information when you use our mobile game on Android (and other platforms where the App may be made available).

By installing or using the App, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree, please do not use the App.

---

## 1. Who we are

**App name:** Mahjong Rise  
**Package name:** `com.rise.mahjong`  
**Developer / Data controller:** Oleksii Hnylytskyi  
**Contact email:** myevidentsuccess@gmail.com

For privacy-related questions, requests, or complaints, please contact us at the email address above.

---

## 2. Overview

Mahjong Rise is an offline-capable tile-matching puzzle game with optional online features:

- **Online leaderboard** (powered by Google Firebase)
- **Rewarded advertisements** (powered by Google AdMob)

We do **not** require you to create an account with an email address or password. Online features use **anonymous authentication** provided by Firebase.

We do **not** sell your personal information.

---

## 3. Information we collect

### 3.1 Information you provide

| Data | Description | Required? |
|------|-------------|-----------|
| **Display name** | A nickname you choose for the leaderboard (up to 20 characters) | Optional (default: generic label) |

You are encouraged not to use your real name or other personally identifying information as your display name.

### 3.2 Information collected automatically — game progress (local)

The App stores game progress on your device using local storage (SharedPreferences), including:

- Levels unlocked
- Stars earned per level
- Best scores per level
- Player display name (if set)
- Local sync metadata for the leaderboard

This data is stored **on your device** and is used to save your progress and calculate your rating.

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

The leaderboard is **publicly readable** by anyone using the App. Other players can see your display name and scores. Only you (via your anonymous account on your device) can update your own leaderboard entry.

**Firebase services used:**

- Firebase Authentication (Anonymous sign-in)
- Cloud Firestore (database)

**Firebase project:** `mahjong-rise`

### 3.4 Information collected automatically — advertising (Google AdMob)

The App displays **rewarded advertisements** through **Google AdMob**. When you choose to watch an ad (for example, to receive an in-game boost), Google may collect information such as:

- Advertising ID (AAID on Android)
- Device information (device model, OS version)
- IP address (approximate location may be inferred)
- Ad interaction data (impressions, clicks, rewards)
- Diagnostic and performance data related to ad delivery

This data is collected and processed by **Google** in accordance with Google’s policies, not directly by us.

**AdMob App ID:** `ca-app-pub-1524654355170130~6121469025`

For more information:

- [Google Privacy Policy](https://policies.google.com/privacy)
- [Google AdMob & Advertising](https://support.google.com/admob/answer/6128543)
- [How Google uses data from sites and apps that use its services](https://policies.google.com/technologies/partner-sites)

You can reset or limit your advertising ID in your **Android device settings** (Settings → Google → Ads → Reset advertising ID / Opt out of Ads Personalization).

### 3.5 Information we do NOT collect

We do **not** intentionally collect:

- Email address or phone number
- Precise GPS location
- Contacts, photos, microphone, or camera data
- Payment or financial information (the App is free; any purchases would be handled by Google Play if added in the future)

---

## 4. How we use your information

We use collected information to:

| Purpose | Legal basis (where applicable) |
|---------|-------------------------------|
| Save and restore your game progress | Performance of the App’s core functionality |
| Display and sync the online leaderboard | Your use of optional online features |
| Calculate and rank player ratings | App functionality |
| Deliver rewarded advertisements | Your consent (when you tap to watch an ad) |
| Improve stability and fix bugs | Legitimate interest |
| Comply with legal obligations | Legal requirement |

We do **not** use your data for automated decision-making that produces legal or similarly significant effects.

---

## 5. Data sharing and third parties

We share data only with the following categories of recipients:

| Recipient | Data shared | Purpose |
|-----------|-------------|---------|
| **Google LLC (Firebase)** | Anonymous ID, display name, game stats | Online leaderboard, anonymous auth |
| **Google LLC (AdMob)** | Ad ID, device/ad interaction data | Display rewarded ads |
| **Google LLC (Google Play)** | Standard Play distribution data | App distribution (when published on Play Store) |

We do **not** sell, rent, or trade your personal information to third parties for their marketing purposes.

Firebase and AdMob may process data on servers located outside your country, including the United States and the European Union, subject to Google’s data protection terms and standard contractual clauses where applicable.

---

## 6. Data retention

| Data type | Retention |
|-----------|-----------|
| **Local game progress** | Until you uninstall the App or clear App data |
| **Leaderboard entry (Firestore)** | Until you request deletion or we remove inactive entries as part of maintenance |
| **Anonymous Firebase account** | Managed by Firebase; tied to your device session |
| **AdMob data** | Retained by Google per [Google’s retention policies](https://policies.google.com/privacy) |

We may retain anonymized or aggregated data that cannot identify you for analytics and service improvement.

---

## 7. Data security

We take reasonable measures to protect your information:

- Data in transit to Firebase is encrypted via HTTPS/TLS
- Firestore security rules restrict writes so users can only update their own leaderboard document
- Leaderboard writes require authenticated (anonymous) access

No method of transmission or storage is 100% secure. We cannot guarantee absolute security.

---

## 8. Your rights and choices

Depending on your location, you may have the right to:

- **Access** the personal data we hold about you
- **Correct** inaccurate data (e.g., change your display name in the App)
- **Delete** your data
- **Object** to or **restrict** certain processing
- **Withdraw consent** for optional features (e.g., do not watch ads; disable online features by playing offline)
- **Lodge a complaint** with your local data protection authority

### How to exercise your rights

1. **Display name:** Change it in the App on the leaderboard screen.
2. **Local data:** Uninstall the App or clear App storage in Android Settings → Apps → Mahjong Rise → Storage → Clear data.
3. **Online leaderboard data:** Email us at myevidentsuccess@gmail.com with your display name and approximate rating/scores so we can locate and delete your Firestore entry. Because accounts are anonymous, we may not be able to verify identity beyond information you provide.
4. **Advertising preferences:** Manage via Android device settings (see Section 3.4).

We will respond to requests within a reasonable timeframe and as required by applicable law (typically within 30 days).

---

## 9. Children’s privacy

Mahjong Rise is intended for a **general audience** and is not directed at children under 13 (or the applicable age in your jurisdiction).

We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has provided us with personal information, please contact us at myevidentsuccess@gmail.com and we will take steps to delete such information.

If the App is made available to children on Google Play, we will comply with Google Play’s Families Policy and applicable laws (including COPPA where relevant), including use of age-appropriate ad formats and disclosures.

---

## 10. International users

If you access the App from the European Economic Area (EEA), United Kingdom, or other regions with data protection laws, you have additional rights under GDPR/UK GDPR as described in Section 8.

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
| Do I need an account? | No email account. Optional anonymous online ID for leaderboard. |
| Is my name public? | Your chosen nickname appears on the public leaderboard. |
| Are there ads? | Yes — optional rewarded video ads via Google AdMob. |
| Is data sold? | No. |
| Can I delete my data? | Yes — clear app data locally; email us for online leaderboard deletion. |
| Who processes my data? | Primarily Google (Firebase, AdMob) under their policies. |

---

*This Privacy Policy applies to Mahjong Rise (`com.rise.mahjong`) published by Oleksii Hnylytskyi.*
