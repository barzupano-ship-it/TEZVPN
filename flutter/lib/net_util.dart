String? sslipAddress(String host) {
  final match = RegExp(
    r'^(\d{1,3})-(\d{1,3})-(\d{1,3})-(\d{1,3})\.sslip\.io$',
  ).firstMatch(host.toLowerCase());
  if (match == null) return null;
  final parts = <int>[];
  for (var i = 1; i <= 4; i++) {
    final n = int.parse(match.group(i)!);
    if (n > 255) return null;
    parts.add(n);
  }
  return parts.join('.');
}

String? shopIpv4FromUrl(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  return sslipAddress(host);
}

String friendlyNetError(Object error, {required bool english}) {
  final raw = error.toString();
  if (raw.contains('SocketException') ||
      raw.contains('ClientException') ||
      raw.contains('HandshakeException') ||
      raw.contains('Failed host lookup') ||
      raw.contains('10057') ||
      raw.contains('Connection closed') ||
      raw.contains('Connection reset')) {
    return english
        ? 'No connection to the server. Check the internet and try again.'
        : 'Нет связи с сервером. Проверьте интернет и отправьте ещё раз.';
  }
  return raw.replaceFirst('Exception: ', '');
}
