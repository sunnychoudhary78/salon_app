class AppConfig {
  AppConfig._();

  static const String appName = 'CATCHY';
  static const String packageName = 'com.imt.catchy';
  static const String appIconAsset = 'assets/icon/app_icon.png';
  static const String appLogoAsset = 'assets/icon/app_logo.png';

  // Environment Base URLs:
  // Real Physical Phone (Your current PC Wi-Fi IP):
  static const String deviceLocalBaseUrl = 'http://10.121.94.42:3011/api';
  // Android Emulator (10.0.2.2 maps to host PC localhost):
  static const String emulatorBaseUrl = 'http://10.121.94.42:3011/api';
  // iOS Simulator / Web / Desktop / USB reverse localhost:
  static const String localhostBaseUrl = 'http://localhost:3011/api';
  // UAT Server:
  static const String uatBaseUrl = 'https://uat-salon-api.immortaltechnovation.com/api';
  // Production Server:
  static const String prodBaseUrl = 'https://salon-api.immortaltechnovation.com/api';

  /// Active Base URL:
  // static const String baseUrl = deviceLocalBaseUrl; // <-- Real Phone Wi-Fi ke liye
  // static const String baseUrl = emulatorBaseUrl; // <-- Android Emulator ke liye
  // static const String baseUrl = localhostBaseUrl; // <-- iOS/Web/USB adb reverse ke liye
  static const String baseUrl = uatBaseUrl; // <-- UAT
  // static const String baseUrl = prodBaseUrl;

  static const String authPrefix = '/auth';
  static const String appPrefix = '/app';

  static const String appVersion = '1.0.0';
  static const String supportEmail = 'sales@immortaltechnovation.com';
  static const String companyName = 'Immortal Technovation';
}
