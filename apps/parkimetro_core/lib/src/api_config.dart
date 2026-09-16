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

  /// URL pública de la API. `--dart-define=API_PROD_URL=...` la puede sustituir.
  static const publicApiUrl = 'https://apipark.facvel.com';

  static const productionBaseUrl = String.fromEnvironment(
    'API_PROD_URL',
    defaultValue: publicApiUrl,
  );

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
    final production = productionBaseUrl.trim();
    if (production.isEmpty) {
      return normalize(publicApiUrl);
    }
    return normalize(production);
  }

  static String normalize(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
