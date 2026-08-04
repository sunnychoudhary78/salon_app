import 'package:saloon_booking/features/owner/data/models/owner_model.dart';

enum OwnerPayoutStatus { missing, pending, rejected, verified }

OwnerPayoutStatus resolveOwnerPayoutStatus(OwnerPayoutAccountModel? account) {
  if (account == null) return OwnerPayoutStatus.missing;
  final status = account.verificationStatus?.toUpperCase();
  if (status == 'REJECTED') return OwnerPayoutStatus.rejected;
  if (status == 'PENDING') return OwnerPayoutStatus.pending;
  return OwnerPayoutStatus.verified;
}

bool ownerPayoutNeedsAction(OwnerPayoutAccountModel? account) {
  final status = resolveOwnerPayoutStatus(account);
  return status == OwnerPayoutStatus.missing ||
      status == OwnerPayoutStatus.rejected ||
      status == OwnerPayoutStatus.pending;
}

String ownerPayoutStatusMessage(OwnerPayoutStatus status) {
  return switch (status) {
    OwnerPayoutStatus.missing => 'Add bank details to receive settlements',
    OwnerPayoutStatus.pending => 'Payout account is pending verification',
    OwnerPayoutStatus.rejected =>
      'Payout account verification was rejected — please update your details',
    OwnerPayoutStatus.verified => 'Payout account connected',
  };
}

String? buildOwnerSetupHint({
  required OwnerPayoutAccountModel? payoutAccount,
  required int profilePercent,
}) {
  final parts = <String>[];
  final payoutStatus = resolveOwnerPayoutStatus(payoutAccount);
  switch (payoutStatus) {
    case OwnerPayoutStatus.missing:
      parts.add('bank details');
    case OwnerPayoutStatus.rejected:
      parts.add('update bank details');
    case OwnerPayoutStatus.pending:
      parts.add('bank verification pending');
    case OwnerPayoutStatus.verified:
      break;
  }
  if (profilePercent < 100) {
    parts.add('profile $profilePercent%');
  }
  if (parts.isEmpty) return null;
  return 'Complete setup: ${parts.join(' · ')}';
}
