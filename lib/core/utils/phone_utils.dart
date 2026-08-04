import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: digits);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> launchEmail(String email, {String? subject}) async {
  if (email.trim().isEmpty) return false;

  final query = subject != null && subject.isNotEmpty
      ? 'subject=${Uri.encodeComponent(subject)}'
      : null;
  final uri = Uri(scheme: 'mailto', path: email.trim(), query: query);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> launchWebUrl(String url) async {
  if (url.trim().isEmpty) return false;

  final uri = Uri.parse(url.trim());
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
