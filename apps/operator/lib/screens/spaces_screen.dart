import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import '../tow/tow_services.dart';
import '../widgets/status_chip.dart';
import '../widgets/zone_camera_panel.dart';
import 'space_detail_screen.dart';
import 'space_form_screen.dart';
import 'tow_request_screen.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({
    super.key,
    required this.api,
    required this.zone,
    this.towServices,
  });

  final ParkimetroApi api;
  final Zone zone;
  final TowServices? towServices;

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

  Future<void> _openTowRequest() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            TowRequestScreen(zone: widget.zone, services: widget.towServices),
      ),
    );
  }

  Future<void> _openSpaceForm() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SpaceFormScreen(api: widget.api, zone: widget.zone),
      ),
    );
    if (created == true) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraUrl = widget.zone.resolvedVideoUrl(widget.api.baseUrl);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zone.name),
        actions: [
          IconButton(
            onPressed: _openTowRequest,
            tooltip: 'Solicitar grúa',
            icon: const Icon(Icons.local_shipping_outlined),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'tow',
            onPressed: _openTowRequest,
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Grúa'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'space',
            onPressed: _openSpaceForm,
            icon: const Icon(Icons.add),
            label: const Text('Espacio'),
          ),
        ],
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StayLimitIcon(space: space),
                      StatusChip(status: space.status),
                    ],
                  ),
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
