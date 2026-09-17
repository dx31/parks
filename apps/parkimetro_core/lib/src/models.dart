enum SpaceStatus { free, occupied, reserved, outOfService }

SpaceStatus spaceStatusFromApi(String value) => switch (value) {
  'occupied' => SpaceStatus.occupied,
  'reserved' => SpaceStatus.reserved,
  'outOfService' => SpaceStatus.outOfService,
  _ => SpaceStatus.free,
};

String spaceStatusToApi(SpaceStatus status) => switch (status) {
  SpaceStatus.free => 'free',
  SpaceStatus.occupied => 'occupied',
  SpaceStatus.reserved => 'reserved',
  SpaceStatus.outOfService => 'outOfService',
};

String spaceStatusLabel(SpaceStatus status) => switch (status) {
  SpaceStatus.free => 'Libre',
  SpaceStatus.occupied => 'Ocupado',
  SpaceStatus.reserved => 'Reservado',
  SpaceStatus.outOfService => 'Fuera de servicio',
};

class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.city,
    required this.spacesCount,
    required this.freeCount,
    this.videoUrl,
  });

  final String id;
  final String name;
  final String city;
  final int spacesCount;
  final int freeCount;
  final String? videoUrl;

  String? resolvedVideoUrl(String apiBaseUrl) {
    final value = videoUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final path = value.startsWith('/') ? value : '/$value';
    return '$apiBaseUrl$path';
  }

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    id: json['id'] as String,
    name: json['name'] as String,
    city: json['city'] as String,
    spacesCount: json['spacesCount'] as int,
    freeCount: json['freeCount'] as int,
    videoUrl: json['videoUrl'] as String?,
  );
}

class ParkingSpace {
  const ParkingSpace({
    required this.id,
    required this.code,
    required this.zoneId,
    required this.zoneName,
    required this.latitude,
    required this.longitude,
    required this.hourlyRate,
    required this.status,
    required this.updatedAt,
    this.notes,
    this.activeSessionId,
    this.clientDni,
    this.clientRuc,
    this.clientName,
    this.occupiedSince,
    this.reservedFrom,
    this.limitUntil,
  });

  final String id;
  final String code;
  final String zoneId;
  final String zoneName;
  final double latitude;
  final double longitude;
  final double hourlyRate;
  final SpaceStatus status;
  final String? notes;
  final DateTime updatedAt;
  final String? activeSessionId;
  final String? clientDni;
  final String? clientRuc;
  final String? clientName;
  final DateTime? occupiedSince;
  final DateTime? reservedFrom;
  final DateTime? limitUntil;

  bool get isFree => status == SpaceStatus.free;

  bool exceededStay([DateTime? now]) {
    if (limitUntil == null) {
      return false;
    }
    if (status != SpaceStatus.occupied && status != SpaceStatus.reserved) {
      return false;
    }
    return (now ?? DateTime.now()).toUtc().isAfter(limitUntil!.toUtc());
  }

  factory ParkingSpace.fromJson(Map<String, dynamic> json) => ParkingSpace(
    id: json['id'] as String,
    code: json['code'] as String,
    zoneId: json['zoneId'] as String,
    zoneName: json['zoneName'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    hourlyRate: (json['hourlyRate'] as num).toDouble(),
    status: spaceStatusFromApi(json['status'] as String),
    notes: json['notes'] as String?,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    activeSessionId: json['activeSessionId'] as String?,
    clientDni: json['clientDni'] as String?,
    clientRuc: json['clientRuc'] as String?,
    clientName: json['clientName'] as String?,
    occupiedSince: json['occupiedSince'] == null
        ? null
        : DateTime.parse(json['occupiedSince'] as String),
    reservedFrom: json['reservedFrom'] == null
        ? null
        : DateTime.parse(json['reservedFrom'] as String),
    limitUntil: json['limitUntil'] == null
        ? null
        : DateTime.parse(json['limitUntil'] as String),
  );
}

class OperatorAccount {
  const OperatorAccount({
    required this.id,
    required this.name,
    required this.username,
  });

  final String id;
  final String name;
  final String username;

  factory OperatorAccount.fromJson(Map<String, dynamic> json) =>
      OperatorAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        username: json['username'] as String,
      );
}

class AuthSession {
  const AuthSession({required this.token, required this.operatorAccount});

  final String token;
  final OperatorAccount operatorAccount;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String,
    operatorAccount: OperatorAccount.fromJson(
      json['operator'] as Map<String, dynamic>,
    ),
  );
}

class ParkingSession {
  const ParkingSession({
    required this.id,
    required this.spaceId,
    required this.spaceCode,
    required this.operatorId,
    required this.operatorName,
    required this.startedAt,
    required this.isActive,
    this.licensePlate,
    this.endedAt,
    this.billedHours = 1,
    this.amount = 0,
  });

  final String id;
  final String spaceId;
  final String spaceCode;
  final String operatorId;
  final String operatorName;
  final String? licensePlate;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isActive;
  final int billedHours;
  final double amount;

  factory ParkingSession.fromJson(Map<String, dynamic> json) => ParkingSession(
    id: json['id'] as String,
    spaceId: json['spaceId'] as String,
    spaceCode: json['spaceCode'] as String,
    operatorId: json['operatorId'] as String,
    operatorName: json['operatorName'] as String,
    licensePlate: json['licensePlate'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    endedAt: json['endedAt'] == null
        ? null
        : DateTime.parse(json['endedAt'] as String),
    isActive: json['isActive'] as bool,
    billedHours: json['billedHours'] as int? ?? 1,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
  );
}

class ClientIdentity {
  const ClientIdentity({
    required this.dni,
    required this.ruc,
    required this.name,
    this.address,
  });

  final String dni;
  final String ruc;
  final String name;
  final String? address;

  factory ClientIdentity.fromJson(Map<String, dynamic> json) => ClientIdentity(
    dni: json['dni'] as String,
    ruc: json['ruc'] as String,
    name: json['name'] as String,
    address: json['address'] as String?,
  );
}
