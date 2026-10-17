import 'package:flutter/material.dart';

import '../../../../shop_controller.dart';

/// Registration and sign-in for the PlayPORT welcome screen.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.shop});

  final ShopController shop;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();

  bool get _creating => widget.shop.registering;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final t = shop.l10n;
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: shop.closeRegistration,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1C1E), size: 18),
            ),
            Text(
              _creating ? t.registerButton : t.loginButton,
              style: const TextStyle(color: Color(0xFF1A1C1E), fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        Text(
          _creating ? t.registerBlurb : t.loginBlurb,
          style: const TextStyle(color: Color(0xFF5C6166), fontSize: 14),
        ),
        const SizedBox(height: 14),
        _Field(
          controller: _id,
          label: t.settingsEmailOrPhone,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _Field(controller: _password, label: t.passwordLabel, secret: true),
        if (_creating) ...[
          const SizedBox(height: 10),
          _Field(controller: _again, label: t.passwordAgain, secret: true),
        ],
        if (shop.error != null) ...[
          const SizedBox(height: 10),
          Text(shop.error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 13)),
        ],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: shop.busy
              ? null
              : () {
                  if (_creating) {
                    shop.registerWithIdentifier(_id.text, _password.text, _again.text);
                  } else {
                    shop.signInExisting(_id.text, _password.text);
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2F6FED),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
          ),
          child: shop.busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_creating ? t.createAccount : t.signIn),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.secret = false,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final bool secret;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: secret,
      keyboardType: keyboard,
      autocorrect: false,
      style: const TextStyle(color: Color(0xFF1C1B22)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6E6A78)),
        filled: true,
        fillColor: const Color(0xFFEEF4FF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5E4F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF927FFF)),
        ),
      ),
    );
  }
}
