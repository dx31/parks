import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import '../widgets/status_chip.dart';
import '../widgets/zone_camera_panel.dart';
import 'space_detail_screen.dart';
import 'space_form_screen.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key, required this.api, required this.zone});

  final ParkimetroApi api;
  final Zone zone;

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> {
  late Future<List<ParkingSpace>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.listSpaces(zoneId: widget.zone.id);
  }

  void _reload() {
    setState(() {
      _future = widget.api.listSpaces(zoneId: widget.zone.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraUrl = widget.zone.resolvedVideoUrl(widget.api.baseUrl);
    return Scaffold(
      appBar: AppBar(title: Text(widget.zone.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) =>
                  SpaceFormScreen(api: widget.api, zone: widget.zone),
            ),
          );
          if (created == true) {
            _reload();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Espacio'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final list = _spacesList();
          if (cameraUrl == null) {
            return list;
          }
          return Column(
            children: [
              SizedBox(
                height: constraints.maxHeight / 2,
                width: double.infinity,
                child: ZoneCameraPanel(
                  url: cameraUrl,
                  headers: {
                    if (widget.api.token != null)
                      'Authorization': 'Bearer ${widget.api.token}',
                  },
                ),
              ),
              Expanded(child: list),
            ],
          );
        },
      ),
    );
  }

  Widget _spacesList() {
    return FutureBuilder<List<ParkingSpace>>(
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
          return const Center(child: Text('Esta zona aún no tiene espacios.'));
        }
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: spaces.length,
            itemBuilder: (context, index) {
              final space = spaces[index];
              return Card(
                child: ListTile(
                  title: Text(space.code),
                  subtitle: space.occupiedSince != null
                      ? OccupancyClock(
                          startedAt: space.occupiedSince!,
                          hourlyRate: space.hourlyRate,
                          compact: true,
                        )
                      : Text(
                          space.clientName == null
                              ? rateLabel(space.hourlyRate)
                              : '${space.clientName} · DNI ${space.clientDni}',
                        ),
                  trailing: StatusChip(status: space.status),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SpaceDetailScreen(
                          api: widget.api,
                          spaceId: space.id,
                        ),
                      ),
                    );
                    _reload();
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
