/// Adjusts a tunnel config in memory before it is handed to AmneziaWG.
/// The original text is not logged.
String applyTunnelOptions(
  String conf, {
  required bool netShield,
  required bool accelerator,
  required Set<String> excludedApps,
}) {
  var text = conf.replaceAll('\r\n', '\n');
  if (netShield) {
    text = _upsertInterface(text, 'DNS', '94.140.14.14, 94.140.15.15');
    text = _upsertInterface(text, 'DomainBlockingEnabled', 'true');
  } else {
    text = _removeInterface(text, 'DomainBlockingEnabled');
    if (accelerator) {
      text = _upsertInterface(text, 'DNS', '1.1.1.1, 1.0.0.1');
    }
  }
  final apps = excludedApps.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()..sort();
  if (apps.isEmpty) {
    text = _removeInterface(text, 'ExcludedApplications');
  } else {
    text = _upsertInterface(text, 'ExcludedApplications', apps.join(', '));
  }
  return text;
}

String _upsertInterface(String conf, String key, String value) {
  final lines = conf.split('\n');
  final out = <String>[];
  var inInterface = false;
  var wrote = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[')) {
      if (inInterface && !wrote) {
        out.add('$key = $value');
        wrote = true;
      }
      inInterface = trimmed.toLowerCase() == '[interface]';
      out.add(line);
      continue;
    }
    if (inInterface && trimmed.toLowerCase().startsWith(key.toLowerCase())) {
      if (!wrote) out.add('$key = $value');
      wrote = true;
      continue;
    }
    out.add(line);
  }
  if (!wrote) out.add('$key = $value');
  return out.join('\n');
}

String _removeInterface(String conf, String key) {
  final lines = conf.split('\n');
  final out = <String>[];
  var inInterface = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('[')) {
      inInterface = trimmed.toLowerCase() == '[interface]';
      out.add(line);
      continue;
    }
    if (inInterface && trimmed.toLowerCase().startsWith(key.toLowerCase())) continue;
    out.add(line);
  }
  return out.join('\n');
}
