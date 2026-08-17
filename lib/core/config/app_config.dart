class AppConfig {
  AppConfig._();

  static const String appName = 'CATCHY';
  static const String packageName = 'com.imt.catchy';
  static const String appIconAsset = 'assets/icon/app_icon.png';
  static const String appLogoAsset = 'assets/icon/app_logo.png';

  /// Change this to your PC WiFi IP (run `ipconfig`).
  /// Android emulator: use `http://10.0.2.2:3011/api`
  static const String baseUrl =
      'https://salon-api.immortaltechnovation.com/api';
  // 'https://uat-salon-api.immortaltechnovation.com/api';

  static const String authPrefix = '/auth';
  static const String appPrefix = '/app';

  static const String appVersion = '1.0.0';
  static const String supportEmail = 'sales@immortaltechnovation.com';
  static const String companyName = 'Immortal Technovation';
}
