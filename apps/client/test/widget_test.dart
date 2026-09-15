import 'package:client_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import 'helpers/fake_api.dart';

void main() {
  testWidgets('lista espacios libres y abre el detalle', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(ClientApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('A-01 · Centro Histórico'), findsOneWidget);
    expect(find.text('A-02 · Centro Histórico'), findsNothing);
    expect(api.lastFilter, SpaceStatus.free);

    await tester.tap(find.text('A-01 · Centro Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('cerca del parque'), findsOneWidget);
    expect(find.text('Libre'), findsWidgets);
  });

  testWidgets('puede mostrar todos los espacios', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(ClientApp(api: api));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(api.lastFilter, isNull);
    expect(find.text('A-02 · Centro Histórico'), findsOneWidget);
  });

  testWidgets('muestra el error de la API', (tester) async {
    final api = FakeParkimetroApi()
      ..error = ApiException('No se pudo conectar con la API.');
    await tester.pumpWidget(ClientApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('No se pudo conectar con la API.'), findsOneWidget);
  });
}
