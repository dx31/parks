import 'package:parkimetro_core/parkimetro_core.dart';

class FakeParkimetroApi extends ParkimetroApi {
  FakeParkimetroApi() : super(baseUrl: 'http://fake.local');

  bool failLogin = false;
  String? createdZoneName;
  String? occupiedSpaceId;
  String? lastStatusChange;
  String? reservedDni;
  String? lookedUpDni;

  final zones = [
    const Zone(
      id: 'z1',
      name: 'Centro Histórico',
      city: 'Ciudad',
      spacesCount: 2,
      freeCount: 1,
    ),
  ];

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
      updatedAt: DateTime.utc(2026, 9, 13),
    ),
  ];

  @override
  Future<AuthSession> login(String username, String pin) async {
    if (failLogin) {
      throw ApiException('Usuario o PIN incorrectos.', statusCode: 401);
    }
    token = 'fake-token';
    return const AuthSession(
      token: 'fake-token',
      operatorAccount: OperatorAccount(
        id: 'o1',
        name: 'Ana López',
        username: 'ana',
      ),
    );
  }

  @override
  Future<List<Zone>> listZones() async => zones;

  @override
  Future<Zone> createZone({
    required String name,
    required String city,
    String? videoUrl,
  }) async {
    createdZoneName = name;
    final zone = Zone(
      id: 'z-new',
      name: name,
      city: city,
      spacesCount: 0,
      freeCount: 0,
      videoUrl: videoUrl,
    );
    zones.add(zone);
    return zone;
  }

  @override
  Future<List<ParkingSpace>> listSpaces({
    String? zoneId,
    SpaceStatus? status,
  }) async {
    return spaces
        .where((space) => zoneId == null || space.zoneId == zoneId)
        .where((space) => status == null || space.status == status)
        .toList();
  }

  @override
  Future<ParkingSpace> getSpace(String id) async =>
      spaces.firstWhere((space) => space.id == id);

  @override
  Future<ParkingSpace> createSpace({
    required String code,
    required String zoneId,
    required double latitude,
    required double longitude,
    required double hourlyRate,
    String? notes,
  }) async {
    final space = ParkingSpace(
      id: 's-new',
      code: code,
      zoneId: zoneId,
      zoneName: 'Centro Histórico',
      latitude: latitude,
      longitude: longitude,
      hourlyRate: hourlyRate,
      status: SpaceStatus.free,
      notes: notes,
      updatedAt: DateTime.utc(2026, 9, 13),
    );
    spaces.add(space);
    return space;
  }

  @override
  Future<ParkingSpace> changeStatus(String id, SpaceStatus status) async {
    lastStatusChange = '$id:${spaceStatusToApi(status)}';
    return getSpace(id);
  }

  @override
  Future<ParkingSpace> reserveSpace(String id, {required String dni}) async {
    reservedDni = dni;
    return ParkingSpace(
      id: id,
      code: 'A-01',
      zoneId: 'z1',
      zoneName: 'Centro Histórico',
      latitude: 19.4,
      longitude: -99.1,
      hourlyRate: 18,
      status: SpaceStatus.reserved,
      updatedAt: DateTime.utc(2026, 9, 13),
      clientDni: dni,
      clientRuc: '10123456780',
      clientName: 'PEREZ PEREZ JUAN',
    );
  }

  @override
  Future<ClientIdentity> lookupClient(String dni) async {
    lookedUpDni = dni;
    return ClientIdentity(
      dni: dni,
      ruc: '10123456780',
      name: 'PEREZ PEREZ JUAN',
    );
  }

  @override
  Future<ParkingSession> startSession(
    String spaceId, {
    String? licensePlate,
  }) async {
    occupiedSpaceId = spaceId;
    return ParkingSession(
      id: 'p1',
      spaceId: spaceId,
      spaceCode: 'A-01',
      operatorId: 'o1',
      operatorName: 'Ana López',
      licensePlate: licensePlate,
      startedAt: DateTime.utc(2026, 9, 13),
      isActive: true,
    );
  }

  @override
  Future<ParkingSession> endSession(String sessionId) async {
    return ParkingSession(
      id: sessionId,
      spaceId: 's1',
      spaceCode: 'A-01',
      operatorId: 'o1',
      operatorName: 'Ana López',
      startedAt: DateTime.utc(2026, 9, 13),
      endedAt: DateTime.utc(2026, 9, 13, 13),
      isActive: false,
    );
  }
}
