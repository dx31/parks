import 'package:parkimetro_core/parkimetro_core.dart';

class FakeParkimetroApi extends ParkimetroApi {
  FakeParkimetroApi() : super(baseUrl: 'http://fake.local');

  Object? error;
  SpaceStatus? lastFilter;

  final spaces = [
    ParkingSpace(
      id: 's1',
      code: 'A-01',
      zoneId: 'z1',
      zoneName: 'Centro Histórico',
      latitude: 19.4,
      longitude: -99.1,
      hourlyRate: 18,
      status: SpaceStatus.free,
      notes: 'cerca del parque',
      updatedAt: DateTime.utc(2026, 9, 13),
    ),
    ParkingSpace(
      id: 's2',
      code: 'A-02',
      zoneId: 'z1',
      zoneName: 'Centro Histórico',
      latitude: 19.41,
      longitude: -99.11,
      hourlyRate: 18,
      status: SpaceStatus.occupied,
      updatedAt: DateTime.utc(2026, 9, 13),
    ),
  ];

  @override
  Future<List<ParkingSpace>> listSpaces({
    String? zoneId,
    SpaceStatus? status,
  }) async {
    lastFilter = status;
    if (error != null) {
      throw error!;
    }
    return spaces
        .where((space) => status == null || space.status == status)
        .toList();
  }
}
