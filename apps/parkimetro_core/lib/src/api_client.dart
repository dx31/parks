import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ParkimetroApi {
  ParkimetroApi({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? defaultBaseUrl(),
      _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  String? token;

  static String defaultBaseUrl() => ApiConfig.currentBaseUrl();

  Future<AuthSession> login(String username, String pin) async {
    final json = await _send(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'pin': pin},
    ) as Map<String, dynamic>;
    final session = AuthSession.fromJson(json);
    token = session.token;
    return session;
  }

  Future<List<Zone>> listZones() async {
    final json = await _send('GET', '/api/zones');
    return (json as List<dynamic>)
        .map((item) => Zone.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Zone> createZone({
    required String name,
    required String city,
    String? videoUrl,
  }) async {
    final json = await _send(
      'POST',
      '/api/zones',
      body: {'name': name, 'city': city, 'videoUrl': videoUrl},
    ) as Map<String, dynamic>;
    return Zone.fromJson(json);
  }

  Future<Zone> updateZone({
    required String id,
    required String name,
    required String city,
    String? videoUrl,
  }) async {
    final json = await _send(
      'PUT',
      '/api/zones/$id',
      body: {'name': name, 'city': city, 'videoUrl': videoUrl},
    ) as Map<String, dynamic>;
    return Zone.fromJson(json);
  }

  Future<List<ParkingSpace>> listSpaces({
    String? zoneId,
    SpaceStatus? status,
  }) async {
    final query = <String, String>{
      'zoneId': ?zoneId,
      'status': ?switch (status) {
        null => null,
        final value => spaceStatusToApi(value),
      },
    };
    final json = await _send('GET', '/api/spaces', query: query);
    return (json as List<dynamic>)
        .map((item) => ParkingSpace.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ParkingSpace> getSpace(String id) async {
    final json = await _send('GET', '/api/spaces/$id') as Map<String, dynamic>;
    return ParkingSpace.fromJson(json);
  }

  Future<ParkingSpace> createSpace({
    required String code,
    required String zoneId,
    required double latitude,
    required double longitude,
    required double hourlyRate,
    String? notes,
  }) async {
    final json = await _send(
      'POST',
      '/api/spaces',
      body: {
        'code': code,
        'zoneId': zoneId,
        'latitude': latitude,
        'longitude': longitude,
        'hourlyRate': hourlyRate,
        'notes': notes,
      },
    ) as Map<String, dynamic>;
    return ParkingSpace.fromJson(json);
  }

  Future<ParkingSpace> changeStatus(String id, SpaceStatus status) async {
    final json = await _send(
      'PATCH',
      '/api/spaces/$id/status',
      body: {'status': spaceStatusToApi(status)},
    ) as Map<String, dynamic>;
    return ParkingSpace.fromJson(json);
  }

  Future<ParkingSpace> reserveSpace(
    String id, {
    required String dni,
    String? clientName,
    required DateTime startsAt,
    required DateTime limitUntil,
  }) async {
    final json = await _send(
      'POST',
      '/api/spaces/$id/reserve',
      body: {
        'dni': dni,
        if (clientName != null && clientName.trim().isNotEmpty)
          'clientName': clientName.trim(),
        'startsAt': startsAt.toUtc().toIso8601String(),
        'limitUntil': limitUntil.toUtc().toIso8601String(),
      },
    ) as Map<String, dynamic>;
    return ParkingSpace.fromJson(json);
  }

  Future<ClientIdentity> lookupClient(String dni) async {
    final json =
        await _send('GET', '/api/clients/$dni') as Map<String, dynamic>;
    return ClientIdentity.fromJson(json);
  }

  Future<ParkingSession> startSession(
    String spaceId, {
    required String dni,
    String? clientName,
    String? licensePlate,
    required DateTime limitUntil,
  }) async {
    final plate = licensePlate?.trim();
    final name = clientName?.trim();
    final json = await _send(
      'POST',
      '/api/sessions',
      body: {
        'spaceId': spaceId,
        'dni': dni,
        if (name != null && name.isNotEmpty) 'clientName': name,
        if (plate != null && plate.isNotEmpty) 'licensePlate': plate,
        'limitUntil': limitUntil.toUtc().toIso8601String(),
      },
    ) as Map<String, dynamic>;
    return ParkingSession.fromJson(json);
  }

  Future<ParkingSession> endSession(String sessionId) async {
    final json = await _send(
      'POST',
      '/api/sessions/$sessionId/end',
    ) as Map<String, dynamic>;
    return ParkingSession.fromJson(json);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    late http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request);
    } catch (error) {
      throw ApiException('No se pudo conectar con la API ($baseUrl).');
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      throw ApiException(_readError(response), statusCode: response.statusCode);
    }
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  String _readError(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic> && json['message'] is String) {
        return json['message'] as String;
      }
    } catch (_) {
      // Keep the generic fallback below.
    }
    return 'Error ${response.statusCode} al llamar a la API.';
  }
}
