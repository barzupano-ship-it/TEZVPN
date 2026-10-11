import 'package:flutter_test/flutter_test.dart';
import 'package:tezvpn/main.dart';
import 'package:tezvpn/shop_controller.dart';

void main() {
  testWidgets('shows TEZVPN title', (tester) async {
    await tester.pumpWidget(TezVpnApp(controller: ShopController()));
    expect(find.text('TEZVPN'), findsWidgets);
  });
}
