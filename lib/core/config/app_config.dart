class AppConfig {
  AppConfig._();

  static const String appName = 'CATCHY';
  static const String packageName = 'com.imt.catchy';
  static const String appIconAsset = 'assets/icon/app_icon.png';
  static const String appLogoAsset = 'assets/icon/app_logo.png';

  /// Change this to your PC WiFi IP (run `ipconfig`).
  /// Android emulator: use `http://10.0.2.2:3011/api`
  static const String baseUrl =
      // 'https://salon-api.immortaltechnovation.com/api';
      'http://192.168.1.26:3011/api';

  static const String authPrefix = '/auth';
  static const String appPrefix = '/app';
}
