import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: digits);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}

Future<bool> launchEmail(
  String email, {
  String? subject,
}) async {
  if (email.trim().isEmpty) return false;

  final query = subject != null && subject.isNotEmpty
      ? 'subject=${Uri.encodeComponent(subject)}'
      : null;
  final uri = Uri(scheme: 'mailto', path: email.trim(), query: query);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}

Future<bool> launchWebUrl(String url) async {
  if (url.trim().isEmpty) return false;

  final uri = Uri.parse(url.trim());
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
