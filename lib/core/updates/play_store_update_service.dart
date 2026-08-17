import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:saloon_booking/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayStoreUpdateCheck {
  const PlayStoreUpdateCheck({
    required this.updateAvailable,
    required this.flexibleAllowed,
    required this.alreadyDownloaded,
  });

  final bool updateAvailable;
  final bool flexibleAllowed;
  final bool alreadyDownloaded;

  static const none = PlayStoreUpdateCheck(
    updateAvailable: false,
    flexibleAllowed: false,
    alreadyDownloaded: false,
  );
}

enum FlexibleUpdateStartResult { downloaded, denied, failed }

abstract class PlayStoreUpdateService {
  Future<PlayStoreUpdateCheck> check();

  Future<FlexibleUpdateStartResult> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();

  Future<bool> openStoreListing();
}

class PlayCoreUpdateService implements PlayStoreUpdateService {
  const PlayCoreUpdateService();

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<PlayStoreUpdateCheck> check() async {
    if (!isSupported) return PlayStoreUpdateCheck.none;
    try {
      final info = await InAppUpdate.checkForUpdate();
      final downloaded = info.installStatus == InstallStatus.downloaded;
      final available =
          info.updateAvailability == UpdateAvailability.updateAvailable ||
          downloaded;
      return PlayStoreUpdateCheck(
        updateAvailable: available,
        flexibleAllowed: info.flexibleUpdateAllowed,
        alreadyDownloaded: downloaded,
      );
    } on MissingPluginException {
      return PlayStoreUpdateCheck.none;
    } on PlatformException {
      return PlayStoreUpdateCheck.none;
    } catch (_) {
      return PlayStoreUpdateCheck.none;
    }
  }

  @override
  Future<FlexibleUpdateStartResult> startFlexibleUpdate() async {
    if (!isSupported) return FlexibleUpdateStartResult.failed;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      return switch (result) {
        AppUpdateResult.success => FlexibleUpdateStartResult.downloaded,
        AppUpdateResult.userDeniedUpdate => FlexibleUpdateStartResult.denied,
        AppUpdateResult.inAppUpdateFailed => FlexibleUpdateStartResult.failed,
      };
    } on MissingPluginException {
      return FlexibleUpdateStartResult.failed;
    } on PlatformException {
      return FlexibleUpdateStartResult.failed;
    } catch (_) {
      return FlexibleUpdateStartResult.failed;
    }
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    if (!isSupported) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } on MissingPluginException {
      // Sideloaded / debug builds have no Play Core.
    } on PlatformException {
      // Ignore; Play will retry on next launch if the download is still pending.
    }
  }

  @override
  Future<bool> openStoreListing() async {
    final market = Uri.parse('market://details?id=${AppConfig.packageName}');
    final https = Uri.parse(
      'https://play.google.com/store/apps/details?id=${AppConfig.packageName}',
    );
    try {
      if (await canLaunchUrl(market)) {
        return launchUrl(market, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    try {
      return await launchUrl(https, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
