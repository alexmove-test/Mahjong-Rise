# Release-подпись Android (Mahjong Rise)

## Файлы (не коммитить в git)

| Файл | Назначение |
|------|------------|
| `android/app/mahjong-rise-release.jks` | Keystore |
| `android/key.properties` | Пароли и путь к keystore |

Оба файла уже в `.gitignore`. **Сохраните резервную копию** — без них нельзя обновлять приложение в Google Play.

## Сборка для Google Play

```powershell
flutter build appbundle --release
```

AAB-файл:

```
build\app\outputs\bundle\release\app-release.aab
```

Или APK:

```powershell
flutter build apk --release
```

## Если keystore потерян

Создайте новый (потребуется новое приложение в Play Console или обращение в поддержку Google):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -genkeypair -v -storetype PKCS12 -keyalg RSA -keysize 2048 `
  -validity 10000 -alias mahjong-rise `
  -keystore android/app/mahjong-rise-release.jks
```

Скопируйте `key.properties.example` → `key.properties` и заполните пароли.

## Проверка подписи

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" `
  -list -v -keystore android/app/mahjong-rise-release.jks
```
