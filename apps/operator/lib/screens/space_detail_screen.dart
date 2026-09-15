import 'package:flutter/material.dart';
import 'package:parkimetro_core/parkimetro_core.dart';

import '../widgets/status_chip.dart';

class SpaceDetailScreen extends StatefulWidget {
  const SpaceDetailScreen({
    super.key,
    required this.api,
    required this.spaceId,
  });

  final ParkimetroApi api;
  final String spaceId;

  @override
  State<SpaceDetailScreen> createState() => _SpaceDetailScreenState();
}

class _SpaceDetailScreenState extends State<SpaceDetailScreen> {
  late Future<ParkingSpace> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getSpace(widget.spaceId);
  }

  void _reload() {
    setState(() {
      _future = widget.api.getSpace(widget.spaceId);
    });
  }

  Future<void> _setStatus(SpaceStatus status) async {
    try {
      await widget.api.changeStatus(widget.spaceId, status);
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reserve() async {
    final dni = TextEditingController();
    ClientIdentity? identity;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reservar espacio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: dni,
                    decoration: const InputDecoration(
                      labelText: 'DNI del cliente',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        try {
                          final found = await widget.api.lookupClient(
                            dni.text.trim(),
                          );
                          setDialogState(() => identity = found);
                        } on ApiException catch (error) {
                          setDialogState(() => identity = null);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)),
                            );
                          }
                        }
                      },
                      child: const Text('Buscar'),
                    ),
                  ),
                  if (identity != null)
                    Text('${identity!.name}\nRUC ${identity!.ruc}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reservar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (accepted != true) {
      return;
    }
    try {
      await widget.api.reserveSpace(widget.spaceId, dni: dni.text.trim());
      _reload();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _occupy() async {
    final plate = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar ocupación'),
        content: TextField(
          controller: plate,
          decoration: const InputDecoration(labelText: 'Placa (opcional)'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ocupar'),
          ),
        ],
      ),
    );
    if (accepted != true) {
      return;
    }
    try {
      await widget.api.startSession(
        widget.spaceId,
        licensePlate: plate.text.trim().isEmpty ? null : plate.text.trim(),
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

  Future<void> _release(ParkingSpace space) async {
    try {
      if (space.activeSessionId != null) {
        await widget.api.endSession(space.activeSessionId!);
      } else {
        await widget.api.changeStatus(space.id, SpaceStatus.free);
      }
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
      appBar: AppBar(title: const Text('Espacio')),
      body: FutureBuilder<ParkingSpace>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final space = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text(
                    space.code,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: space.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(space.zoneName),
              Text('\$${space.hourlyRate.toStringAsFixed(0)} por hora'),
              Text('Lat ${space.latitude}, Lng ${space.longitude}'),
              if (space.notes != null) Text(space.notes!),
              if (space.clientName != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Cliente: ${space.clientName}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('DNI ${space.clientDni} · RUC ${space.clientRuc}'),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: space.status == SpaceStatus.occupied
                        ? null
                        : _occupy,
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Ocupar'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: space.status == SpaceStatus.free
                        ? null
                        : () => _release(space),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Liberar'),
                  ),
                  OutlinedButton(
                    onPressed: _reserve,
                    child: const Text('Reservar'),
                  ),
                  OutlinedButton(
                    onPressed: () => _setStatus(SpaceStatus.outOfService),
                    child: const Text('Fuera de servicio'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
