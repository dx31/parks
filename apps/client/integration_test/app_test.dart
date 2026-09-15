import 'package:client_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_api.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('flujo de cliente: listar y abrir detalle', (tester) async {
    await tester.pumpWidget(ClientApp(api: FakeParkimetroApi()));
    await tester.pumpAndSettle();
    expect(find.textContaining('A-01'), findsOneWidget);

    await tester.tap(find.textContaining('A-01'));
    await tester.pumpAndSettle();
    expect(find.text('Centro Histórico'), findsOneWidget);
  });
}
