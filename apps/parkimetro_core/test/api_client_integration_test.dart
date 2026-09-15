import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:parkimetro_core/parkimetro_core.dart';

void main() {
  late HttpServer server;
  late ParkimetroApi api;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      final body = await utf8.decoder.bind(request).join();
      request.response.headers.contentType = ContentType.json;

      if (request.method == 'POST' && path == '/api/auth/login') {
        final payload = jsonDecode(body) as Map<String, dynamic>;
        if (payload['username'] == 'ana' && payload['pin'] == '1234') {
          request.response.write(
            jsonEncode({
              'token': 'live-token',
              'operator': {'id': 'o1', 'name': 'Ana López', 'username': 'ana'},
            }),
          );
        } else {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write(
            jsonEncode({'message': 'Usuario o PIN incorrectos.'}),
          );
        }
      } else if (request.method == 'GET' && path == '/api/zones') {
        final auth = request.headers.value(HttpHeaders.authorizationHeader);
        expect(auth, 'Bearer live-token');
        request.response.write(
          jsonEncode([
            {
              'id': 'z1',
              'name': 'Centro Histórico',
              'city': 'Ciudad',
              'spacesCount': 2,
              'freeCount': 1,
            },
          ]),
        );
      } else if (request.method == 'POST' && path == '/api/spaces') {
        request.response.statusCode = HttpStatus.created;
        request.response.write(
          jsonEncode({
            'id': 's-new',
            'code': 'A-20',
            'zoneId': 'z1',
            'zoneName': 'Centro Histórico',
            'latitude': 19.4,
            'longitude': -99.1,
            'hourlyRate': 18,
            'status': 'free',
            'updatedAt': DateTime.utc(2026, 9, 13).toIso8601String(),
          }),
        );
      } else if (request.method == 'POST' && path == '/api/sessions/p1/end') {
        request.response.write(
          jsonEncode({
            'id': 'p1',
            'spaceId': 's1',
            'spaceCode': 'A-01',
            'operatorId': 'o1',
            'operatorName': 'Ana López',
            'startedAt': DateTime.utc(2026, 9, 13, 12).toIso8601String(),
            'endedAt': DateTime.utc(2026, 9, 13, 13).toIso8601String(),
            'isActive': false,
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({'message': 'no encontrado'}));
      }

      await request.response.close();
    });

    api = ParkimetroApi(
      baseUrl: 'http://${server.address.address}:${server.port}',
      httpClient: http.Client(),
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('talks to a live HTTP server', () async {
    final session = await api.login('ana', '1234');
    expect(session.operatorAccount.name, 'Ana López');

    final zones = await api.listZones();
    expect(zones.single.name, 'Centro Histórico');

    final space = await api.createSpace(
      code: 'A-20',
      zoneId: 'z1',
      latitude: 19.4,
      longitude: -99.1,
      hourlyRate: 18,
    );
    expect(space.id, 's-new');

    final ended = await api.endSession('p1');
    expect(ended.isActive, isFalse);
  });
}
