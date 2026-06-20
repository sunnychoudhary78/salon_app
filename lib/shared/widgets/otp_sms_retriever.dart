import 'package:pinput/pinput.dart';
import 'package:saloon_booking/features/auth/presentation/utils/otp_sms_listener.dart';

/// Pinput SMS retriever backed by the shared [OtpSmsListener].
class OtpSmsRetriever implements SmsRetriever {
  @override
  bool get listenForMultipleSms => true;

  @override
  Future<String?> getSmsCode() {
    return OtpSmsListener.instance.waitForCode();
  }

  @override
  Future<void> dispose() async {
    // Session lifecycle is managed by OtpSmsListener.stopSession().
  }
}
