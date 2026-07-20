import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fired when a 401 clears the session so the UI can show feedback before redirect.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state++;
}

final sessionExpiredProvider =
    NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);
