import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import 'login_screen.dart';

void main() {
  runApp(ClientApp(api: ParkimetroApi()));
}

class ClientApp extends StatefulWidget {
  const ClientApp({super.key, required this.api});

  final ParkimetroApi api;

  @override
  State<ClientApp> createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  OperatorAccount? _account;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parkímetro Cliente',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B4F9C)),
        useMaterial3: true,
      ),
      home: _account == null
          ? LoginScreen(
              api: widget.api,
              onLoggedIn: (account) => setState(() => _account = account),
            )
          : ClientHomeScreen(
              api: widget.api,
              onLogout: () {
                widget.api.token = null;
                setState(() => _account = null);
              },
            ),
    );
  }
}

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({
    super.key,
    required this.api,
    required this.onLogout,
  });

  final ParkimetroApi api;
  final VoidCallback onLogout;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  bool _onlyFree = true;
  late Future<List<ParkingSpace>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ParkingSpace>> _load() {
    return widget.api.listSpaces(status: _onlyFree ? SpaceStatus.free : null);
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espacios disponibles'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Solo espacios libres'),
            value: _onlyFree,
            onChanged: (value) {
              setState(() {
                _onlyFree = value;
                _future = _load();
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<ParkingSpace>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final spaces = snapshot.data ?? [];
                if (spaces.isEmpty) {
                  return const Center(
                    child: Text('No hay espacios para mostrar.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: space.isFree
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: space.exceededStay()
                              ? Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.deepOrange.shade700,
                                )
                              : Icon(
                                  space.isFree
                                      ? Icons.local_parking
                                      : Icons.block,
                                  color: space.isFree
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                        ),
                        title: Text('${space.code} · ${space.zoneName}'),
                        subtitle: space.occupiedSince == null
                            ? Text(
                                '${spaceStatusLabel(space.status)} · ${rateLabel(space.hourlyRate)}',
                              )
                            : OccupancyClock(
                                startedAt: space.occupiedSince!,
                                hourlyRate: space.hourlyRate,
                                compact: true,
                              ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SpaceInfoScreen(space: space),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SpaceInfoScreen extends StatelessWidget {
  const SpaceInfoScreen({super.key, required this.space});

  final ParkingSpace space;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(space.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            space.zoneName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(spaceStatusLabel(space.status)),
          Text(rateLabel(space.hourlyRate)),
          Text('Lat ${space.latitude}, Lng ${space.longitude}'),
          if (space.notes != null) ...[
            const SizedBox(height: 12),
            Text(space.notes!),
          ],
          if (space.occupiedSince != null) ...[
            const SizedBox(height: 16),
            OccupancyClock(
              startedAt: space.occupiedSince!,
              hourlyRate: space.hourlyRate,
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'En el siguiente paso podemos agregar mapa y pago desde aquí.',
          ),
        ],
      ),
    );
  }
}
