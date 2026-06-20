import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/features/auth/presentation/providers/auth_provider.dart';
import 'package:saloon_booking/features/owner/data/services/owner_service.dart';

class HasApprovedSalons extends Notifier<bool> {
  @override
  bool build() => false;

  Future<bool> refresh() async {
    final auth = ref.read(authProvider).value;
    if (auth?.salonOwner == null) {
      state = false;
      return false;
    }

    try {
      final salons = await ref.read(ownerServiceProvider).getOwnerSalons();
      final approved = salons.isNotEmpty;
      state = approved;
      if (approved) {
        ref.invalidate(ownerSalonsProvider);
      }
      return approved;
    } catch (_) {
      state = false;
      return false;
    }
  }

  void reset() => state = false;
}

final hasApprovedSalonsProvider =
    NotifierProvider<HasApprovedSalons, bool>(HasApprovedSalons.new);
