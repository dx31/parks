import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

void main() {
  test('development URL uses Android emulator loopback', () {
    expect(
      ApiConfig.developmentBaseUrl(
        isWeb: false,
        platform: TargetPlatform.android,
      ),
      'http://10.0.2.2:5280',
    );
  });

  test('development URL uses localhost on web and desktop', () {
    expect(ApiConfig.developmentBaseUrl(isWeb: true), 'http://localhost:5280');
    expect(
      ApiConfig.developmentBaseUrl(
        isWeb: false,
        platform: TargetPlatform.windows,
      ),
      'http://localhost:5280',
    );
  });

  test('production URL is not hardcoded', () {
    expect(ApiConfig.productionBaseUrl, isEmpty);
  });

  test('debug builds use the development URL', () {
    expect(ApiConfig.isProduction, isFalse);
    expect(ApiConfig.currentBaseUrl(), ApiConfig.developmentBaseUrl());
    expect(ParkimetroApi.defaultBaseUrl(), ApiConfig.currentBaseUrl());
  });

  test('normalize strips a trailing slash', () {
    expect(
      ApiConfig.normalize('https://api.example.com/'),
      'https://api.example.com',
    );
    expect(
      ApiConfig.normalize('http://localhost:5280'),
      'http://localhost:5280',
    );
  });
}
