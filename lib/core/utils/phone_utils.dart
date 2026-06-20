import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: digits);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri);
}
