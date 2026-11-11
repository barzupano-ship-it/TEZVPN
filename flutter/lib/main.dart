import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'net_util.dart';
import 'shop_controller.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TezHttp();
  await ShopConfig.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(TezVpnApp(controller: ShopController(prefs: prefs)..init()));
}

/// Windows DNS (UDP sendto) fails with errno 10057 when the tunnel or IPv6
/// route has no address. sslip.io names are the server IP, so connect to that
/// IP and keep the real host name for TLS.
class TezHttp extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 20);
    client.idleTimeout = const Duration(seconds: 2);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      final ip = sslipAddress(uri.host);
      if (ip == null) {
        if (uri.scheme == 'https') {
          final task = await SecureSocket.startConnect(uri.host, uri.port);
          return ConnectionTask.fromSocket<Socket>(
            task.socket.then<Socket>((socket) => socket),
            task.cancel,
          );
        }
        final plain = await Socket.startConnect(uri.host, uri.port);
        return ConnectionTask.fromSocket<Socket>(plain.socket, plain.cancel);
      }
      final socket = await Socket.connect(
        InternetAddress(ip),
        uri.port,
        timeout: const Duration(seconds: 15),
      );
      final secure = await SecureSocket.secure(socket, host: uri.host);
      return ConnectionTask.fromSocket<Socket>(
        Future<Socket>.value(secure),
        () => secure.destroy(),
      );
    };
    return client;
  }
}

class TezVpnApp extends StatelessWidget {
  const TezVpnApp({super.key, required this.controller});
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ShopConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2F6FED),
          onPrimary: Colors.white,
          surface: Colors.white,
          error: Color(0xFFC62828),
        ),
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
      ),
      home: DesktopPhoneFrame(child: TezHome(controller: controller)),
    );
  }
}

/// Windows and Mac use the same phone layout as the mobile app.
class DesktopPhoneFrame extends StatelessWidget {
  const DesktopPhoneFrame({super.key, required this.child});

  final Widget child;

  static const _width = 430.0;

  bool get _desktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    if (!_desktop) return child;
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < _width ? constraints.maxWidth : _width;
          final height = constraints.maxHeight;
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: Size(width, height)),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
