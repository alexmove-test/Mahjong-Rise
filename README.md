# Mahjong Rise

Tile matching puzzle game built with Flutter.

## Campaign challenges

Each 24-level cycle introduces three special tables: level 6 has a compact,
layered tower; level 12 ends when both starred goal tiles have been removed;
level 18 requires a full clear without shuffling. Other boosters remain available.
The goal is shown above the board, and starred tiles keep their marks in the tray.
Shuffling cannot change a starred tile's face. The no-shuffle rule also blocks
rewarded shuffle offers, without spending the player's saved charges.

New saves retain the challenge and goal tile IDs. Saves made before challenges
were introduced continue under their original full-clear rules. Daily tables use
the ordinary full-clear rules.

## Getting Started

```bash
flutter pub get
flutter run
```

For Firebase online leaderboard setup, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

## Home courtyard

The hub is a pannable country map. The player's own plateau is a single grassy
yard: one evolving house on the left and a living pet area beside it. The four
fenced pads on the map art are covered by that lawn so the home reads as one
courtyard. Leaderboard neighbors sit on the surrounding hills. The old four plot
tracks remain readable for save compatibility and are combined into the visible
house stage, so existing progress is preserved. Tapping the pet area opens the
full pet page. Players with several companions can choose which one appears in
the yard from that page.

Permanent reward choices such as the pond, swing, and flower bed sit around the
house on the plateau. The selected pet's active story title, mood, collected
items, and next translucent item appear directly in its yard area.

## Pet adventures

Every companion has five themed adventures with three visual chapters each: 25
stories and 75 collectible moments in total. Adventures are gifts, not a separate
start action. Every three first-time campaign clears unlock one choice: a remaining
courtyard object, or the next adventure chapter for a companion. Choosing a chapter
for a pet you do not yet have invites that pet into the yard and grants the first
item in the same step.

The five-story list on the pet page shows what is complete, waiting as a gift, or
still locked. Play continues the campaign; it does not start a story. Daily wins,
defeats, and replays of the same victory do not spend a gift. Progress is stored
under `pet.stories.v1`. Existing Fox adventure progress is migrated into A Cozy
Corner, while the old courtyard decoration remains intact.

After the choice, the earned item appears in a short story moment over the
courtyard, then as objects in the pet's yard scene. The moment respects
reduced-motion settings.

## Courtyard reward choices

Every three first-time campaign clears unlock one permanent gift: a little pond, a
garden swing, a flower bed, a table look (classic mahjong or bright match), or an
adventure chapter. The default ivory table stays free. Replays and daily tables do
not count. The player can postpone the choice and reopen it from the progress
banner. Later series keep offering remaining courtyard objects, table looks, and
unfinished adventures. Progress and choices are stored under `courtyard.rewards.v1`.
Existing completed campaign levels are credited once when the feature first loads.

## Localization

English is the template. Russian and Thai are the other supported languages.
Strings live in `lib/l10n/app_en.arb`, `lib/l10n/app_ru.arb`, and
`lib/l10n/app_th.arb`. The app reads them through `AppLocalizations`.

Add a string: put the same key in every ARB file. Use `{name}` placeholders and
an `@key` block with types. For counts, write the whole phrase as an ICU plural
(`one`/`few`/`many`/`other` in Russian, including 1, 2, 5, 11, and 21). Then run:

```bash
flutter gen-l10n
```

`flutter pub get` also regenerates, because `flutter: generate: true` is set.
Missing translations are listed in `lib/l10n/untranslated_messages.txt`.
Thai does not inflect plurals, so `one` and `other` use the same phrase. Thai
letters fall back to the bundled Noto Sans Thai font.

Add a language: copy `app_en.arb` to `app_<code>.arb`, translate every key, and
run generation again. The new locale is picked up from `supportedLocales`.
Wire it in `LanguagePref` and the settings picker only after the file is
complete. A partial Ukrainian draft is kept in `l10n_drafts/app_uk.arb` and is
not a supported locale.
