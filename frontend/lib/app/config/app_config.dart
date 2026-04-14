import 'package:package_info_plus/package_info_plus.dart';
import 'package:togli_app/app/config/runtime_config.dart';

class AppConfig {
  static late String version;

  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
  }
}

class ApiConfig {
  static String get baseUrl => RuntimeConfig.apiBaseUrl;
}