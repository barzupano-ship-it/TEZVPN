import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LegalNotice extends StatefulWidget {
  const LegalNotice({
    super.key,
    required this.onTerms,
    required this.onPrivacy,
    this.prefix = 'Продолжая, вы соглашаетесь с ',
    this.terms = 'Условиями использования',
    this.andWord = ' и ',
    this.privacy = 'Политикой конфиденциальности',
  });

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final String prefix;
  final String terms;
  final String andWord;
  final String privacy;

  @override
  State<LegalNotice> createState() => _LegalNoticeState();
}

class _LegalNoticeState extends State<LegalNotice> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()..onTap = widget.onTerms;
    _privacy = TapGestureRecognizer()..onTap = widget.onPrivacy;
  }

  @override
  void didUpdateWidget(covariant LegalNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    _terms.onTap = widget.onTerms;
    _privacy.onTap = widget.onPrivacy;
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: Color(0xFF5C6166), fontSize: 11, height: 1.35);
    const link = TextStyle(
      color: Color(0xFF1A1C1E),
      fontSize: 11,
      height: 1.35,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: muted,
        children: [
          TextSpan(text: widget.prefix),
          TextSpan(text: widget.terms, style: link, recognizer: _terms),
          TextSpan(text: widget.andWord),
          TextSpan(text: widget.privacy, style: link, recognizer: _privacy),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
