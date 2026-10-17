# SULTAN VPN — проект для магазинов

Это готовое приложение. Внутри магазин тарифов и VPN AmneziaWG. На экране название **SULTAN VPN**. Техническое имя пакета не меняйте: от него зависят Google Play, App Store и уже выпущенный ключ подписи.

Отдайте клиенту всю папку `flutter`. Вместе с ней должны уехать два файла подписи, они уже лежат внутри:

- `android/app/upload-keystore.jks` — ключ загрузки в Google Play
- `android/key.properties` — пароль этого ключа

Эти два файла не публикуйте в открытый репозиторий и не присылайте в чат. Без них следующее обновление в Play нельзя будет подписать тем же ключом.

## Что не менять

| | |
|---|---|
| Android applicationId | `ru.tezvpn.app` |
| iPhone bundle id | `ru.tezvpn.app` |
| Расширение туннеля | `ru.tezvpn.app.tunnel` |
| Версия сейчас | `1.0.5+6` в `pubspec.yaml` |
| Ключ | alias `upload`, файл `upload-keystore.jks` |
| SHA-1 ключа | `B9:62:1A:EC:BF:51:CA:0B:6C:4E:0F:B1:92:99:68:BA:F5:4F:81:25` |

Перед каждой новой загрузкой в магазин увеличьте версию в `pubspec.yaml`. Пример: `1.0.6+7`. Число после `+` должно расти каждый раз.

## Что нужно клиенту

Свои аккаунты разработчика:

- Google Play Console
- Apple Developer Program

На компьютере для Android: Flutter 3.24 или новее, JDK 17, Android SDK.  
На Mac для iPhone: Xcode, Flutter, Go (`brew install go`). Сборка iPhone с Windows невозможна.

Сайт приложения: `https://188-116-24-47.sslip.io`

## Google Play

В папке `flutter`:

```
flutter pub get
flutter build appbundle --release
```

Файл для загрузки:

`build/app/outputs/bundle/release/app-release.aab`

В Play Console: создать приложение → Production или внутреннее тестирование → загрузить этот AAB.

При создании записи укажите:

- название **SULTAN VPN**
- пакет `ru.tezvpn.app`
- подпись тем ключом, который уже в проекте. Play App Signing можно включить, загрузочный ключ — этот `upload-keystore.jks`
- тип приложения: VPN. Разрешение VPN и фоновая служба уже есть в манифесте
- политику конфиденциальности по публичной ссылке. Черновик внутри приложения магазином не принимается, нужна страница на сайте
- возраст и анкету содержимого в консоли Play

Проверочный APK, не для магазина:

```
flutter build apk --release
```

`build/app/outputs/flutter-apk/app-release.apk`

## App Store

Папка `ios` уже содержит приложение Runner и расширение туннеля TEZVPNTunnel. Библиотека AmneziaWG лежит в `ios/amneziawg-apple`. Если этой папки нет, на Mac выполните из `flutter/ios`:

```
git clone --depth 1 https://github.com/amnezia-vpn/amneziawg-apple.git amneziawg-apple
```

Дальше на Mac, в папке `flutter`:

```
flutter pub get
open ios/Runner.xcworkspace
```

В Xcode у двух целей, **Runner** и **TEZVPNTunnel**:

1. Signing & Capabilities → Team: аккаунт клиента.
2. Bundle Identifier не менять: `ru.tezvpn.app` и `ru.tezvpn.app.tunnel`.
3. Capability Network Extensions → Packet Tunnel. Apple включает это расширение отдельно в аккаунте разработчика. Пока галочка не одобрена, архив не пройдёт.

Затем Product → Archive → Distribute App → App Store Connect.

В App Store Connect создайте приложение с bundle id `ru.tezvpn.app`, имя **SULTAN VPN**, версия как в `pubspec.yaml`.

## Windows

Установщик для сайта, не для Google Play:

```
flutter build windows --release
```

Готовый установщик собирается скриптом `downloads/TEZVPN.nsi` через NSIS. Имя программы SULTAN VPN, файл установки `TEZVPN-Setup.exe`.

## Mac с сайта

Кнопка Mac на сайте отдаёт `AmneziaVPN-macOS.pkg`. Это отдельный установщик Amnezia, его нельзя подписывать и называть как SULTAN VPN.
