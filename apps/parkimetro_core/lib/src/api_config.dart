import 'package:flutter/foundation.dart';

/// URLs de la API para desarrollo y producción.
///
/// Por defecto:
/// - `flutter run` / debug → [developmentBaseUrl]
/// - `flutter run --release` / APK de release → [productionBaseUrl]
///
/// Sobrescribe al compilar:
/// - `--dart-define=API_ENV=prod` o `dev`
/// - `--dart-define=API_DEV_URL=http://192.168.1.10:5280`
/// - `--dart-define=API_PROD_URL=https://tu-api.com`
/// - `--dart-define=API_BASE_URL=https://cualquier-url` (fuerza esa URL)
class ApiConfig {
  ApiConfig._();

  /// URL de producción. No la dejes en el código: pásala al compilar.
  static const productionBaseUrl = String.fromEnvironment('API_PROD_URL');

  static const _forcedUrl = String.fromEnvironment('API_BASE_URL');
  static const _forcedEnv = String.fromEnvironment('API_ENV');
  static const _developmentOverride = String.fromEnvironment('API_DEV_URL');

  static bool get isProduction {
    if (_forcedEnv == 'prod' || _forcedEnv == 'production') {
      return true;
    }
    if (_forcedEnv == 'dev' || _forcedEnv == 'development') {
      return false;
    }
    return kReleaseMode;
  }

  static String developmentBaseUrl({
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    if (_developmentOverride.isNotEmpty) {
      return normalize(_developmentOverride);
    }
    if (isWeb) {
      return 'http://localhost:5280';
    }
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:5280',
      _ => 'http://localhost:5280',
    };
  }

  static String currentBaseUrl() {
    if (_forcedUrl.isNotEmpty) {
      return normalize(_forcedUrl);
    }
    if (!isProduction) {
      return developmentBaseUrl();
    }
    if (productionBaseUrl.isEmpty) {
      throw StateError(
        'Falta API_PROD_URL. Compila con --dart-define-from-file=api_env.json',
      );
    }
    return normalize(productionBaseUrl);
  }

  static String normalize(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }
}
