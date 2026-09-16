import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

void main() {
  tearDown(() => OccupancyClock.live = true);

  testWidgets('shows occupied time and current charge', (tester) async {
    OccupancyClock.live = false;
    final started = DateTime.now().subtract(const Duration(minutes: 8));
    await tester.pumpWidget(
      MaterialApp(home: OccupancyClock(startedAt: started, hourlyRate: 2)),
    );

    expect(find.textContaining('Tiempo ocupado'), findsOneWidget);
    expect(find.textContaining('S/ 2.00'), findsOneWidget);
  });
}
