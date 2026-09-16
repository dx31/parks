import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import 'screens/login_screen.dart';
import 'screens/zones_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    runApp(OperatorApp(api: ParkimetroApi()));
  } catch (error) {
    runApp(_StartupErrorApp(message: error.toString()));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}

class OperatorApp extends StatefulWidget {
  const OperatorApp({super.key, required this.api});

  final ParkimetroApi api;

  @override
  State<OperatorApp> createState() => _OperatorAppState();
}

class _OperatorAppState extends State<OperatorApp> {
  OperatorAccount? _operator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkímetro Operador',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F6C6C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _operator == null
          ? LoginScreen(
              api: widget.api,
              onLoggedIn: (account) => setState(() => _operator = account),
            )
          : ZonesScreen(
              api: widget.api,
              operatorAccount: _operator!,
              onLogout: () {
                widget.api.token = null;
                setState(() => _operator = null);
              },
            ),
    );
  }
}
