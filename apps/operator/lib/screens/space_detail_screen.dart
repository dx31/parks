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
    final result = await showDialog<_ReserveResult>(
      context: context,
      builder: (context) => _ReserveDialog(api: widget.api),
    );
    if (result == null) {
      return;
    }
    try {
      await widget.api.reserveSpace(
        widget.spaceId,
        dni: result.dni,
        clientName: result.clientName,
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

  Future<void> _occupy() async {
    final plate = await showDialog<String>(
      context: context,
      builder: (context) => const _OccupyDialog(),
    );
    if (plate == null) {
      return;
    }
    try {
      await widget.api.startSession(
        widget.spaceId,
        licensePlate: plate.isEmpty ? null : plate,
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
        final ended = await widget.api.endSession(space.activeSessionId!);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cobrado ${formatSoles(ended.amount)} (${ended.billedHours} h o fracción)',
            ),
          ),
        );
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
              Text(rateLabel(space.hourlyRate)),
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
              if (space.occupiedSince != null) ...[
                const SizedBox(height: 16),
                OccupancyClock(
                  startedAt: space.occupiedSince!,
                  hourlyRate: space.hourlyRate,
                ),
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

class _ReserveResult {
  const _ReserveResult({required this.dni, this.clientName});

  final String dni;
  final String? clientName;
}

class _ReserveDialog extends StatefulWidget {
  const _ReserveDialog({required this.api});

  final ParkimetroApi api;

  @override
  State<_ReserveDialog> createState() => _ReserveDialogState();
}

class _ReserveDialogState extends State<_ReserveDialog> {
  final _dni = TextEditingController();
  final _name = TextEditingController();
  var _lookupHint = 'Si el padrón no lo trae, escríbelo aquí.';

  @override
  void dispose() {
    _dni.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    try {
      final found = await widget.api.lookupClient(_dni.text.trim());
      setState(() {
        _name.text = found.name;
        _lookupHint = 'RUC ${found.ruc}';
      });
    } on ApiException catch (error) {
      setState(() {
        _lookupHint = error.statusCode == 404
            ? 'No se encontró. Ingresa el nombre completo.'
            : error.message;
      });
      if (error.statusCode != 404 && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reservar espacio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _dni,
              decoration: const InputDecoration(labelText: 'DNI del cliente'),
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _lookup,
                child: const Text('Buscar'),
              ),
            ),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                helperText: _lookupHint,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ReserveResult(
              dni: _dni.text.trim(),
              clientName: _name.text.trim().isEmpty ? null : _name.text.trim(),
            ),
          ),
          child: const Text('Reservar'),
        ),
      ],
    );
  }
}

class _OccupyDialog extends StatefulWidget {
  const _OccupyDialog();

  @override
  State<_OccupyDialog> createState() => _OccupyDialogState();
}

class _OccupyDialogState extends State<_OccupyDialog> {
  final _plate = TextEditingController();

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Iniciar ocupación'),
      content: TextField(
        controller: _plate,
        decoration: const InputDecoration(labelText: 'Placa (opcional)'),
        textCapitalization: TextCapitalization.characters,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _plate.text.trim()),
          child: const Text('Ocupar'),
        ),
      ],
    );
  }
}
