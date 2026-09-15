import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:operator_app/main.dart';

import '../test/helpers/fake_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo de operador: login, zona y espacio', (tester) async {
    final api = FakeParkimetroApi();
    await tester.pumpWidget(OperatorApp(api: api));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Centro Histórico'), findsOneWidget);
    await tester.tap(find.text('Centro Histórico'));
    await tester.pumpAndSettle();
    expect(find.text('A-01'), findsOneWidget);
  });
}
