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

  testWidgets('zones screen lista zonas y crea una nueva', (tester) async {
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

    await tester.tap(find.text('Zona'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nombre'),
      'Nueva zona',
    );
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(api.createdZoneName, 'Nueva zona');
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
    await tester.tap(find.text('Reservar').last);
    await tester.pumpAndSettle();
    expect(api.reservedDni, '12345678');
    expect(api.lookedUpDni, '12345678');
    expect(api.reservedName, 'PEREZ PEREZ JUAN');
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
      find.widgetWithText(TextField, 'Placa (opcional)'),
      'XYZ99',
    );
    await tester.tap(find.text('Ocupar').last);
    await tester.pumpAndSettle();
    expect(api.occupiedSpaceId, 's1');
    expect(find.textContaining('Tiempo ocupado'), findsOneWidget);
    expect(find.textContaining('S/'), findsWidgets);
  });
}
