# TEZVPN Flutter

Одно приложение для **Google Play** и **App Store**: купили тариф — конфиг ставится — VPN (AmneziaWG) включается внутри приложения.

Исходники: `D:\TEZ VPN APP\flutter`  
Магазин: `https://188-116-24-47.sslip.io`

## Android → Google Play

1. Установите Flutter SDK (на этом ПК: `C:\Users\adol\flutter`).
2. В папке `flutter`:

```
flutter pub get
flutter build apk --debug
```

APK: `flutter/build/app/outputs/flutter-apk/app-debug.apk`

Для магазина: `flutter build appbundle` → `build/app/outputs/bundle/release/app-release.aab`

applicationId: `ru.tezvpn.app`

## iPhone → App Store

Собирается **только на Mac**.

1. Скопируйте папку `flutter` на Mac.
2. `flutter pub get` и откройте `ios/Runner.xcworkspace` в Xcode.
3. Signing: Team для **Runner** и расширения **TEZVPNTunnel**.
4. Capabilities: Network Extensions + App Groups `group.ru.tezvpn.app`.
5. File → Add Files: папка `ios/TEZVPNTunnel`. Добавьте target **Network Extension / Packet Tunnel** `ru.tezvpn.app.tunnel`, SPM `https://github.com/amnezia-vpn/amneziawg-apple` (WireGuardKit).
6. Product → Archive → Distribute App.

VPN на iOS — системное Network Extension с AmneziaWG. Нужен платный Apple Developer и Go (`brew install go`) для wg-go-bridge.

## Как пользоваться

Тариф → имя → перевод Alif / DC / WeChat / Alipay → фото чека → после подтверждения админа VPN включается сам.
