import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

void main() {
  test('login stores the bearer token', () async {
    final api = ParkimetroApi(
      baseUrl: 'http://api.test',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');
        return http.Response(
          jsonEncode({
            'token': 'tok-1',
            'operator': {'id': 'o1', 'name': 'Ana', 'username': 'ana'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await api.login('ana', '1234');
    expect(session.token, 'tok-1');
    expect(api.token, 'tok-1');
  });

  test('listSpaces sends filters and parses results', () async {
    final api = ParkimetroApi(
      baseUrl: 'http://api.test',
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['zoneId'], 'z1');
        expect(request.url.queryParameters['status'], 'free');
        return http.Response(
          jsonEncode([
            {
              'id': 's1',
              'code': 'A-01',
              'zoneId': 'z1',
              'zoneName': 'Centro',
              'latitude': 19.4,
              'longitude': -99.1,
              'hourlyRate': 18,
              'status': 'free',
              'updatedAt': '2026-09-13T12:00:00Z',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final spaces = await api.listSpaces(zoneId: 'z1', status: SpaceStatus.free);
    expect(spaces, hasLength(1));
    expect(spaces.first.code, 'A-01');
  });

  test('maps API errors and connection failures', () async {
    final failing = ParkimetroApi(
      baseUrl: 'http://api.test',
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'La zona no existe.'}),
          400,
        );
      }),
    );

    expect(
      () => failing.createZone(name: 'X', city: 'Y'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'La zona no existe.',
        ),
      ),
    );

    final offline = ParkimetroApi(
      baseUrl: 'http://api.test',
      httpClient: MockClient((request) async => throw Exception('socket')),
    );
    expect(
      () => offline.listZones(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('No se pudo conectar'),
        ),
      ),
    );
  });

  test('sends authorization when changing status and sessions', () async {
    String? authorization;
    final api = ParkimetroApi(
      baseUrl: 'http://api.test',
      httpClient: MockClient((request) async {
        authorization = request.headers['Authorization'];
        if (request.url.path == '/api/spaces/s1/status') {
          return http.Response(
            jsonEncode({
              'id': 's1',
              'code': 'A-01',
              'zoneId': 'z1',
              'zoneName': 'Centro',
              'latitude': 1,
              'longitude': 1,
              'hourlyRate': 10,
              'status': 'reserved',
              'updatedAt': '2026-09-13T12:00:00Z',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'id': 'p1',
            'spaceId': 's1',
            'spaceCode': 'A-01',
            'operatorId': 'o1',
            'operatorName': 'Ana',
            'startedAt': '2026-09-13T12:00:00Z',
            'isActive': true,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..token = 'secret';

    await api.changeStatus('s1', SpaceStatus.reserved);
    expect(authorization, 'Bearer secret');
    final session = await api.startSession('s1', licensePlate: 'ABC123');
    expect(session.isActive, isTrue);
  });

  test('parses zone video url and client identity', () async {
    final api = ParkimetroApi(
      baseUrl: 'http://api.test',
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/clients/12345678') {
          return http.Response(
            jsonEncode({
              'dni': '12345678',
              'ruc': '10123456780',
              'name': 'PEREZ PEREZ JUAN',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/spaces/s1/reserve') {
          return http.Response(
            jsonEncode({
              'id': 's1',
              'code': 'A-01',
              'zoneId': 'z1',
              'zoneName': 'Centro',
              'latitude': 1,
              'longitude': 1,
              'hourlyRate': 10,
              'status': 'reserved',
              'updatedAt': '2026-09-13T12:00:00Z',
              'clientDni': '12345678',
              'clientRuc': '10123456780',
              'clientName': 'PEREZ PEREZ JUAN',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'id': 'z1',
            'name': 'Centro',
            'city': 'Lima',
            'spacesCount': 0,
            'freeCount': 0,
            'videoUrl': '/api/cameras/demo',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..token = 'secret';

    final zone = await api.createZone(
      name: 'Centro',
      city: 'Lima',
      videoUrl: '/api/cameras/demo',
    );
    expect(
      zone.resolvedVideoUrl(api.baseUrl),
      'http://api.test/api/cameras/demo',
    );
    final client = await api.lookupClient('12345678');
    expect(client.name, 'PEREZ PEREZ JUAN');
    final reserved = await api.reserveSpace('s1', dni: '12345678');
    expect(reserved.clientName, 'PEREZ PEREZ JUAN');
  });

  test('defaultBaseUrl follows the current API environment', () {
    expect(ParkimetroApi.defaultBaseUrl(), ApiConfig.currentBaseUrl());
  });
}
