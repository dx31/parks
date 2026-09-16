import 'package:flutter_test/flutter_test.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

void main() {
  group('space status', () {
    test('maps unknown values to free', () {
      expect(spaceStatusFromApi('free'), SpaceStatus.free);
      expect(spaceStatusFromApi('occupied'), SpaceStatus.occupied);
      expect(spaceStatusFromApi('reserved'), SpaceStatus.reserved);
      expect(spaceStatusFromApi('outOfService'), SpaceStatus.outOfService);
      expect(spaceStatusFromApi('otro'), SpaceStatus.free);
    });

    test('serializes and labels every status', () {
      expect(spaceStatusToApi(SpaceStatus.free), 'free');
      expect(spaceStatusToApi(SpaceStatus.occupied), 'occupied');
      expect(spaceStatusToApi(SpaceStatus.reserved), 'reserved');
      expect(spaceStatusToApi(SpaceStatus.outOfService), 'outOfService');
      expect(spaceStatusLabel(SpaceStatus.free), 'Libre');
      expect(spaceStatusLabel(SpaceStatus.occupied), 'Ocupado');
      expect(spaceStatusLabel(SpaceStatus.reserved), 'Reservado');
      expect(spaceStatusLabel(SpaceStatus.outOfService), 'Fuera de servicio');
    });
  });

  test('parses API models', () {
    final zone = Zone.fromJson({
      'id': 'z1',
      'name': 'Centro',
      'city': 'Ciudad',
      'spacesCount': 3,
      'freeCount': 1,
    });
    expect(zone.freeCount, 1);

    final space = ParkingSpace.fromJson({
      'id': 's1',
      'code': 'A-01',
      'zoneId': 'z1',
      'zoneName': 'Centro',
      'latitude': 19,
      'longitude': -99,
      'hourlyRate': 2,
      'status': 'free',
      'notes': 'cerca',
      'updatedAt': '2026-09-13T12:00:00Z',
      'activeSessionId': null,
    });
    expect(space.isFree, isTrue);
    expect(space.hourlyRate, 2);
    expect(space.occupiedSince, isNull);

    final session = AuthSession.fromJson({
      'token': 'abc',
      'operator': {'id': 'o1', 'name': 'Ana', 'username': 'ana'},
    });
    expect(session.operatorAccount.username, 'ana');

    final parkingSession = ParkingSession.fromJson({
      'id': 'p1',
      'spaceId': 's1',
      'spaceCode': 'A-01',
      'operatorId': 'o1',
      'operatorName': 'Ana',
      'licensePlate': 'ABC123',
      'startedAt': '2026-09-13T12:00:00Z',
      'endedAt': '2026-09-13T13:00:00Z',
      'isActive': false,
      'billedHours': 1,
      'amount': 2,
    });
    expect(parkingSession.endedAt, isNotNull);
    expect(parkingSession.isActive, isFalse);
    expect(parkingSession.billedHours, 1);
  });

  test('bills by hour or fraction at two soles', () {
    final started = DateTime.utc(2026, 9, 15, 12);
    expect(hoursOrFraction(started, started), 1);
    expect(
      hoursOrFraction(started, started.add(const Duration(minutes: 1))),
      1,
    );
    expect(hoursOrFraction(started, started.add(const Duration(hours: 1))), 1);
    expect(
      hoursOrFraction(
        started,
        started.add(const Duration(hours: 1, seconds: 1)),
      ),
      2,
    );
    expect(
      billedAmount(started, started.add(const Duration(minutes: 10)), 2),
      2,
    );
    expect(formatSoles(2), 'S/ 2.00');
    expect(rateLabel(2), 'S/ 2.00 / hora o fracción');
  });

  test('ApiException uses the message as string', () {
    expect(ApiException('falló', statusCode: 500).toString(), 'falló');
  });
}
