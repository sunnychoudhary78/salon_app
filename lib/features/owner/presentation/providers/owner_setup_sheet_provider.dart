import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the owner setup (payout / profile) bottom sheet has already been
/// presented this app session. Resets when the process restarts.
class OwnerSetupSheetShown extends Notifier<bool> {
  @override
  bool build() => false;

  void markShown() => state = true;
}

final ownerSetupSheetShownProvider =
    NotifierProvider<OwnerSetupSheetShown, bool>(OwnerSetupSheetShown.new);
