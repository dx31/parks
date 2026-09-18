import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/main.dart';
import 'package:operator_app/screens/login_screen.dart';
import 'package:operator_app/screens/space_detail_screen.dart';
import 'package:operator_app/screens/space_form_screen.dart';
import 'package:operator_app/screens/spaces_screen.dart';
import 'package:operator_app/screens/zones_screen.dart';
import 'package:operator_app/widgets/status_chip.dart';
import 'package:operator_app/widgets/zone_camera_panel.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import 'helpers/fake_api.dart';

void main() {
  setUp(() {
    ZoneCameraPanel.disablePlayer = true;
    OccupancyClock.live = false;
  });

  testWidgets('login exitoso entra a zonas', (tester) async {
    await tester.pumpWidget(OperatorApp(api: FakeParkimetroApi()));
    expect(find.text('http://fake.local'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Ana López'), findsOneWidget);
    expect(find.text('Centro Histórico'), findsOneWidget);
  });

  testWidgets('login fallido muestra el error', (tester) async {
    final api = FakeParkimetroApi()..failLogin = true;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(api: api, onLoggedIn: (_) {}),
      ),
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Usuario o PIN incorrectos.'), findsOneWidget);
  });

  testWidgets('status chip muestra cada estado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusChip(status: SpaceStatus.free),
              StatusChip(status: SpaceStatus.occupied),
              StatusChip(status: SpaceStatus.reserved),
              StatusChip(status: SpaceStatus.outOfService),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Libre'), findsOneWidget);
    expect(find.text('Ocupado'), findsOneWidget);
    expect(find.text('Reservado'), findsOneWidget);
    expect(find.text('Fuera de servicio'), findsOneWidget);
  });

  testWidgets('zones screen lista zonas sin botón de crear', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ZonesScreen(
          api: api,
          operatorAccount: const OperatorAccount(
            id: 'o1',
            name: 'Ana López',
            username: 'ana',
          ),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Centro Histórico'), findsOneWidget);
    expect(find.text('Zona'), findsNothing);
  });

  testWidgets('spaces screen muestra espacios de la zona', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpacesScreen(
          api: FakeParkimetroApi(),
          zone: const Zone(
            id: 'z1',
            name: 'Centro Histórico',
            city: 'Ciudad',
            spacesCount: 1,
            freeCount: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A-01'), findsOneWidget);
    expect(find.text('A-02'), findsOneWidget);
    expect(find.textContaining('Ocupado'), findsWidgets);
    expect(find.text('Grúa'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    expect(find.text('Espacio'), findsNothing);
  });

  testWidgets('spaces screen alerta si se excedió la salida estimada', (
    tester,
  ) async {
    final api = FakeParkimetroApi();
    api.spaces.add(
      ParkingSpace(
        id: 's3',
        code: 'A-03',
        zoneId: 'z1',
        zoneName: 'Centro Histórico',
        latitude: 19.42,
        longitude: -99.12,
        hourlyRate: 2,
        status: SpaceStatus.occupied,
        updatedAt: DateTime.utc(2026, 9, 13),
        occupiedSince: DateTime.now().subtract(const Duration(hours: 3)),
        limitUntil: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SpacesScreen(
          api: api,
          zone: const Zone(
            id: 'z1',
            name: 'Centro Histórico',
            city: 'Ciudad',
            spacesCount: 3,
            freeCount: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A-03'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      find.byTooltip('Se excedió la hora de salida estimada'),
      findsOneWidget,
    );
  });

  testWidgets('spaces screen abre el formulario de grúa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpacesScreen(
          api: FakeParkimetroApi(),
          zone: const Zone(
            id: 'z1',
            name: 'Centro Histórico',
            city: 'Ciudad',
            spacesCount: 1,
            freeCount: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grúa'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitar grúa'), findsOneWidget);
    expect(find.text('Placa del vehículo'), findsOneWidget);
    expect(find.text('Indicaciones adicionales'), findsOneWidget);
  });

  testWidgets('spaces screen muestra cámara en la mitad de la pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SpacesScreen(
          api: FakeParkimetroApi(),
          zone: const Zone(
            id: 'z1',
            name: 'Centro Histórico',
            city: 'Ciudad',
            spacesCount: 1,
            freeCount: 1,
            videoUrl: '/api/cameras/demo',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cámara en vivo'), findsOneWidget);
    expect(find.byType(ZoneCameraPanel), findsOneWidget);
  });

  testWidgets('space detail reserva con DNI del cliente', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(
      MaterialApp(
        home: SpaceDetailScreen(api: api, spaceId: 's1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'DNI del cliente'),
      '12345678',
    );
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PEREZ PEREZ JUAN'), findsOneWidget);
    expect(find.text('Hora de inicio'), findsOneWidget);
    expect(find.text('Hora de fin estimada'), findsOneWidget);
    await tester.tap(find.text('Reservar').last);
    await tester.pumpAndSettle();
    expect(api.reservedDni, '12345678');
    expect(api.lookedUpDni, '12345678');
    expect(api.reservedName, 'PEREZ PEREZ JUAN');
    expect(api.reservedStartsAt, isNotNull);
    expect(api.reservedLimitUntil, isNotNull);
    expect(api.reservedLimitUntil!.isAfter(api.reservedStartsAt!), isTrue);
    expect(find.textContaining('RUC'), findsNothing);
    expect(find.textContaining('DNI 12345678'), findsOneWidget);
    expect(find.textContaining('Inicio:'), findsOneWidget);
    expect(find.textContaining('Fin estimado:'), findsOneWidget);
  });

  testWidgets('space detail reserva con nombre manual si no hay padrón', (
    tester,
  ) async {
    final api = FakeParkimetroApi()..unknownDnis.add('00000000');
    await tester.pumpWidget(
      MaterialApp(
        home: SpaceDetailScreen(api: api, spaceId: 's1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'DNI del cliente'),
      '00000000',
    );
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se encontró'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre completo'),
      'JUAN MANUAL',
    );
    await tester.tap(find.text('Reservar').last);
    await tester.pumpAndSettle();
    expect(api.reservedDni, '00000000');
    expect(api.reservedName, 'JUAN MANUAL');
  });

  testWidgets('space form guarda un espacio', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(
      MaterialApp(
        home: SpaceFormScreen(
          api: api,
          zone: const Zone(
            id: 'z1',
            name: 'Centro Histórico',
            city: 'Ciudad',
            spacesCount: 1,
            freeCount: 1,
          ),
        ),
      ),
    );
    await tester.enterText(find.widgetWithText(TextField, 'Código'), 'A-77');
    await tester.tap(find.text('Guardar espacio'));
    await tester.pumpAndSettle();
    expect(api.spaces.any((space) => space.code == 'A-77'), isTrue);
  });

  testWidgets('space detail puede ocupar un espacio', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(
      MaterialApp(
        home: SpaceDetailScreen(api: api, spaceId: 's1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A-01'), findsOneWidget);

    await tester.tap(find.text('Ocupar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'DNI del cliente'),
      '12345678',
    );
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PEREZ PEREZ JUAN'), findsOneWidget);
    expect(find.text('Hora de inicio'), findsNothing);
    expect(find.text('Hora de fin estimada'), findsOneWidget);
    expect(
      find.textContaining('El inicio lo registra el servidor'),
      findsOneWidget,
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Placa (opcional)'),
      'XYZ99',
    );
    await tester.tap(find.text('Ocupar').last);
    await tester.pumpAndSettle();
    expect(api.occupiedSpaceId, 's1');
    expect(api.occupiedDni, '12345678');
    expect(api.occupiedName, 'PEREZ PEREZ JUAN');
    expect(api.occupiedPlate, 'XYZ99');
    expect(api.occupiedLimitUntil, isNotNull);
    expect(api.lookedUpDni, '12345678');
    expect(find.textContaining('Tiempo ocupado'), findsOneWidget);
    expect(find.textContaining('S/'), findsWidgets);
    expect(find.textContaining('RUC'), findsNothing);
    expect(find.textContaining('DNI 12345678'), findsOneWidget);
    expect(find.textContaining('Fin estimado:'), findsOneWidget);
  });

  testWidgets('space detail ocupa con nombre manual si no hay padrón', (
    tester,
  ) async {
    final api = FakeParkimetroApi()..unknownDnis.add('00000000');
    await tester.pumpWidget(
      MaterialApp(
        home: SpaceDetailScreen(api: api, spaceId: 's1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ocupar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'DNI del cliente'),
      '00000000',
    );
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se encontró'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre completo'),
      'JUAN MANUAL',
    );
    await tester.tap(find.text('Ocupar').last);
    await tester.pumpAndSettle();
    expect(api.occupiedDni, '00000000');
    expect(api.occupiedName, 'JUAN MANUAL');
  });
}
