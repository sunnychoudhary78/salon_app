import 'package:flutter/material.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/phone_utils.dart';
import 'package:saloon_booking/shared/widgets/gradient_background.dart';
import 'package:saloon_booking/shared/widgets/premium_app_bar.dart';
import 'package:saloon_booking/shared/widgets/premium_button.dart';

enum LegalInfoKind { privacy, terms, refund, help, about }

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key, required this.kind});

  final LegalInfoKind kind;

  static Future<void> open(
    BuildContext context, {
    required LegalInfoKind kind,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalInfoScreen(kind: kind)),
    );
  }

  Future<void> _openContact(BuildContext context) async {
    final launched = await launchEmail(
      AppConfig.supportEmail,
      subject: '${AppConfig.appName} support',
    );
    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email us at ${AppConfig.supportEmail}')),
      );
    }
  }

  String get _title {
    switch (kind) {
      case LegalInfoKind.privacy:
        return 'Privacy Policy';
      case LegalInfoKind.terms:
        return 'Terms & Conditions';
      case LegalInfoKind.refund:
        return 'Cancellation & Refund Policy';
      case LegalInfoKind.help:
        return 'Help & Support';
      case LegalInfoKind.about:
        return 'About CATCHY';
    }
  }

  List<_LegalSection> get _sections {
    switch (kind) {
      case LegalInfoKind.privacy:
        return _privacySections;
      case LegalInfoKind.terms:
        return _termsSections;
      case LegalInfoKind.refund:
        return _refundSections;
      case LegalInfoKind.help:
        return _helpSections;
      case LegalInfoKind.about:
        return _aboutSections;
    }
  }

  bool get _showContactButton =>
      kind == LegalInfoKind.about || kind == LegalInfoKind.help;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sections = _sections;

    return Scaffold(
      appBar: PremiumAppBar(
        title: _title,
        showMenu: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GradientBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            AppDecorations.scrollBottomPadding(context),
          ),
          children: [
            if (kind == LegalInfoKind.about) ...[
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Version ${AppConfig.appVersion}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                AppConfig.companyName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
            ],
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.heading,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      section.body,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_showContactButton) ...[
              const SizedBox(height: 8),
              PremiumButton(
                label: 'Contact us',
                icon: Icons.mail_outline_rounded,
                variant: PremiumButtonVariant.ghost,
                size: PremiumButtonSize.small,
                onPressed: () => _openContact(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

const _privacySections = [
  _LegalSection(
    'Who we are',
    'CATCHY is a salon booking app operated by ${AppConfig.companyName}. '
        'This policy explains what information we collect, how we use it, and the choices you have. '
        'Questions: ${AppConfig.supportEmail}.',
  ),
  _LegalSection(
    'Information we collect',
    'We collect account details such as your name, mobile number, and optional email or profile photo. '
        'When you book, we store salon, service, time, and payment-related records. '
        'If you allow location, we use your coordinates or chosen city to show nearby salons. '
        'The app may also collect device and diagnostic data, including crash reports (Firebase Crashlytics) '
        'and a notification token so we can send booking updates.',
  ),
  _LegalSection(
    'How we use information',
    'We use your data to create and secure your account, show relevant salons, complete bookings, '
        'send reminders and support messages, process payments, and improve CATCHY. '
        'We do not sell your personal information.',
  ),
  _LegalSection(
    'Sharing',
    'Salon owners see the booking details they need to serve you. '
        'Payment partners such as Razorpay receive only what is required to process a transaction. '
        'We may share information with service providers who help us operate the app, '
        'or when required by law.',
  ),
  _LegalSection(
    'Your rights',
    'You can update profile details in the app, change your mobile number after OTP verification, '
        'and request help with access or deletion by emailing ${AppConfig.supportEmail}. '
        'CATCHY does not currently offer in-app account deletion.',
  ),
  _LegalSection(
    'Contact',
    '${AppConfig.companyName}\n'
        '${AppConfig.supportEmail}\n'
        'Registered office: to be updated.',
  ),
];

const _termsSections = [
  _LegalSection(
    'Agreement',
    'By using CATCHY you agree to these terms. CATCHY is provided by ${AppConfig.companyName} '
        'to help customers book salon services and salon owners manage listings, staff, and bookings.',
  ),
  _LegalSection(
    'Accounts',
    'You must provide accurate information and keep your phone number verified. '
        'You are responsible for activity on your account. Do not share OTPs or try to access another user’s account.',
  ),
  _LegalSection(
    'Bookings and payments',
    'Sending a request is not the same as paying. The salon first accepts or rejects your request. '
        'If accepted, you may pay the salon fee online through Razorpay or choose pay at shop. '
        'Urgent (premium) bookings also require a premium fee shown in the app, which must be paid within the time window displayed. '
        'A booking is an agreement between you and the salon. Prices and availability come from the salon. '
        'CATCHY may charge a platform or premium fee where shown before you pay.',
  ),
  _LegalSection(
    'Cancellations and refunds',
    'You may cancel a request that is still pending or accepted. Cancelling in the app does not automatically refund a completed online payment. '
        'See the Cancellation & Refund Policy for details.',
  ),
  _LegalSection(
    'Salon owners',
    'Owners must keep services, hours, and prices accurate, honour accepted bookings, '
        'and comply with applicable laws. We may suspend listings that are misleading or abusive.',
  ),
  _LegalSection(
    'Acceptable use',
    'Do not misuse CATCHY, scrape data, spam, or post unlawful or harmful content. '
        'We may suspend or close accounts that break these terms.',
  ),
  _LegalSection(
    'Liability',
    'CATCHY is a booking platform. Services are provided by independent salons. '
        'To the extent allowed by law, ${AppConfig.companyName} is not liable for salon service quality, '
        'delays, or losses beyond what we can reasonably control.',
  ),
  _LegalSection(
    'Contact',
    'For questions about these terms, email ${AppConfig.supportEmail}.',
  ),
];

const _refundSections = [
  _LegalSection(
    'When you can cancel',
    'Customers can cancel a booking in CATCHY while it is pending (waiting for the salon) or accepted. '
        'Completed, rejected, or already-cancelled visits cannot be cancelled again.',
  ),
  _LegalSection(
    'What cancel does',
    'Cancelling updates the booking status in CATCHY and notifies the salon. '
        'It does not automatically refund money that was already paid online. '
        'CATCHY does not currently process automatic Razorpay refunds in the app.',
  ),
  _LegalSection(
    'Before the salon accepts',
    'A normal request is sent first. Payment is not taken at that step. '
        'If you cancel while the request is still pending, there is usually nothing to refund.',
  ),
  _LegalSection(
    'After the salon accepts',
    'You may pay the salon fee online (Razorpay) or choose pay at shop. '
        'Pay at shop is settled at the salon, so CATCHY has no in-app refund for that amount. '
        'If you already paid online and then cancel, email ${AppConfig.supportEmail} for a case-by-case review. '
        'Approved refunds, if any, are handled manually and are not instant in the app.',
  ),
  _LegalSection(
    'Urgent (premium) bookings',
    'Urgent bookings require a premium fee after the salon accepts. '
        'The payment window is shown in the app (typically 15 minutes). '
        'If the premium fee is not paid in time, CATCHY cancels the booking. '
        'An unpaid or expired payment is not a refund — no charge was completed.',
  ),
  _LegalSection(
    'Salon rejection',
    'The salon may reject a pending request. That usually happens before payment. '
        'If you believe you were charged in error, contact ${AppConfig.supportEmail}.',
  ),
  _LegalSection(
    'How to request help',
    'Email ${AppConfig.supportEmail} with your booking details. '
        'We will review the payment status and respond as soon as we can.',
  ),
];

const _helpSections = [
  _LegalSection(
    'Booking a salon',
    'Open a salon, choose services and a time, then send a request. '
        'The salon accepts or rejects it. After accept, pay online or choose pay at shop from Bookings.',
  ),
  _LegalSection(
    'Urgent bookings',
    'If a slot is already taken, CATCHY may offer an urgent booking for a premium fee. '
        'Pay that fee within the countdown shown on the booking, or the visit is cancelled.',
  ),
  _LegalSection(
    'Cancelling',
    'Open Bookings and tap Cancel while the visit is still pending or accepted. '
        'Cancelling does not automatically refund an online payment. See Cancellation & Refund Policy.',
  ),
  _LegalSection(
    'Payments',
    'Online payments use Razorpay. Pay at shop is confirmed by the salon at the visit. '
        'If a payment succeeds in Razorpay but the app still looks unpaid, wait a moment and pull to refresh Bookings.',
  ),
  _LegalSection(
    'Account',
    'Update your name, photo, or email in Profile. Changing your mobile number requires OTP verification.',
  ),
  _LegalSection(
    'Contact',
    '${AppConfig.companyName}\n'
        '${AppConfig.supportEmail}\n'
        'Support phone: to be updated.\n'
        'Registered office: to be updated.',
  ),
];

const _aboutSections = [
  _LegalSection(
    'What CATCHY is',
    'CATCHY helps you discover nearby salons, book services, and manage appointments. '
        'Salon owners can list services, staff, and hours from the same app.',
  ),
  _LegalSection(
    'Operator',
    'CATCHY is operated by ${AppConfig.companyName}.\n'
        'Registered office: to be updated.',
  ),
  _LegalSection(
    'Support',
    'Need help with an account, booking, or listing? Email ${AppConfig.supportEmail}.',
  ),
];
