import 'package:parkimetro_core/parkimetro_core.dart';

class FakeParkimetroApi extends ParkimetroApi {
  FakeParkimetroApi() : super(baseUrl: 'http://fake.local');

  bool failLogin = false;
  String? createdZoneName;
  String? occupiedSpaceId;
  String? occupiedDni;
  String? occupiedName;
  String? occupiedPlate;
  DateTime? occupiedLimitUntil;
  String? lastStatusChange;
  String? reservedDni;
  String? reservedName;
  DateTime? reservedStartsAt;
  DateTime? reservedLimitUntil;
  String? lookedUpDni;
  final unknownDnis = <String>{};

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
      hourlyRate: 2,
      status: SpaceStatus.free,
      updatedAt: DateTime.utc(2026, 9, 13),
    ),
    ParkingSpace(
      id: 's2',
      code: 'A-02',
      zoneId: 'z1',
      zoneName: 'Centro Histórico',
      latitude: 19.41,
      longitude: -99.11,
      hourlyRate: 2,
      status: SpaceStatus.occupied,
      updatedAt: DateTime.utc(2026, 9, 13),
      activeSessionId: 'p-occupied',
      occupiedSince: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
  ];

  void _replace(ParkingSpace space) {
    final index = spaces.indexWhere((item) => item.id == space.id);
    if (index >= 0) {
      spaces[index] = space;
    }
  }

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
  Future<ParkingSpace> reserveSpace(
    String id, {
    required String dni,
    String? clientName,
    required DateTime startsAt,
    required DateTime limitUntil,
  }) async {
    reservedDni = dni;
    reservedName = clientName;
    reservedStartsAt = startsAt;
    reservedLimitUntil = limitUntil;
    final current = await getSpace(id);
    final reserved = ParkingSpace(
      id: current.id,
      code: current.code,
      zoneId: current.zoneId,
      zoneName: current.zoneName,
      latitude: current.latitude,
      longitude: current.longitude,
      hourlyRate: current.hourlyRate,
      status: SpaceStatus.reserved,
      notes: current.notes,
      updatedAt: DateTime.utc(2026, 9, 13),
      clientDni: dni,
      clientRuc: '10123456780',
      clientName: clientName ?? 'PEREZ PEREZ JUAN',
      reservedFrom: startsAt,
      limitUntil: limitUntil,
    );
    _replace(reserved);
    return reserved;
  }

  @override
  Future<ClientIdentity> lookupClient(String dni) async {
    lookedUpDni = dni;
    if (unknownDnis.contains(dni)) {
      throw ApiException(
        'No se encontró el DNI en el padrón RUC.',
        statusCode: 404,
      );
    }
    return ClientIdentity(
      dni: dni,
      ruc: '10123456780',
      name: 'PEREZ PEREZ JUAN',
    );
  }

  @override
  Future<ParkingSession> startSession(
    String spaceId, {
    required String dni,
    String? clientName,
    String? licensePlate,
    required DateTime limitUntil,
  }) async {
    occupiedSpaceId = spaceId;
    occupiedDni = dni;
    occupiedName = clientName;
    occupiedPlate = licensePlate;
    occupiedLimitUntil = limitUntil;
    final current = await getSpace(spaceId);
    final occupied = ParkingSpace(
      id: current.id,
      code: current.code,
      zoneId: current.zoneId,
      zoneName: current.zoneName,
      latitude: current.latitude,
      longitude: current.longitude,
      hourlyRate: current.hourlyRate,
      status: SpaceStatus.occupied,
      notes: current.notes,
      updatedAt: DateTime.utc(2026, 9, 13),
      activeSessionId: 'p1',
      clientDni: dni,
      clientRuc: '10123456780',
      clientName: clientName ?? current.clientName ?? 'PEREZ PEREZ JUAN',
      occupiedSince: DateTime.now(),
      reservedFrom: current.reservedFrom,
      limitUntil: limitUntil,
    );
    _replace(occupied);
    return ParkingSession(
      id: 'p1',
      spaceId: spaceId,
      spaceCode: current.code,
      operatorId: 'o1',
      operatorName: 'Ana López',
      licensePlate: licensePlate,
      startedAt: occupied.occupiedSince!,
      isActive: true,
      billedHours: 1,
      amount: 2,
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
      billedHours: 1,
      amount: 2,
    );
  }
}
