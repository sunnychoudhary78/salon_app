import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented when a 401 response clears the stored token.
class UnauthorizedTrigger extends Notifier<int> {
  @override
  int build() {
    ref.keepAlive();
    return 0;
  }

  void trigger() => state++;
}

final unauthorizedTriggerProvider =
    NotifierProvider<UnauthorizedTrigger, int>(UnauthorizedTrigger.new);
