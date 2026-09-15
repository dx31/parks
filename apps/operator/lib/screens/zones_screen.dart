import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import 'spaces_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({
    super.key,
    required this.api,
    required this.operatorAccount,
    required this.onLogout,
  });

  final ParkimetroApi api;
  final OperatorAccount operatorAccount;
  final VoidCallback onLogout;

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  late Future<List<Zone>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.listZones();
  }

  void _reload() {
    setState(() {
      _future = widget.api.listZones();
    });
  }

  Future<void> _createZone() async {
    final name = TextEditingController();
    final city = TextEditingController(text: 'Ciudad');
    final videoUrl = TextEditingController(text: '/api/cameras/demo');
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva zona'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: city,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            TextField(
              controller: videoUrl,
              decoration: const InputDecoration(
                labelText: 'URL de video (opcional)',
                hintText: '/api/cameras/demo',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (created != true || !mounted) {
      return;
    }

    try {
      await widget.api.createZone(
        name: name.text.trim(),
        city: city.text.trim(),
        videoUrl: videoUrl.text.trim().isEmpty ? null : videoUrl.text.trim(),
      );
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createZone,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Zona'),
      ),
      body: FutureBuilder<List<Zone>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final zones = snapshot.data ?? [];
          if (zones.isEmpty) {
            return const Center(child: Text('No hay zonas registradas.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'Hola, ${widget.operatorAccount.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              }
              final zone = zones[index - 1];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.map_outlined)),
                  title: Text(zone.name),
                  subtitle: Text(
                    '${zone.city} · ${zone.freeCount} libres de ${zone.spacesCount}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SpacesScreen(api: widget.api, zone: zone),
                      ),
                    );
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
