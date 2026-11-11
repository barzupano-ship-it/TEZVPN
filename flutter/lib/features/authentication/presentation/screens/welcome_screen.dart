import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shop_controller.dart';
import 'identifier_login_screen.dart';
import '../widgets/legal_notice.dart';
import '../widgets/playport_logo.dart';
import '../widgets/primary_login_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: shop.registrationOpen
                ? Column(
                    children: [
                      const SizedBox(height: 28),
                      const PlayportLogo(),
                      const SizedBox(height: 16),
                      Expanded(child: RegistrationForm(shop: shop)),
                    ],
                  )
                : Column(
                    children: [
                      const Spacer(),
                      const PlayportLogo(),
                      const SizedBox(height: 28),
                      PrimaryLoginButton(
                        label: shop.l10n.registerButton,
                        onPressed: () => shop.openRegistration(create: true),
                      ),
                      const SizedBox(height: 12),
                      PrimaryLoginButton(
                        label: shop.l10n.loginButton,
                        filled: false,
                        onPressed: () => shop.openRegistration(create: false),
                      ),
                      const Spacer(),
                      LegalNotice(
                        prefix: shop.l10n.legalPrefix,
                        terms: shop.l10n.legalTerms,
                        andWord: shop.l10n.legalAnd,
                        privacy: shop.l10n.legalPrivacy,
                        onTerms: () => shop.go('terms'),
                        onPrivacy: () => shop.go('privacy'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
