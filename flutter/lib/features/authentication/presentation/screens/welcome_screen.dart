import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shop_controller.dart';
import 'identifier_login_screen.dart';
import '../widgets/gaming_collage.dart';
import '../widgets/legal_notice.dart';
import '../widgets/playport_logo.dart';
import '../widgets/primary_login_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.shop});

  final ShopController shop;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final collageHeight = height * 0.46;
          final form = shop.registrationOpen;
          return Stack(
            children: [
              const ColoredBox(color: Colors.white),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: collageHeight,
                child: const GamingCollage(),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      SizedBox(height: form ? collageHeight * 0.22 : collageHeight * 0.72),
                      const PlayportLogo(),
                      const SizedBox(height: 16),
                      if (form)
                        Expanded(child: RegistrationForm(shop: shop))
                      else ...[
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
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

