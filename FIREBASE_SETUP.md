# Firebase: онлайн-рейтинг

## 1. Создайте проект Firebase

1. Откройте [Firebase Console](https://console.firebase.google.com/).
2. Создайте проект (например, `mahjong-rise`).
3. Добавьте приложение **Android** с package name: `com.rise.mahjong` (отображаемое имя: **Mahjong Rise**).
4. Скачайте `google-services.json` и положите в:

```
android/app/google-services.json
```

5. (Опционально) добавьте iOS-приложение и скачайте `GoogleService-Info.plist` в `ios/Runner/`.

## 2. Включите сервисы

### Authentication
- Firebase Console → **Authentication** → **Sign-in method**
- Включите **Anonymous**

### Firestore
- Firebase Console → **Firestore Database** → **Create database**
- Режим: production
- Регион: ближайший к игрокам (например, `europe-west1`)

### Правила Firestore
- Firebase Console → **Firestore** → **Rules**
- Вставьте содержимое файла `firestore.rules` из корня репозитория
- Нажмите **Publish**

### Индекс (если попросит)
Запрос сортирует по `rating` — базового single-field индекса обычно достаточно.

## 3. Сгенерируйте конфиг Flutter

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Команда обновит `lib/firebase_options.dart` и конфиги платформ.

## 4. Проверка

```bash
flutter run
```

1. Пройдите уровень — рейтинг отправится в Firestore после победы.
2. Откройте **Общий рейтинг** на экране уровней.
3. В Firebase Console → Firestore → коллекция `leaderboard` должны появиться документы.

## Структура данных

Коллекция: `leaderboard/{uid}`

| Поле | Тип | Описание |
|------|-----|----------|
| `name` | string | Имя игрока (до 20 символов) |
| `rating` | int | Сводный рейтинг |
| `totalStars` | int | Звёзды кампании |
| `levelsUnlocked` | int | Открытые уровни |
| `sumBestScores` | int | Сумма лучших счётов |
| `updatedAt` | timestamp | Время обновления |

## Формула рейтинга

```
rating = totalStars × 100 000 + sumBestScores + maxUnlocked × 500
```

## Офлайн-режим

Пока `lib/firebase_options.dart` содержит `REPLACE_ME`, приложение работает без онлайн-рейтинга и показывает только ваш локальный результат.

## Release-сборка Android

- Сборка **работает без** `google-services.json` (онлайн-рейтинг просто отключён)
- Для Firebase в release добавьте `google-services.json` — плагин подключится автоматически
- Разрешение `INTERNET` уже добавлено в `AndroidManifest.xml`
- `minSdk` установлен минимум **23**
