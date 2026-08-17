const updatePromptSnoozeKey = 'update_prompt_snoozed_at';
const updatePromptSnoozeDuration = Duration(hours: 24);

bool isUpdateSnoozed(int? snoozedAtMs, DateTime now) {
  if (snoozedAtMs == null) return false;
  final snoozedAt = DateTime.fromMillisecondsSinceEpoch(snoozedAtMs);
  return now.difference(snoozedAt) < updatePromptSnoozeDuration;
}

bool shouldPromptForAvailableUpdate({
  required bool snoozed,
  required bool updateAvailable,
}) {
  return updateAvailable && !snoozed;
}
