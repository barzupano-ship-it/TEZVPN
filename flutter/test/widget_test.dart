import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tezvpn/features/vpn/application/tunnel_options.dart';
import 'package:tezvpn/main.dart';
import 'package:tezvpn/shop_controller.dart';

void main() {
  testWidgets('shows the VPN home screen', (tester) async {
    final shop = ShopController();
    await tester.pumpWidget(TezVpnApp(controller: shop));
    expect(find.text('SULTAN VPN'), findsOneWidget);
    shop.go('vpn');
    await tester.pump();
    expect(find.text('Нажмите, чтобы подключить'), findsOneWidget);
    expect(find.text('Нет подключения'), findsOneWidget);
  });

  testWidgets('welcome screen matches the login layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final shop = ShopController();
    await tester.pumpWidget(TezVpnApp(controller: shop));
    await tester.pump();

    expect(find.text('SULTAN VPN'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Войти с помощью почты или телефона'), findsNothing);
    expect(find.textContaining('Условиями использования'), findsOneWidget);
    expect(find.textContaining('Политикой конфиденциальности'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Регистрация'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Почта или телефон'), findsOneWidget);
    expect(find.text('Пароль ещё раз'), findsOneWidget);
    expect(find.text('Создать аккаунт'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.tap(find.text('Вход'));
    await tester.pump();
    expect(find.text('Пароль ещё раз'), findsNothing);
    expect(find.text('Войти'), findsOneWidget);
  });

  testWidgets('subscription period selector shows four prices', (tester) async {
    final shop = ShopController();
    await tester.pumpWidget(TezVpnApp(controller: shop));
    shop.go('home');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1 месяц'), findsWidgets);
    expect(find.text('3 месяца'), findsOneWidget);
    expect(find.text('6 месяцев'), findsOneWidget);
    expect(find.text('12 месяцев'), findsOneWidget);
    expect(find.text('-30%'), findsNothing);
    expect(find.text('Free'), findsNothing);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('VIP'), findsOneWidget);
    expect(find.text('Plus'), findsNothing);
    expect(find.text('25 смн'), findsOneWidget);
    expect(find.text('¥18'), findsOneWidget);
    expect(find.text('42 смн'), findsOneWidget);
    expect(find.text('¥30'), findsOneWidget);
    expect(find.text('76 смн'), findsOneWidget);
    expect(find.text('¥55'), findsOneWidget);

    await tester.tap(find.text('3 месяца'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('104 смн'), findsOneWidget);

    await tester.tap(find.text('6 месяцев'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('215 смн'), findsOneWidget);

    await tester.tap(find.text('12 месяцев'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('210 смн'), findsOneWidget);
    expect(find.text('¥151'), findsOneWidget);
    expect(find.text('348 смн'), findsOneWidget);
    expect(find.text('¥250'), findsOneWidget);
    expect(find.text('630 смн'), findsOneWidget);
    expect(find.text('¥453'), findsOneWidget);
    expect(find.text('0 смн'), findsNothing);
  });

  testWidgets('settings screen lists account, features, and the real protocol', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final shop = ShopController();
    await tester.pumpWidget(TezVpnApp(controller: shop));
    shop.go('settings');
    await tester.pump();

    expect(find.text('Кабинет'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('Войти на другом устройстве'), findsOneWidget);
    expect(find.text('Аварийное отключение'), findsOneWidget);
    expect(find.text('Протокол'), findsOneWidget);
    expect(find.text('AmneziaWG'), findsOneWidget);
    expect(find.text('Дополнительно'), findsNothing);
    expect(find.text('Общие'), findsOneWidget);
    expect(find.text('PLUS'), findsNothing);
    expect(find.text('NetShield'), findsNothing);
    expect(find.text('Раздельное туннелирование'), findsNothing);
    expect(find.text('Ускорение VPN'), findsNothing);
    expect(find.text('Конфиденциальность'), findsNothing);
    expect(find.text('VLESS'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Протокол'));
    await tester.pump();
    expect(find.text('AmneziaWG — единственный протокол в этом VPN.'), findsOneWidget);
    expect(find.text('VLESS'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Profile'));
    await tester.pump();
    expect(find.text('Кабинет'), findsOneWidget);
    await shop.setLang('en');
    await tester.pump();
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Кабинет'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.bySemanticsLabel('Home'));
    await tester.pump();
    expect(find.text('Tap to connect'), findsOneWidget);
  });

  test('tunnel options change dns without dropping the key line', () {
    const conf = '[Interface]\nPrivateKey = testkey\nDNS = 8.8.8.8\n\n[Peer]\nPublicKey = peer\n';
    final out = applyTunnelOptions(conf, netShield: true, accelerator: false, excludedApps: {'com.example.app'});
    expect(out.contains('PrivateKey = testkey'), isTrue);
    expect(out.contains('DNS = 94.140.14.14, 94.140.15.15'), isTrue);
    expect(out.contains('DomainBlockingEnabled = true'), isTrue);
    expect(out.contains('ExcludedApplications = com.example.app'), isTrue);
    expect(out.contains('PublicKey = peer'), isTrue);
  });
}
