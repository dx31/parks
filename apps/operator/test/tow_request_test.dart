import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:operator_app/screens/tow_request_screen.dart';
import 'package:operator_app/tow/tow_share_message.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import 'helpers/fake_tow_services.dart';

void main() {
  const zone = Zone(
    id: 'z1',
    name: 'Centro Histórico',
    city: 'Ciudad',
    spacesCount: 2,
    freeCount: 1,
  );

  test('el mensaje de grúa incluye placa, zona y mapa', () {
    final text = buildTowShareMessage(
      zoneName: 'Centro Histórico',
      city: 'Lima',
      plate: 'ABC-123',
      notes: 'Bloqueando la rampa',
      latitude: -12.046374,
      longitude: -77.042793,
    );

    expect(text, contains('Solicitud de grúa'));
    expect(text, contains('Zona: Centro Histórico'));
    expect(text, contains('Placa: ABC-123'));
    expect(text, contains('Indicaciones: Bloqueando la rampa'));
    expect(text, contains('https://maps.google.com/?q=-12.046374,-77.042793'));
  });

  Future<void> pumpScreen(WidgetTester tester, FakeTowServices services) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: TowRequestScreen(zone: zone, services: services),
      ),
    );
  }

  testWidgets('solicitar grúa exige placa y foto antes de compartir', (
    tester,
  ) async {
    final services = FakeTowServices(photoPath: null);
    await pumpScreen(tester, services);

    await tester.tap(find.text('Compartir solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Indica la placa del vehículo.'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Placa del vehículo'),
      'abc-123',
    );
    await tester.tap(find.text('Compartir solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('Toma una foto del vehículo a incautar.'), findsOneWidget);
    expect(services.lastSharedText, isNull);
  });

  testWidgets('toma foto y comparte geolocalización con la placa', (
    tester,
  ) async {
    final services = FakeTowServices();
    await pumpScreen(tester, services);

    await tester.enterText(
      find.widgetWithText(TextField, 'Placa del vehículo'),
      'abc-99',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Indicaciones adicionales'),
      'Rojo, frente a la municipalidad',
    );
    await tester.ensureVisible(find.text('Tomar foto'));
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(find.text('Foto lista'), findsOneWidget);
    expect(services.lastFromCamera, isTrue);

    await tester.tap(find.text('Compartir solicitud'));
    await tester.pumpAndSettle();

    expect(services.lastSharedImage, 'tow-photo.jpg');
    expect(services.lastSharedText, contains('Placa: ABC-99'));
    expect(services.lastSharedText, contains('Centro Histórico'));
    expect(
      services.lastSharedText,
      contains('Rojo, frente a la municipalidad'),
    );
    expect(
      services.lastSharedText,
      contains('https://maps.google.com/?q=-12.046374,-77.042793'),
    );
    expect(
      find.text('Solicitud lista para enviar por mensajería.'),
      findsOneWidget,
    );
  });
}
